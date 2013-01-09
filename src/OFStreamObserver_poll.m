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

		FDs = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct pollfd)];

		p.fd = cancelFD[0];
		[FDs addItem: &p];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[FDs release];

	[super dealloc];
}

- (void)OF_addFileDescriptor: (int)fd
		  withEvents: (short)events
{
	struct pollfd *FDs_ = [FDs items];
	size_t i, count = [FDs count];
	BOOL found = NO;

	for (i = 0; i < count; i++) {
		if (FDs_[i].fd == fd) {
			FDs_[i].events |= events;
			found = YES;
			break;
		}
	}

	if (!found) {
		struct pollfd p = { fd, events | POLLERR, 0 };
		[FDs addItem: &p];
	}
}

- (void)OF_removeFileDescriptor: (int)fd
		     withEvents: (short)events
{
	struct pollfd *FDs_ = [FDs items];
	size_t i, nFDs = [FDs count];

	for (i = 0; i < nFDs; i++) {
		if (FDs_[i].fd == fd) {
			FDs_[i].events &= ~events;

			if ((FDs_[i].events & ~POLLERR) == 0)
				[FDs removeItemAtIndex: i];

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

- (BOOL)observeWithTimeout: (double)timeout
{
	void *pool = objc_autoreleasePoolPush();
	struct pollfd *FDs_;
	size_t i, nFDs, realEvents = 0;

	[self OF_processQueue];

	if ([self OF_processCache]) {
		objc_autoreleasePoolPop(pool);
		return YES;
	}

	objc_autoreleasePoolPop(pool);

	FDs_ = [FDs items];
	nFDs = [FDs count];

#ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];
#endif

	if (poll(FDs_, (nfds_t)nFDs,
	    (int)(timeout != -1 ? timeout * 1000 : -1)) < 1)
		return NO;

	for (i = 0; i < nFDs; i++) {
		pool = objc_autoreleasePoolPush();

		if (FDs_[i].revents & POLLIN) {
			if (FDs_[i].fd == cancelFD[0]) {
				char buffer;

				OF_ENSURE(read(cancelFD[0], &buffer, 1) > 0);
				FDs_[i].revents = 0;

				objc_autoreleasePoolPop(pool);
				continue;
			}

			if ([delegate respondsToSelector:
			    @selector(streamIsReadyForReading:)])
				[delegate streamIsReadyForReading:
				    FDToStream[FDs_[i].fd]];

			realEvents++;
		}

		if (FDs_[i].revents & POLLOUT) {
			if ([delegate respondsToSelector:
			    @selector(streamIsReadyForWriting:)])
				[delegate streamIsReadyForWriting:
				    FDToStream[FDs_[i].fd]];

			realEvents++;
		}

		if (FDs_[i].revents & POLLERR) {
			if ([delegate respondsToSelector:
			    @selector(streamDidReceiveException:)])
				[delegate streamDidReceiveException:
				    FDToStream[FDs_[i].fd]];

			realEvents++;
		}

		FDs_[i].revents = 0;

		objc_autoreleasePoolPop(pool);
	}

	if (realEvents == 0)
		return NO;

	return YES;
}
@end
