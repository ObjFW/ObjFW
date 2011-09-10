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

#import "OFStreamPollObserver.h"
#import "OFStream.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

#import "OFOutOfRangeException.h"

enum {
	QUEUE_ADD = 0,
	QUEUE_REMOVE = 1,
	QUEUE_READ = 0,
	QUEUE_WRITE = 2
};

@implementation OFStreamPollObserver

- init
{
	self = [super init];

	@try {
		struct pollfd p = { 0, POLLIN, 0 };

		FDs = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct pollfd)];
		FDToStream = [[OFMutableDictionary alloc] init];

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
	[FDToStream release];
	[FDs release];

	[super dealloc];
}


- (void)_addStream: (OFStream*)stream
	withEvents: (short)events
{
	struct pollfd *FDsCArray = [FDs cArray];
	size_t i, count = [FDs count];
	int fileDescriptor = [stream fileDescriptor];
	BOOL found = NO;

	for (i = 0; i < count; i++) {
		if (FDsCArray[i].fd == fileDescriptor) {
			FDsCArray[i].events |= events;
			found = YES;
		}
	}

	if (!found) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		struct pollfd p = { fileDescriptor, events | POLLERR, 0 };
		[FDs addItem: &p];
		[FDToStream setObject: stream
			       forKey: [OFNumber numberWithInt:
				       fileDescriptor]];
		[pool release];
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
			OFAutoreleasePool *pool;

			FDsCArray[i].events &= ~events;

			if ((FDsCArray[i].events & ~POLLERR) != 0)
				return;

			pool = [[OFAutoreleasePool alloc] init];

			[FDs removeItemAtIndex: i];
			[FDToStream removeObjectForKey:
			    [OFNumber numberWithInt: fileDescriptor]];

			[pool release];
		}
	}
}

- (void)_processQueue
{
	@synchronized (queue) {
		OFStream **queueCArray = [queue cArray];
		OFNumber **queueInfoCArray = [queueInfo cArray];
		size_t i, count = [queue count];

		for (i = 0; i < count; i++) {
			switch ([queueInfoCArray[i] intValue]) {
			case QUEUE_ADD | QUEUE_READ:
				[readStreams addObject: queueCArray[i]];

				[self _addStream: queueCArray[i]
				      withEvents: POLLIN];

				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[writeStreams addObject: queueCArray[i]];

				[self _addStream: queueCArray[i]
				      withEvents: POLLOUT];

				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[readStreams removeObjectIdenticalTo:
				    queueCArray[i]];

				[self _removeStream: queueCArray[i]
					 withEvents: POLLIN];

				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[writeStreams removeObjectIdenticalTo:
				    queueCArray[i]];

				[self _removeStream: queueCArray[i]
					 withEvents: POLLOUT];

				break;
			default:
				assert(0);
			}
		}

		[queue removeNObjects: count];
		[queueInfo removeNObjects: count];
	}
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
		OFNumber *num;
		OFStream *stream;

		if (FDsCArray[i].revents & POLLIN) {
			if (FDsCArray[i].fd == cancelFD[0]) {
				char buffer;

				assert(read(cancelFD[0], &buffer, 1) > 0);
				FDsCArray[i].revents = 0;

				continue;
			}

			num = [OFNumber numberWithInt: FDsCArray[i].fd];
			stream = [FDToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
			[pool releaseObjects];
		}

		if (FDsCArray[i].revents & POLLOUT) {
			num = [OFNumber numberWithInt: FDsCArray[i].fd];
			stream = [FDToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
			[pool releaseObjects];
		}

		if (FDsCArray[i].revents & POLLERR) {
			num = [OFNumber numberWithInt: FDsCArray[i].fd];
			stream = [FDToStream objectForKey: num];
			[delegate streamDidReceiveException: stream];
			[pool releaseObjects];
		}

		FDsCArray[i].revents = 0;
	}

	[pool release];

	return YES;
}
@end
