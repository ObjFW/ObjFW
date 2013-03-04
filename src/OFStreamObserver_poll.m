/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#define __NO_EXT_QNX

#include <unistd.h>
#include <poll.h>

#import "OFStreamObserver_poll.h"
#import "OFDataArray.h"

#import "OFOutOfRangeException.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFStreamObserver_poll
- init
{
	self = [super init];

	@try {
		struct pollfd p = { 0, POLLIN, 0 };

		_FDs = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct pollfd)];

		p.fd = _cancelFD[0];
		[_FDs addItem: &p];
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

- (void)OF_addFileDescriptor: (int)fd
		  withEvents: (short)events
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
		struct pollfd p = { fd, events | POLLERR, 0 };
		[_FDs addItem: &p];
	}
}

- (void)OF_removeFileDescriptor: (int)fd
		     withEvents: (short)events
{
	struct pollfd *FDs = [_FDs items];
	size_t i, nFDs = [_FDs count];

	for (i = 0; i < nFDs; i++) {
		if (FDs[i].fd == fd) {
			FDs[i].events &= ~events;

			if ((FDs[i].events & ~POLLERR) == 0)
				[_FDs removeItemAtIndex: i];

			break;
		}
	}
}

- (void)OF_addFileDescriptorForReading: (int)fd
{
	[self OF_addFileDescriptor: fd
			withEvents: POLLIN];
}

- (void)OF_addFileDescriptorForWriting: (int)fd
{
	[self OF_addFileDescriptor: fd
			withEvents: POLLOUT];
}

- (void)OF_removeFileDescriptorForReading: (int)fd
{
	[self OF_removeFileDescriptor: fd
			   withEvents: POLLIN];
}

- (void)OF_removeFileDescriptorForWriting: (int)fd
{
	[self OF_removeFileDescriptor: fd
			   withEvents: POLLOUT];
}

- (bool)observeWithTimeout: (double)timeout
{
	void *pool = objc_autoreleasePoolPush();
	struct pollfd *FDs;
	size_t i, nFDs, realEvents = 0;

	[self OF_processQueue];

	if ([self OF_processCache]) {
		objc_autoreleasePoolPop(pool);
		return true;
	}

	objc_autoreleasePoolPop(pool);

	FDs = [_FDs items];
	nFDs = [_FDs count];

#ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];
#endif

	if (poll(FDs, (nfds_t)nFDs,
	    (int)(timeout != -1 ? timeout * 1000 : -1)) < 1)
		return false;

	for (i = 0; i < nFDs; i++) {
		pool = objc_autoreleasePoolPush();

		if (FDs[i].revents & POLLIN) {
			if (FDs[i].fd == _cancelFD[0]) {
				char buffer;

				OF_ENSURE(read(_cancelFD[0], &buffer, 1) > 0);
				FDs[i].revents = 0;

				objc_autoreleasePoolPop(pool);
				continue;
			}

			if ([_delegate respondsToSelector:
			    @selector(streamIsReadyForReading:)])
				[_delegate streamIsReadyForReading:
				    _FDToStream[FDs[i].fd]];

			realEvents++;
		}

		if (FDs[i].revents & POLLOUT) {
			if ([_delegate respondsToSelector:
			    @selector(streamIsReadyForWriting:)])
				[_delegate streamIsReadyForWriting:
				    _FDToStream[FDs[i].fd]];

			realEvents++;
		}

		if (FDs[i].revents & POLLERR) {
			if ([_delegate respondsToSelector:
			    @selector(streamDidReceiveException:)])
				[_delegate streamDidReceiveException:
				    _FDToStream[FDs[i].fd]];

			realEvents++;
		}

		FDs[i].revents = 0;

		objc_autoreleasePoolPop(pool);
	}

	if (realEvents == 0)
		return false;

	return true;
}
@end
