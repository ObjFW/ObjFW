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
#include <math.h>

#include <fcntl.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#import "OFKernelEventObserver_kqueue.h"
#import "OFDataArray.h"
#import "OFArray.h"

#import "OFInitializationFailedException.h"
#import "OFObserveFailedException.h"
#import "OFOutOfRangeException.h"

#define EVENTLIST_SIZE 64

@implementation OFKernelEventObserver_kqueue
- init
{
	self = [super init];

	@try {
		struct kevent event;

#ifdef HAVE_KQUEUE1
		if ((_kernelQueue = kqueue1(O_CLOEXEC)) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
#else
		int flags;

		if ((_kernelQueue = kqueue()) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		if ((flags = fcntl(_kernelQueue, F_GETFD, 0)) != -1)
			fcntl(_kernelQueue, F_SETFD, flags | FD_CLOEXEC);
#endif

		_changeList = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct kevent)];
		EV_SET(&event, _cancelFD[0], EVFILT_READ, EV_ADD, 0, 0, 0);
		[_changeList addItem: &event];

		_removedArray = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	close(_kernelQueue);

	[_changeList release];
	[_removedArray release];

	[super dealloc];
}

- (void)OF_addObjectForReading: (id)object
{
	struct kevent event;

	if ([_changeList count] >= INT_MAX)
		@throw [OFOutOfRangeException exception];

	memset(&event, 0, sizeof(event));
	event.ident = [object fileDescriptorForReading];
	event.filter = EVFILT_READ;
	event.flags = EV_ADD;
#ifndef OF_NETBSD
	event.udata = object;
#else
	event.udata = (intptr_t)object;
#endif

	[_changeList addItem: &event];
}

- (void)OF_addObjectForWriting: (id)object
{
	struct kevent event;

	if ([_changeList count] >= INT_MAX)
		@throw [OFOutOfRangeException exception];

	memset(&event, 0, sizeof(event));
	event.ident = [object fileDescriptorForWriting];
	event.filter = EVFILT_WRITE;
	event.flags = EV_ADD;
#ifndef OF_NETBSD
	event.udata = object;
#else
	event.udata = (intptr_t)object;
#endif

	[_changeList addItem: &event];
}

- (void)OF_removeObjectForReading: (id)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = [object fileDescriptorForReading];
	event.filter = EVFILT_READ;
	event.flags = EV_DELETE;
	[_changeList addItem: &event];
}

- (void)OF_removeObjectForWriting: (id)object
{
	struct kevent event;

	memset(&event, 0, sizeof(event));
	event.ident = [object fileDescriptorForWriting];
	event.filter = EVFILT_WRITE;
	event.flags = EV_DELETE;
	[_changeList addItem: &event];
}

- (void)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	void *pool = objc_autoreleasePoolPush();
	struct timespec timeout;
	struct kevent eventList[EVENTLIST_SIZE];
	int i, events;

	timeout.tv_sec = (time_t)timeInterval;
	timeout.tv_nsec = lrint((timeInterval - timeout.tv_sec) * 1000000000);

	/*
	 * Make sure to keep the streams retained and thus the file descriptors
	 * valid until the actual change has been performed.
	 */
	[self OF_processQueueAndStoreRemovedIn: _removedArray];

	[self OF_processReadBuffers];

	objc_autoreleasePoolPop(pool);

	events = kevent(_kernelQueue, [_changeList items],
	    (int)[_changeList count], eventList, EVENTLIST_SIZE,
	    (timeInterval != -1 ? &timeout : NULL));

	if (events < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	[_changeList removeAllItems];
	[_removedArray removeAllObjects];

	for (i = 0; i < events; i++) {
		if (eventList[i].flags & EV_ERROR)
			@throw [OFObserveFailedException
			    exceptionWithObserver: self
					    errNo: (int)eventList[i].data];

		if (eventList[i].ident == _cancelFD[0]) {
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
