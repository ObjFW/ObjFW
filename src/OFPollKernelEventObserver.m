/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include <assert.h>
#include <errno.h>

#ifdef HAVE_POLL_H
# include <poll.h>
#endif

#import "OFPollKernelEventObserver.h"
#import "OFData.h"

#import "OFObserveFailedException.h"
#import "OFOutOfRangeException.h"

#import "socket_helpers.h"

#ifdef OF_WII
# define pollfd pollsd
# define fd socket
#endif

@implementation OFPollKernelEventObserver
- (instancetype)init
{
	self = [super init];

	@try {
		struct pollfd p = { _cancelFD[0], POLLIN, 0 };

		_FDs = [[OFMutableData alloc] initWithItemSize:
		    sizeof(struct pollfd)];
		[_FDs addItem: &p];

		_maxFD = _cancelFD[0];
		_FDToObject = of_malloc((size_t)_maxFD + 1, sizeof(id));
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_FDs release];
	free(_FDToObject);

	[super dealloc];
}

- (void)of_addObject: (id)object
      fileDescriptor: (int)fd
	      events: (short)events OF_DIRECT
{
	struct pollfd *FDs;
	size_t count;
	bool found;

	if (fd < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: EBADF];

	FDs = _FDs.mutableItems;
	count = _FDs.count;
	found = false;

	for (size_t i = 0; i < count; i++) {
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
			_FDToObject = of_realloc(_FDToObject,
			    (size_t)_maxFD + 1, sizeof(id));
		}

		_FDToObject[fd] = object;
		[_FDs addItem: &p];
	}
}

- (void)of_removeObject: (id)object
	 fileDescriptor: (int)fd
		 events: (short)events OF_DIRECT
{
	struct pollfd *FDs;
	size_t nFDs;

	if (fd < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: EBADF];

	FDs = _FDs.mutableItems;
	nFDs = _FDs.count;

	for (size_t i = 0; i < nFDs; i++) {
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

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[self of_addObject: object
	    fileDescriptor: object.fileDescriptorForReading
		    events: POLLIN];

	[super addObjectForReading: object];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	[self of_addObject: object
	    fileDescriptor: object.fileDescriptorForWriting
		    events: POLLOUT];

	[super addObjectForWriting: object];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[self of_removeObject: object
	       fileDescriptor: object.fileDescriptorForReading
		       events: POLLIN];

	[super removeObjectForReading: object];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	[self of_removeObject: object
	       fileDescriptor: object.fileDescriptorForWriting
		       events: POLLOUT];

	[super removeObjectForWriting: object];
}

- (void)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	void *pool;
	struct pollfd *FDs;
	int events;
	size_t nFDs;

	if ([self of_processReadBuffers])
		return;

	pool = objc_autoreleasePoolPush();

	FDs = [[[_FDs mutableCopy] autorelease] mutableItems];
	nFDs = _FDs.count;

#ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	events = poll(FDs, (nfds_t)nFDs,
	    (int)(timeInterval != -1 ? timeInterval * 1000 : -1));

	if (events < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	for (size_t i = 0; i < nFDs; i++) {
		assert(FDs[i].fd <= _maxFD);

		if (FDs[i].revents & POLLIN) {
			void *pool2;

			if (FDs[i].fd == _cancelFD[0]) {
				char buffer;

#ifdef OF_HAVE_PIPE
				OF_ENSURE(read(_cancelFD[0], &buffer, 1) == 1);
#else
				OF_ENSURE(recvfrom(_cancelFD[0], &buffer, 1,
				    0, NULL, NULL) == 1);
#endif
				FDs[i].revents = 0;

				continue;
			}

			pool2 = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading:
				    _FDToObject[FDs[i].fd]];

			objc_autoreleasePoolPop(pool2);
		}

		if (FDs[i].revents & (POLLOUT | POLLHUP)) {
			void *pool2 = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting:
				    _FDToObject[FDs[i].fd]];

			objc_autoreleasePoolPop(pool2);
		}

		FDs[i].revents = 0;
	}

	objc_autoreleasePoolPop(pool);
}
@end
