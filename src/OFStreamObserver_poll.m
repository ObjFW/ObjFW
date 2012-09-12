/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

- (void)_addFileDescriptor: (int)fd
		withEvents: (short)events
{
	struct pollfd *FDsCArray = [FDs cArray];
	size_t i, count = [FDs count];
	BOOL found = NO;

	for (i = 0; i < count; i++) {
		if (FDsCArray[i].fd == fd) {
			FDsCArray[i].events |= events;
			found = YES;
			break;
		}
	}

	if (!found) {
		struct pollfd p = { fd, events | POLLERR, 0 };
		[FDs addItem: &p];
	}
}

- (void)_removeFileDescriptor: (int)fd
		   withEvents: (short)events
{
	struct pollfd *FDsCArray = [FDs cArray];
	size_t i, nFDs = [FDs count];

	for (i = 0; i < nFDs; i++) {
		if (FDsCArray[i].fd == fd) {
			FDsCArray[i].events &= ~events;

			if ((FDsCArray[i].events & ~POLLERR) == 0)
				[FDs removeItemAtIndex: i];

			break;
		}
	}
}

- (void)_addFileDescriptorForReading: (int)fd
{
	[self _addFileDescriptor: fd
		      withEvents: POLLIN];
}

- (void)_addFileDescriptorForWriting: (int)fd
{
	[self _addFileDescriptor: fd
		      withEvents: POLLOUT];
}

- (void)_removeFileDescriptorForReading: (int)fd
{
	[self _removeFileDescriptor: fd
			 withEvents: POLLIN];
}

- (void)_removeFileDescriptorForWriting: (int)fd
{
	[self _removeFileDescriptor: fd
			 withEvents: POLLOUT];
}

- (BOOL)observeWithTimeout: (double)timeout
{
	void *pool = objc_autoreleasePoolPush();
	struct pollfd *FDsCArray;
	size_t i, nFDs, realEvents = 0;

	[self _processQueue];

	if ([self _processCache]) {
		objc_autoreleasePoolPop(pool);
		return YES;
	}

	objc_autoreleasePoolPop(pool);

	FDsCArray = [FDs cArray];
	nFDs = [FDs count];

#ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];
#endif

	if (poll(FDsCArray, (nfds_t)nFDs,
	    (timeout != -1 ? timeout * 1000 : -1)) < 1)
		return NO;

	for (i = 0; i < nFDs; i++) {
		pool = objc_autoreleasePoolPush();

		if (FDsCArray[i].revents & POLLIN) {
			if (FDsCArray[i].fd == cancelFD[0]) {
				char buffer;

				OF_ENSURE(read(cancelFD[0], &buffer, 1) > 0);
				FDsCArray[i].revents = 0;

				objc_autoreleasePoolPop(pool);
				continue;
			}

			realEvents++;
			[delegate streamIsReadyForReading:
			    FDToStream[FDsCArray[i].fd]];
		}

		if (FDsCArray[i].revents & POLLOUT) {
			realEvents++;
			[delegate streamIsReadyForWriting:
			    FDToStream[FDsCArray[i].fd]];
		}

		if (FDsCArray[i].revents & POLLERR) {
			realEvents++;
			[delegate streamDidReceiveException:
			    FDToStream[FDsCArray[i].fd]];
		}

		FDsCArray[i].revents = 0;

		objc_autoreleasePoolPop(pool);
	}

	if (realEvents == 0)
		return NO;

	return YES;
}
@end
