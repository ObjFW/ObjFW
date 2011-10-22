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
#import "OFAutoreleasePool.h"

@implementation OFStreamObserver_select
- init
{
	self = [super init];

	FD_ZERO(&readFDs);
	FD_ZERO(&writeFDs);

	FD_SET(cancelFD[0], &readFDs);

	return self;
}

- (void)_addFileDescriptorForReading: (int)fd
{
	FD_SET(fd, &readFDs);
	FD_SET(fd, &exceptFDs);
}

- (void)_addFileDescriptorForWriting: (int)fd
{
	FD_SET(fd, &writeFDs);
	FD_SET(fd, &exceptFDs);
}

- (void)_removeFileDescriptorForReading: (int)fd
{
	FD_CLR(fd, &readFDs);

	if (!FD_ISSET(fd, &writeFDs))
		FD_CLR(fd, &exceptFDs);
}

- (void)_removeFileDescriptorForWriting: (int)fd
{
	FD_CLR(fd, &writeFDs);

	if (!FD_ISSET(fd, &readFDs))
		FD_CLR(fd, &exceptFDs);
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

#ifdef FD_COPY
	FD_COPY(&readFDs, &readFDs_);
	FD_COPY(&writeFDs, &writeFDs_);
	FD_COPY(&exceptFDs, &exceptFDs_);
#else
	readFDs_ = readFDs;
	writeFDs_ = writeFDs;
	exceptFDs_ = exceptFDs;
#endif

	time.tv_sec = timeout / 1000;
	time.tv_usec = (timeout % 1000) * 1000;

	if (select((int)maxFD + 1, &readFDs_, &writeFDs_, &exceptFDs_,
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
			[delegate streamIsReadyForReading: cArray[i]];
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
			[delegate streamIsReadyForWriting: cArray[i]];
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
