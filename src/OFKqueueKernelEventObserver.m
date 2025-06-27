/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <errno.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif
#include "unistd_wrapper.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#import "OFKqueueKernelEventObserver.h"
#import "OFArray.h"

#import "OFInitializationFailedException.h"
#import "OFObserveKernelEventsFailedException.h"
#import "OFOutOfRangeException.h"

#define eventListSize 64

@implementation OFKqueueKernelEventObserver
- (instancetype)initWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	self = [super initWithRunLoopMode: runLoopMode];

	@try {
		struct kevent event;

#ifdef HAVE_KQUEUE1
		if ((_kernelQueue = kqueue1(O_CLOEXEC)) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
#else
		int flags;

		if ((_kernelQueue = kqueue()) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		if ((flags = fcntl(_kernelQueue, F_GETFD, 0)) != -1)
			fcntl(_kernelQueue, F_SETFD, flags | FD_CLOEXEC);
#endif

		EV_SET(&event, _cancelFD[0], EVFILT_READ, EV_ADD, 0, 0, 0);

		while (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
			if (errno != EINTR)
				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	close(_kernelQueue);

	[super dealloc];
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForReading;
	event.filter = EVFILT_READ;
	event.flags = EV_ADD;
	/*
	 * Ugly hack required for NetBSD: NetBSD used `intptr_t` for udata, but
	 * switched this to `void *` in NetBSD 10.
	 */
	event.udata = (__typeof__(event.udata))object;

	while (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		if (errno != EINTR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errno];

	[super addObjectForReading: object];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForWriting;
	event.filter = EVFILT_WRITE;
	event.flags = EV_ADD;
	/*
	 * Ugly hack required for NetBSD: NetBSD used `intptr_t` for udata, but
	 * switched this to `void *` in NetBSD 10.
	 */
	event.udata = (__typeof__(event.udata))object;

	while (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		if (errno != EINTR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errno];

	[super addObjectForWriting: object];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForReading;
	event.filter = EVFILT_READ;
	event.flags = EV_DELETE;

	while (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		if (errno != EINTR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errno];

	[super removeObjectForReading: object];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForWriting;
	event.filter = EVFILT_WRITE;
	event.flags = EV_DELETE;

	while (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		if (errno != EINTR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errno];

	[super removeObjectForWriting: object];
}

- (void)observeForTimeInterval: (OFTimeInterval)timeInterval
{
	struct timespec timeout;
	struct kevent eventList[eventListSize];
	int events;

	if ([self processReadBuffers])
		return;

	timeout.tv_sec = (time_t)timeInterval;
	timeout.tv_nsec = (long)((timeInterval - timeout.tv_sec) * 1000000000);

	while ((events = kevent(_kernelQueue, NULL, 0, eventList, eventListSize,
	    (timeInterval != -1 ? &timeout : NULL))) < 0)
		if (errno != EINTR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errno];

	for (int i = 0; i < events; i++) {
		void *pool;

		if (eventList[i].flags & EV_ERROR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: (int)eventList[i].data];

		if (eventList[i].ident == (uintptr_t)_cancelFD[0]) {
			char buffer;

			OFAssert(eventList[i].filter == EVFILT_READ);
			OFEnsure(read(_cancelFD[0], &buffer, 1) == 1);

			continue;
		}

		pool = objc_autoreleasePoolPush();

		switch (eventList[i].filter) {
		case EVFILT_READ:
			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading:
				    (id)eventList[i].udata];
			break;
		case EVFILT_WRITE:
			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting:
				    (id)eventList[i].udata];
			break;
		default:
			OFAssert(0);
		}

		objc_autoreleasePoolPop(pool);
	}
}
@end
