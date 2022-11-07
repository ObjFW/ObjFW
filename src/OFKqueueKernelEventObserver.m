/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <assert.h>
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
- (instancetype)init
{
	self = [super init];

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

		if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
	} @catch (id e) {
		[self release];
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

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
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

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
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

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
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

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
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

	if ([self of_processReadBuffers])
		return;

	timeout.tv_sec = (time_t)timeInterval;
	timeout.tv_nsec = (long)((timeInterval - timeout.tv_sec) * 1000000000);

	events = kevent(_kernelQueue, NULL, 0, eventList, eventListSize,
	    (timeInterval != -1 ? &timeout : NULL));

	if (events < 0)
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

			assert(eventList[i].filter == EVFILT_READ);
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
			assert(0);
		}

		objc_autoreleasePoolPop(pool);
	}
}
@end
