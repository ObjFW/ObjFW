/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <fcntl.h>
#include <unistd.h>

#include <sys/epoll.h>

#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#import "OFKernelEventObserver_epoll.h"
#import "OFMapTable.h"

#import "OFInitializationFailedException.h"
#import "OFObserveFailedException.h"

#define EVENTLIST_SIZE 64

static const of_map_table_functions_t mapFunctions = { NULL };

@implementation OFKernelEventObserver_epoll
- init
{
	self = [super init];

	@try {
#ifdef HAVE_EPOLL_CREATE1
		if ((_epfd = epoll_create1(EPOLL_CLOEXEC)) == -1)
			@throw [OFInitializationFailedException exception];
#else
		int flags;

		if ((_epfd = epoll_create(1)) == -1)
			@throw [OFInitializationFailedException exception];

		if ((flags = fcntl(_epfd, F_GETFD, 0)) != -1)
			fcntl(_epfd, F_SETFD, flags | FD_CLOEXEC);
#endif

		_FDToEvents = [[OFMapTable alloc]
		    initWithKeyFunctions: mapFunctions
			  valueFunctions: mapFunctions];

		[self OF_addFileDescriptorForReading: _cancelFD[0]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	close(_epfd);

	[_FDToEvents release];

	[super dealloc];
}


- (void)OF_addFileDescriptor: (int)fd
		   forEvents: (int)addEvents
{
	intptr_t events;

	events = (intptr_t)[_FDToEvents valueForKey: (void*)(intptr_t)fd];
	if (events == 0) {
		struct epoll_event event;

		memset(&event, 0, sizeof(event));
		event.events = addEvents;
		event.data.fd = fd;

		if (epoll_ctl(_epfd, EPOLL_CTL_ADD, fd, &event) == -1)
			@throw [OFObserveFailedException
			    exceptionWithObserver: self
					    errNo: errno];

		[_FDToEvents setValue: (void*)(intptr_t)addEvents
			       forKey: (void*)(intptr_t)fd];
	} else {
		struct epoll_event event;

		memset(&event, 0, sizeof(event));
		event.events = (int)events | addEvents;
		event.data.fd = fd;

		if (epoll_ctl(_epfd, EPOLL_CTL_MOD, fd, &event) == -1)
			@throw [OFObserveFailedException
			    exceptionWithObserver: self
					    errNo: errno];

		[_FDToEvents setValue: (void*)(events | addEvents)
			       forKey: (void*)(intptr_t)fd];
	}
}

- (void)OF_removeFileDescriptor: (int)fd
		      forEvents: (int)removeEvents
{
	intptr_t events;

	events = (intptr_t)[_FDToEvents valueForKey: (void*)(intptr_t)fd];
	events &= ~removeEvents;

	if (events == 0) {
		if (epoll_ctl(_epfd, EPOLL_CTL_DEL, fd, NULL) == -1)
			@throw [OFObserveFailedException
			    exceptionWithObserver: self
					    errNo: errno];

		[_FDToEvents removeValueForKey: (void*)(intptr_t)fd];
	} else {
		struct epoll_event event;

		memset(&event, 0, sizeof(event));
		event.events = (int)events;
		event.data.fd = fd;

		if (epoll_ctl(_epfd, EPOLL_CTL_MOD, fd, &event) == -1)
			@throw [OFObserveFailedException
			    exceptionWithObserver: self
					    errNo: errno];

		[_FDToEvents setValue: (void*)events
			       forKey: (void*)(intptr_t)fd];
	}
}

- (void)OF_addFileDescriptorForReading: (int)fd
{
	[self OF_addFileDescriptor: fd
			 forEvents: EPOLLIN];
}

- (void)OF_addFileDescriptorForWriting: (int)fd
{
	[self OF_addFileDescriptor: fd
			 forEvents: EPOLLOUT];
}

- (void)OF_removeFileDescriptorForReading: (int)fd
{
	[self OF_removeFileDescriptor: fd
			    forEvents: EPOLLIN];
}

- (void)OF_removeFileDescriptorForWriting: (int)fd
{
	[self OF_removeFileDescriptor: fd
			    forEvents: EPOLLOUT];
}

- (bool)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	void *pool = objc_autoreleasePoolPush();
	struct epoll_event eventList[EVENTLIST_SIZE];
	int i, events, realEvents = 0;

	[self OF_processQueueAndStoreRemovedIn: nil];

	if ([self OF_processReadBuffers]) {
		objc_autoreleasePoolPop(pool);
		return true;
	}

	objc_autoreleasePoolPop(pool);

	events = epoll_wait(_epfd, eventList, EVENTLIST_SIZE,
	    (timeInterval != -1 ? timeInterval * 1000 : -1));

	if (events < 0)
		return [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	if (events == 0)
		return false;

	for (i = 0; i < events; i++) {
		if (eventList[i].data.fd == _cancelFD[0]) {
			char buffer;

			assert(eventList[i].events == EPOLLIN);
			OF_ENSURE(read(_cancelFD[0], &buffer, 1) == 1);

			continue;
		}

		if (eventList[i].events & EPOLLIN) {
			pool = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading:
				    _FDToObject[eventList[i].data.fd]];

			realEvents++;

			objc_autoreleasePoolPop(pool);
		}

		if (eventList[i].events & EPOLLOUT) {
			pool = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting:
				    _FDToObject[eventList[i].data.fd]];

			realEvents++;

			objc_autoreleasePoolPop(pool);
		}

		assert((eventList[i].events & ~(EPOLLIN | EPOLLOUT)) == 0);
	}

	if (realEvents == 0)
		return false;

	return true;
}
@end
