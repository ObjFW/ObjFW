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

#ifdef HAVE_POLL_H
# include <poll.h>
#endif

#import "OFPollKernelEventObserver.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFNull.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFObserveKernelEventsFailedException.h"
#import "OFOutOfRangeException.h"

#ifdef OF_WII
# define pollfd pollsd
# define fd socket
#endif

@implementation OFPollKernelEventObserver
- (instancetype)initWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	self = [super initWithRunLoopMode: runLoopMode];

	@try {
		struct pollfd p = { _cancelFD[0], POLLIN, 0 };

		_FDs = [[OFMutableData alloc] initWithItemSize:
		    sizeof(struct pollfd)];
		[_FDs addItem: &p];

		_objects = [[OFMutableArray alloc]
		    initWithObject: [OFNull null]];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_FDs);
	objc_release(_objects);

	[super dealloc];
}

static void
addObject(OFPollKernelEventObserver *self, id object, int fd, short events)
{
	struct pollfd p = { fd, events, 0 };
	struct pollfd *FDs;
	size_t count;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];

	FDs = self->_FDs.mutableItems;
	count = self->_FDs.count;

	for (size_t i = 0; i < count; i++) {
		if (FDs[i].fd == fd) {
			FDs[i].events |= events;
			return;
		}
	}

	[self->_FDs addItem: &p];
	[self->_objects addObject: object];
}

static void
removeObject(OFPollKernelEventObserver *self, id object, int fd, short events)
{
	struct pollfd *FDs;
	size_t nFDs;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];

	FDs = self->_FDs.mutableItems;
	nFDs = self->_FDs.count;

	for (size_t i = 0; i < nFDs; i++) {
		if (FDs[i].fd == fd) {
			FDs[i].events &= ~events;

			if (FDs[i].events == 0) {
				[self->_FDs removeItemAtIndex: i];
				[self->_objects removeObjectAtIndex: i];
			}

			break;
		}
	}
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	addObject(self, object, object.fileDescriptorForReading, POLLIN);

	[super addObjectForReading: object];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	addObject(self, object, object.fileDescriptorForWriting, POLLOUT);

	[super addObjectForWriting: object];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	removeObject(self, object, object.fileDescriptorForReading, POLLIN);

	[super removeObjectForReading: object];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	removeObject(self, object, object.fileDescriptorForWriting, POLLOUT);

	[super removeObjectForWriting: object];
}

- (void)observeForTimeInterval: (OFTimeInterval)timeInterval
{
	void *pool;
	struct pollfd *FDs;
	OFArray *objects;
	size_t nFDs;

	if ([self processReadBuffers])
		return;

	pool = objc_autoreleasePoolPush();

	FDs = [objc_autorelease([_FDs mutableCopy]) mutableItems];
	objects = objc_autorelease([_objects copy]);
	nFDs = _FDs.count;

	OFAssert(objects.count == nFDs);

#ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException exception];
#endif

	while (poll(FDs, (nfds_t)nFDs,
	    (int)(timeInterval != -1 ? timeInterval * 1000 : -1)) < 0) {
		int errNo = _OFSocketErrNo();

		if (errNo != EINTR)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: errNo];
	}

	for (size_t i = 0; i < nFDs; i++) {
		if (FDs[i].revents & POLLIN) {
			void *pool2;

			if (FDs[i].fd == _cancelFD[0]) {
				char buffer;

#ifdef OF_HAVE_PIPE
				OFEnsure(read(_cancelFD[0], &buffer, 1) == 1);
#else
				OFEnsure(recvfrom(_cancelFD[0], &buffer, 1, 0,
				    NULL, NULL) == 1);
#endif
				FDs[i].revents = 0;

				continue;
			}

			pool2 = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading:
				    [objects objectAtIndex: i]];

			objc_autoreleasePoolPop(pool2);
		}

		if (FDs[i].revents & (POLLOUT | POLLHUP)) {
			void *pool2 = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting:
				    [objects objectAtIndex: i]];

			objc_autoreleasePoolPop(pool2);
		}
	}

	objc_autoreleasePoolPop(pool);
}
@end
