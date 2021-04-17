/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include <sys/epoll.h>

#import "OFEpollKernelEventObserver.h"
#import "OFArray.h"
#import "OFMapTable.h"
#import "OFNull.h"

#import "OFInitializationFailedException.h"
#import "OFObserveFailedException.h"

#define EVENTLIST_SIZE 64

static const OFMapTableFunctions mapFunctions = { NULL };

@implementation OFEpollKernelEventObserver
- (instancetype)init
{
	self = [super init];

	@try {
		struct epoll_event event;

#ifdef HAVE_EPOLL_CREATE1
		if ((_epfd = epoll_create1(EPOLL_CLOEXEC)) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
#else
		int flags;

		if ((_epfd = epoll_create(1)) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		if ((flags = fcntl(_epfd, F_GETFD, 0)) != -1)
			fcntl(_epfd, F_SETFD, flags | FD_CLOEXEC);
#endif

		_FDToEvents = [[OFMapTable alloc]
		    initWithKeyFunctions: mapFunctions
			 objectFunctions: mapFunctions];

		memset(&event, 0, sizeof(event));
		event.events = EPOLLIN;
		event.data.ptr = [OFNull null];

		if (epoll_ctl(_epfd, EPOLL_CTL_ADD, _cancelFD[0], &event) == -1)
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
	close(_epfd);

	[_FDToEvents release];

	[super dealloc];
}

- (void)of_addObject: (id)object
      fileDescriptor: (int)fd
	      events: (int)addEvents OF_DIRECT
{
	struct epoll_event event;
	intptr_t events;

	events = (intptr_t)[_FDToEvents
	    objectForKey: (void *)((intptr_t)fd + 1)];

	memset(&event, 0, sizeof(event));
	event.events = (int)events | addEvents;
	event.data.ptr = object;

	if (epoll_ctl(_epfd, (events == 0 ? EPOLL_CTL_ADD : EPOLL_CTL_MOD),
	    fd, &event) == -1)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	[_FDToEvents setObject: (void *)(events | addEvents)
			forKey: (void *)((intptr_t)fd + 1)];
}

- (void)of_removeObject: (id)object
	 fileDescriptor: (int)fd
		 events: (int)removeEvents OF_DIRECT
{
	intptr_t events;

	events = (intptr_t)[_FDToEvents
	    objectForKey: (void *)((intptr_t)fd + 1)];
	events &= ~removeEvents;

	if (events == 0) {
		if (epoll_ctl(_epfd, EPOLL_CTL_DEL, fd, NULL) == -1)
			/*
			 * When an async connect fails, it seems the socket is
			 * automatically removed from epoll, meaning ENOENT is
			 * returned when we try to remove it after it failed.
			 */
			if (errno != ENOENT)
				@throw [OFObserveFailedException
				    exceptionWithObserver: self
						    errNo: errno];

		[_FDToEvents removeObjectForKey: (void *)((intptr_t)fd + 1)];
	} else {
		struct epoll_event event;

		memset(&event, 0, sizeof(event));
		event.events = (int)events;
		event.data.ptr = object;

		if (epoll_ctl(_epfd, EPOLL_CTL_MOD, fd, &event) == -1)
			@throw [OFObserveFailedException
			    exceptionWithObserver: self
					    errNo: errno];

		[_FDToEvents setObject: (void *)events
				forKey: (void *)((intptr_t)fd + 1)];
	}
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[self of_addObject: object
	    fileDescriptor: object.fileDescriptorForReading
		    events: EPOLLIN];

	[super addObjectForReading: object];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	[self of_addObject: object
	    fileDescriptor: object.fileDescriptorForWriting
		    events: EPOLLOUT];

	[super addObjectForWriting: object];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[self of_removeObject: object
	       fileDescriptor: object.fileDescriptorForReading
		       events: EPOLLIN];

	[super removeObjectForReading: object];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	[self of_removeObject: object
	       fileDescriptor: object.fileDescriptorForWriting
		       events: EPOLLOUT];

	[super removeObjectForWriting: object];
}

- (void)observeForTimeInterval: (OFTimeInterval)timeInterval
{
	OFNull *nullObject = [OFNull null];
	struct epoll_event eventList[EVENTLIST_SIZE];
	int events;

	if ([self of_processReadBuffers])
		return;

	events = epoll_wait(_epfd, eventList, EVENTLIST_SIZE,
	    (timeInterval != -1 ? timeInterval * 1000 : -1));

	if (events < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	for (int i = 0; i < events; i++) {
		if (eventList[i].events & EPOLLIN) {
			void *pool = objc_autoreleasePoolPush();

			if (eventList[i].data.ptr == nullObject) {
				char buffer;
				OF_ENSURE(read(_cancelFD[0], &buffer, 1) == 1);
				continue;
			}

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading:
				    eventList[i].data.ptr];

			objc_autoreleasePoolPop(pool);
		}

		if (eventList[i].events & EPOLLOUT) {
			void *pool = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting:
				    eventList[i].data.ptr];

			objc_autoreleasePoolPop(pool);
		}
	}
}
@end
