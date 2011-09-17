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

#include <string.h>
#include <assert.h>
#include <unistd.h>

#import "OFStreamObserver_select.h"
#import "OFStream.h"
#import "OFArray.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

#ifdef _WIN32
# define close(sock) closesocket(sock)
#endif

enum {
	QUEUE_ADD = 0,
	QUEUE_REMOVE = 1,
	QUEUE_READ = 0,
	QUEUE_WRITE = 2
};

@implementation OFStreamObserver_select
- init
{
	self = [super init];

	FD_ZERO(&readFDs);
	FD_ZERO(&writeFDs);

	FD_SET(cancelFD[0], &readFDs);
	nFDs = cancelFD[0] + 1;

	return self;
}

- (void)_addStream: (OFStream*)stream
	 withFDSet: (fd_set*)FDSet
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	int fileDescriptor = [stream fileDescriptor];

	FD_SET(fileDescriptor, FDSet);
	FD_SET(fileDescriptor, &exceptFDs);

	if (fileDescriptor >= nFDs)
		nFDs = fileDescriptor + 1;

	[pool release];
}

- (void)_removeStream: (OFStream*)stream
	    withFDSet: (fd_set*)FDSet
	   otherFDSet: (fd_set*)otherFDSet
{
	int fileDescriptor = [stream fileDescriptor];

	FD_CLR(fileDescriptor, FDSet);

	if (!FD_ISSET(fileDescriptor, otherFDSet))
		FD_CLR(fileDescriptor, &exceptFDs);
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
				       withFDSet: &readFDs];

				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[writeStreams addObject: queueCArray[i]];

				[self _addStream: queueCArray[i]
				       withFDSet: &writeFDs];

				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[readStreams removeObjectIdenticalTo:
				    queueCArray[i]];

				[self _removeStream: queueCArray[i]
					  withFDSet: &readFDs
					 otherFDSet: &writeFDs];

				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[writeStreams removeObjectIdenticalTo:
				    queueCArray[i]];

				[self _removeStream: queueCArray[i]
					  withFDSet: &writeFDs
					 otherFDSet: &readFDs];

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
	OFStream **cArray;
	fd_set readFDs_;
	fd_set writeFDs_;
	fd_set exceptFDs_;
	struct timeval time;
	size_t i, count;

	[self _processQueue];

	if ([self _processCache])
		return YES;

# ifdef FD_COPY
	FD_COPY(&readFDs, &readFDs_);
	FD_COPY(&writeFDs, &writeFDs_);
	FD_COPY(&exceptFDs, &exceptFDs_);
# else
	readFDs_ = readFDs;
	writeFDs_ = writeFDs;
	exceptFDs_ = exceptFDs;
# endif

	time.tv_sec = timeout / 1000;
	time.tv_usec = (timeout % 1000) * 1000;

	if (select(nFDs, &readFDs_, &writeFDs_, &exceptFDs_,
	    (timeout != -1 ? &time : NULL)) < 1)
		return NO;

	if (FD_ISSET(cancelFD[0], &readFDs_)) {
		char buffer;
#ifndef _WIN32
		assert(read(cancelFD[0], &buffer, 1) > 0);
#else
		assert(recvfrom(cancelFD[0], &buffer, 1, 0, NULL, NULL) > 0);
#endif
	}

	cArray = [readStreams cArray];
	count = [readStreams count];

	for (i = 0; i < count; i++) {
		int fileDescriptor = [cArray[i] fileDescriptor];

		if (FD_ISSET(fileDescriptor, &readFDs_)) {
			[delegate streamDidBecomeReadyForReading: cArray[i]];
			[pool releaseObjects];
		}

		if (FD_ISSET(fileDescriptor, &exceptFDs_)) {
			[delegate streamDidReceiveException: cArray[i]];
			[pool releaseObjects];

			/*
			 * Prevent calling it twice in case the FD is in both
			 * sets.
			 */
			FD_CLR(fileDescriptor, &exceptFDs_);
		}
	}

	cArray = [writeStreams cArray];
	count = [writeStreams count];

	for (i = 0; i < count; i++) {
		int fileDescriptor = [cArray[i] fileDescriptor];

		if (FD_ISSET(fileDescriptor, &writeFDs_)) {
			[delegate streamDidBecomeReadyForWriting: cArray[i]];
			[pool releaseObjects];
		}

		if (FD_ISSET(fileDescriptor, &exceptFDs_)) {
			[delegate streamDidReceiveException: cArray[i]];
			[pool releaseObjects];
		}
	}

	[pool release];

	return YES;
}
@end
