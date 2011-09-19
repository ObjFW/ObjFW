/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#include <assert.h>
#include <unistd.h>
#include <poll.h>

#import "OFStreamObserver_poll.h"
#import "OFStream.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

#import "OFOutOfRangeException.h"

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

- (void)_addStream: (OFStream*)stream
	withEvents: (short)events
{
	struct pollfd *FDsCArray = [FDs cArray];
	size_t i, count = [FDs count];
	int fd = [stream fileDescriptor];
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

- (void)_removeStream: (OFStream*)stream
	   withEvents: (short)events
{
	struct pollfd *FDsCArray = [FDs cArray];
	size_t i, nFDs = [FDs count];
	int fileDescriptor = [stream fileDescriptor];

	for (i = 0; i < nFDs; i++) {
		if (FDsCArray[i].fd == fileDescriptor) {
			FDsCArray[i].events &= ~events;

			if ((FDsCArray[i].events & ~POLLERR) == 0)
				[FDs removeItemAtIndex: i];

			break;
		}
	}
}

- (void)_addStreamToObserveForReading: (OFStream*)stream
{
	[self _addStream: stream
	      withEvents: POLLIN];
}

- (void)_addStreamToObserveForWriting: (OFStream*)stream
{
	[self _addStream: stream
	      withEvents: POLLOUT];
}

- (void)_removeStreamToObserveForReading: (OFStream*)stream
{
	[self _removeStream: stream
		 withEvents: POLLIN];
}

- (void)_removeStreamToObserveForWriting: (OFStream*)stream
{
	[self _removeStream: stream
		 withEvents: POLLOUT];
}

- (BOOL)observeWithTimeout: (int)timeout
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	struct pollfd *FDsCArray;
	size_t i, nFDs;

	[self _processQueue];

	if ([self _processCache])
		return YES;

	FDsCArray = [FDs cArray];
	nFDs = [FDs count];

#ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException newWithClass: isa];
#endif

	if (poll(FDsCArray, (nfds_t)nFDs, timeout) < 1)
		return NO;

	for (i = 0; i < nFDs; i++) {
		if (FDsCArray[i].revents & POLLIN) {
			if (FDsCArray[i].fd == cancelFD[0]) {
				char buffer;

				assert(read(cancelFD[0], &buffer, 1) > 0);
				FDsCArray[i].revents = 0;

				continue;
			}

			[delegate streamDidBecomeReadyForReading:
			    FDToStream[FDsCArray[i].fd]];
			[pool releaseObjects];
		}

		if (FDsCArray[i].revents & POLLOUT) {
			[delegate streamDidBecomeReadyForReading:
			    FDToStream[FDsCArray[i].fd]];
			[pool releaseObjects];
		}

		if (FDsCArray[i].revents & POLLERR) {
			[delegate streamDidReceiveException:
			    FDToStream[FDsCArray[i].fd]];
			[pool releaseObjects];
		}

		FDsCArray[i].revents = 0;
	}

	[pool release];

	return YES;
}
@end
