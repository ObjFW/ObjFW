/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
#include <math.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif
#include "unistd_wrapper.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#import "OFKqueueKernelEventObserver.h"
#import "OFArray.h"
#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFObserveFailedException.h"
#import "OFOutOfRangeException.h"

#define EVENTLIST_SIZE 64

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

- (void)of_addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForReading;
	event.filter = EVFILT_READ;
	event.flags = EV_ADD;
#ifndef OF_NETBSD
	event.udata = object;
#else
	event.udata = (intptr_t)object;
#endif

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];
}

- (void)of_addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForWriting;
	event.filter = EVFILT_WRITE;
	event.flags = EV_ADD;
#ifndef OF_NETBSD
	event.udata = object;
#else
	event.udata = (intptr_t)object;
#endif

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];
}

- (void)of_removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForReading;
	event.filter = EVFILT_READ;
	event.flags = EV_DELETE;

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];
}

- (void)of_removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = object.fileDescriptorForWriting;
	event.filter = EVFILT_WRITE;
	event.flags = EV_DELETE;

	if (kevent(_kernelQueue, &event, 1, NULL, 0, NULL) != 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];
}

- (void)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	struct timespec timeout;
	struct kevent eventList[EVENTLIST_SIZE];
	int events;

	[self of_processQueue];

	if ([self of_processReadBuffers])
		return;

	timeout.tv_sec = (time_t)timeInterval;
	timeout.tv_nsec = lrint((timeInterval - timeout.tv_sec) * 1000000000);

	events = kevent(_kernelQueue, NULL, 0, eventList, EVENTLIST_SIZE,
	    (timeInterval != -1 ? &timeout : NULL));

	if (events < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	for (int i = 0; i < events; i++) {
		void *pool;

		if (eventList[i].flags & EV_ERROR)
			@throw [OFObserveFailedException
			    exceptionWithObserver: self
					    errNo: (int)eventList[i].data];

		if (eventList[i].ident == (uintptr_t)_cancelFD[0]) {
			char buffer;

			assert(eventList[i].filter == EVFILT_READ);
			OF_ENSURE(read(_cancelFD[0], &buffer, 1) == 1);

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
