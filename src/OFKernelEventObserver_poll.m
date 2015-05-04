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

#define __NO_EXT_QNX

#include "config.h"

#include <errno.h>

#ifdef HAVE_POLL_H
# include <poll.h>
#endif

#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#import "OFKernelEventObserver_poll.h"
#import "OFDataArray.h"

#import "OFObserveFailedException.h"
#import "OFOutOfRangeException.h"

#import "socket_helpers.h"

#ifdef __wii__
# define pollfd pollsd
# define fd socket
#endif

@implementation OFKernelEventObserver_poll
- init
{
	self = [super init];

	@try {
		struct pollfd p = { _cancelFD[0], POLLIN, 0 };

		_FDs = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct pollfd)];
		[_FDs addItem: &p];

		_maxFD = _cancelFD[0];
		_FDToObject = [self allocMemoryWithSize: sizeof(id)
						  count: _maxFD + 1];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_FDs release];

	[super dealloc];
}

- (void)OF_addObject: (id)object
      fileDescriptor: (int)fd
	      events: (short)events
{
	struct pollfd *FDs = [_FDs items];
	size_t i, count = [_FDs count];
	bool found = false;

	for (i = 0; i < count; i++) {
		if (FDs[i].fd == fd) {
			FDs[i].events |= events;
			found = true;
			break;
		}
	}

	if (!found) {
		struct pollfd p = { fd, events, 0 };

		if (fd > _maxFD) {
			_maxFD = fd;
			_FDToObject = [self resizeMemory: _FDToObject
						    size: sizeof(id)
						   count: _maxFD + 1];
		}

		_FDToObject[fd] = object;
		[_FDs addItem: &p];
	}
}

- (void)OF_removeObject: (id)object
	 fileDescriptor: (int)fd
		 events: (short)events
{
	struct pollfd *FDs = [_FDs items];
	size_t i, nFDs = [_FDs count];

	for (i = 0; i < nFDs; i++) {
		if (FDs[i].fd == fd) {
			FDs[i].events &= ~events;

			if (FDs[i].events == 0) {
				/*
				 * TODO: Remove from and resize _FDToObject,
				 *	 adjust _maxFD.
				 */
				[_FDs removeItemAtIndex: i];
			}

			break;
		}
	}
}

- (void)OF_addObjectForReading: (id)object
{
	[self OF_addObject: object
	    fileDescriptor: [object fileDescriptorForReading]
		    events: POLLIN];
}

- (void)OF_addObjectForWriting: (id)object
{
	[self OF_addObject: object
	    fileDescriptor: [object fileDescriptorForWriting]
		    events: POLLOUT];
}

- (void)OF_removeObjectForReading: (id)object
{
	[self OF_removeObject: object
	       fileDescriptor: [object fileDescriptorForReading]
		       events: POLLIN];
}

- (void)OF_removeObjectForWriting: (id)object
{
	[self OF_removeObject: object
	       fileDescriptor: [object fileDescriptorForWriting]
		       events: POLLOUT];
}

- (bool)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	void *pool = objc_autoreleasePoolPush();
	struct pollfd *FDs;
	int events;
	size_t i, nFDs, realEvents = 0;

	[self OF_processQueueAndStoreRemovedIn: nil];

	if ([self OF_processReadBuffers]) {
		objc_autoreleasePoolPop(pool);
		return true;
	}

	objc_autoreleasePoolPop(pool);

	FDs = [_FDs items];
	nFDs = [_FDs count];

#ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	events = poll(FDs, (nfds_t)nFDs,
	    (int)(timeInterval != -1 ? timeInterval * 1000 : -1));

	if (events < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	if (events == 0)
		return false;

	for (i = 0; i < nFDs; i++) {
		if (FDs[i].fd > _maxFD)
			@throw [OFOutOfRangeException exception];

		if (FDs[i].revents & POLLIN) {
			if (FDs[i].fd == _cancelFD[0]) {
				char buffer;

				OF_ENSURE(read(_cancelFD[0], &buffer, 1) == 1);
				FDs[i].revents = 0;

				continue;
			}

			pool = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading:
				    _FDToObject[FDs[i].fd]];

			objc_autoreleasePoolPop(pool);

			realEvents++;
		}

		if (FDs[i].revents & POLLOUT) {
			pool = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting:
				    _FDToObject[FDs[i].fd]];

			objc_autoreleasePoolPop(pool);

			realEvents++;
		}

		FDs[i].revents = 0;
	}

	if (realEvents == 0)
		return false;

	return true;
}
@end
