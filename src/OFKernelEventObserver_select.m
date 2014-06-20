/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include <string.h>
#include <math.h>

#include <sys/time.h>

#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#import "OFKernelEventObserver_select.h"
#import "OFArray.h"

#import "socket_helpers.h"

@implementation OFKernelEventObserver_select
- init
{
	self = [super init];

	FD_ZERO(&_readFDs);
	FD_ZERO(&_writeFDs);

	FD_SET(_cancelFD[0], &_readFDs);

	return self;
}

- (void)OF_addFileDescriptorForReading: (int)fd
{
	FD_SET(fd, &_readFDs);
}

- (void)OF_addFileDescriptorForWriting: (int)fd
{
	FD_SET(fd, &_writeFDs);
}

- (void)OF_removeFileDescriptorForReading: (int)fd
{
	FD_CLR(fd, &_readFDs);
}

- (void)OF_removeFileDescriptorForWriting: (int)fd
{
	FD_CLR(fd, &_writeFDs);
}

- (bool)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	void *pool = objc_autoreleasePoolPush();
	id const *objects;
	fd_set readFDs;
	fd_set writeFDs;
	struct timeval timeout;
	size_t i, count, realEvents = 0;

	[self OF_processQueue];

	if ([self OF_processCache]) {
		objc_autoreleasePoolPop(pool);
		return true;
	}

	objc_autoreleasePoolPop(pool);

#ifdef FD_COPY
	FD_COPY(&_readFDs, &readFDs);
	FD_COPY(&_writeFDs, &writeFDs);
#else
	readFDs = _readFDs;
	writeFDs = _writeFDs;
#endif

	/*
	 * We cast to int before assigning to tv_usec in order to avoid a
	 * warning with Apple GCC on PPC. POSIX defines this as suseconds_t,
	 * however, this is not available on Win32. As an int should always
	 * satisfy the required range, we just cast to int.
	 */
#ifndef _WIN32
	timeout.tv_sec = (time_t)timeInterval;
#else
	timeout.tv_sec = (long)timeInterval;
#endif
	timeout.tv_usec = (int)lrint((timeInterval - timeout.tv_sec) * 1000);

	if (select((int)_maxFD + 1, &readFDs, &writeFDs, NULL,
	    (timeInterval != -1 ? &timeout : NULL)) < 1)
		return false;

	if (FD_ISSET(_cancelFD[0], &readFDs)) {
		char buffer;
#ifndef _WIN32
		OF_ENSURE(read(_cancelFD[0], &buffer, 1) > 0);
#else
		OF_ENSURE(recvfrom(_cancelFD[0], &buffer, 1, 0, NULL,
		    NULL) > 0);
#endif
	}

	objects = [_readObjects objects];
	count = [_readObjects count];

	for (i = 0; i < count; i++) {
		int fd = [objects[i] fileDescriptorForReading];

		pool = objc_autoreleasePoolPush();

		if (FD_ISSET(fd, &readFDs)) {
			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading: objects[i]];

			realEvents++;
		}

		objc_autoreleasePoolPop(pool);
	}

	objects = [_writeObjects objects];
	count = [_writeObjects count];

	for (i = 0; i < count; i++) {
		int fd = [objects[i] fileDescriptorForWriting];

		pool = objc_autoreleasePoolPush();

		if (FD_ISSET(fd, &writeFDs)) {
			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting: objects[i]];

			realEvents++;
		}

		objc_autoreleasePoolPop(pool);
	}

	if (realEvents == 0)
		return false;

	return true;
}
@end
