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

#include <sys/epoll.h>

#import "OFEpollKernelEventObserver.h"
#import "OFArray.h"
#import "OFMapTable.h"
#import "OFNull.h"
#import "OFPair.h"

#import "OFInitializationFailedException.h"
#import "OFObserveKernelEventsFailedException.h"

#define eventListSize 64

static void
releaseEvent(void *object)
{
	struct epoll_event *event = object;

	objc_release(event->data.ptr);
	OFFreeMemory(event);
}

static const OFMapTableFunctions keyFunctions = { NULL };
static const OFMapTableFunctions objectFunctions = {
	.release = releaseEvent
};

@implementation OFEpollKernelEventObserver
- (instancetype)initWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	self = [super initWithRunLoopMode: runLoopMode];

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

		_FDToEvent = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions];

		memset(&event, 0, sizeof(event));
		event.events = EPOLLIN;
		event.data.ptr = [OFNull null];

		if (epoll_ctl(_epfd, EPOLL_CTL_ADD, _cancelFD[0], &event) == -1)
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
	close(_epfd);

	objc_release(_FDToEvent);

	[super dealloc];
}

- (void)of_addObject: (id)object
      fileDescriptor: (int)fd
	      events: (uint32_t)addEvents OF_DIRECT
{
	struct epoll_event *event =
	    [_FDToEvent objectForKey: (void *)((intptr_t)fd + 1)];
	uint32_t oldEvents;

	if (event == NULL) {
		event = OFAllocZeroedMemory(1, sizeof(*event));
		@try {
			event->data.ptr = [[OFMutablePair alloc] init];

			[_FDToEvent setObject: event 
				       forKey: (void *)((intptr_t)fd + 1)];
		} @catch (id e) {
			OFFreeMemory(event);
			@throw e;
		}
	}

	oldEvents = event->events;
	event->events |= addEvents;

	if (epoll_ctl(_epfd, (oldEvents == 0 ? EPOLL_CTL_ADD : EPOLL_CTL_MOD),
	    fd, event) == -1) {
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: errno];
	}

	if (addEvents == EPOLLIN)
		((OFMutablePair *)event->data.ptr).firstObject = object;
	else if (addEvents == EPOLLOUT)
		((OFMutablePair *)event->data.ptr).secondObject = object;
	else
		OFEnsure(0);
}

- (void)of_removeObject: (id)object
	 fileDescriptor: (int)fd
		 events: (uint32_t)removeEvents OF_DIRECT
{
	struct epoll_event *event =
	    [_FDToEvent objectForKey: (void *)((intptr_t)fd + 1)];

	if (event == NULL)
		return;

	event->events &= ~removeEvents;

	if (event->events == 0) {
		if (epoll_ctl(_epfd, EPOLL_CTL_DEL, fd, NULL) == -1)
			/*
			 * When an async connect fails, it seems the socket is
			 * automatically removed from epoll, meaning ENOENT is
			 * returned when we try to remove it after it failed.
			 */
			if (errno != ENOENT)
				@throw [OFObserveKernelEventsFailedException
				    exceptionWithObserver: self
						    errNo: errno];

		[_FDToEvent removeObjectForKey: (void *)((intptr_t)fd + 1)];
	} else {
		if (epoll_ctl(_epfd, EPOLL_CTL_MOD, fd, event) == -1)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errno];

		if (removeEvents == EPOLLIN)
			((OFMutablePair *)event->data.ptr).firstObject = nil;
		else if (removeEvents == EPOLLOUT)
			((OFMutablePair *)event->data.ptr).secondObject = nil;
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
	struct epoll_event eventList[eventListSize];
	int events;

	if ([self processReadBuffers])
		return;

	while ((events = epoll_wait(_epfd, eventList, eventListSize,
	    (timeInterval != -1 ? timeInterval * 1000 : -1))) < 0)
		if (errno != EINTR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errno];

	for (int i = 0; i < events; i++) {
		if (eventList[i].events & EPOLLIN) {
			void *pool = objc_autoreleasePoolPush();

			if (eventList[i].data.ptr == nullObject) {
				char buffer;
				OFEnsure(read(_cancelFD[0], &buffer, 1) == 1);
				continue;
			}

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading:
				    ((OFPair *)eventList[i].data.ptr)
				    .firstObject];

			objc_autoreleasePoolPop(pool);
		}

		if (eventList[i].events & EPOLLOUT) {
			void *pool = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting:
				    ((OFPair *)eventList[i].data.ptr)
				    .secondObject];

			objc_autoreleasePoolPop(pool);
		}
	}
}
@end
