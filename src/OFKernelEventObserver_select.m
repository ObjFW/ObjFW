/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#ifdef _WIN32
/* Win32 has a ridiculous default of 64, even though it supports much more. */
# define FD_SETSIZE 1024
#endif

#include <errno.h>
#include <math.h>
#include <string.h>

#include <sys/time.h>

#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#import "OFKernelEventObserver_select.h"
#import "OFArray.h"

#import "OFInitializationFailedException.h"
#import "OFObserveFailedException.h"
#import "OFOutOfRangeException.h"

#import "socket_helpers.h"

@implementation OFKernelEventObserver_select
- init
{
	self = [super init];

#ifndef _WIN32
	if (_cancelFD[0] >= FD_SETSIZE)
		@throw [OFInitializationFailedException exception];
#endif

	FD_ZERO(&_readFDs);
	FD_ZERO(&_writeFDs);
	FD_SET(_cancelFD[0], &_readFDs);

	if (_cancelFD[0] > INT_MAX)
		@throw [OFOutOfRangeException exception];

	_maxFD = (int)_cancelFD[0];

	return self;
}

- (void)OF_addObjectForReading: (id)object
		fileDescriptor: (int)fd
{
	if (fd < 0 || fd > INT_MAX - 1)
		@throw [OFOutOfRangeException exception];

#ifndef _WIN32
	if (fd >= FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	if (fd > _maxFD)
		_maxFD = fd;

	FD_SET(fd, &_readFDs);
}

- (void)OF_addObjectForWriting: (id)object
		fileDescriptor: (int)fd
{
	if (fd < 0 || fd > INT_MAX - 1)
		@throw [OFOutOfRangeException exception];

#ifndef _WIN32
	if (fd >= FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	if (fd > _maxFD)
		_maxFD = fd;

	FD_SET(fd, &_writeFDs);
}

- (void)OF_removeObjectForReading: (id)object
		   fileDescriptor: (int)fd
{
	/* TODO: Adjust _maxFD */

	if (fd < 0)
		@throw [OFOutOfRangeException exception];

#ifndef _WIN32
	if (fd >= FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	FD_CLR(fd, &_readFDs);
}

- (void)OF_removeObjectForWriting: (id)object
		   fileDescriptor: (int)fd
{
	/* TODO: Adjust _maxFD */

	if (fd < 0)
		@throw [OFOutOfRangeException exception];

#ifndef _WIN32
	if (fd >= FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	FD_CLR(fd, &_writeFDs);
}

- (void)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	void *pool = objc_autoreleasePoolPush();
	id const *objects;
	fd_set readFDs;
	fd_set writeFDs;
	struct timeval timeout;
	int events;
	size_t i, count;

	[self OF_processQueue];
	[self OF_processReadBuffers];

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

	events = select(_maxFD + 1, &readFDs, &writeFDs, NULL,
	    (timeInterval != -1 ? &timeout : NULL));

	if (events < 0)
		@throw [OFObserveFailedException exceptionWithObserver: self
								 errNo: errno];

	if (FD_ISSET(_cancelFD[0], &readFDs)) {
		char buffer;

#ifdef OF_HAVE_PIPE
		OF_ENSURE(read(_cancelFD[0], &buffer, 1) == 1);
#else
		OF_ENSURE(recvfrom(_cancelFD[0], &buffer, 1, 0, NULL,
		    NULL) == 1);
#endif
	}

	objects = [_readObjects objects];
	count = [_readObjects count];

	for (i = 0; i < count; i++) {
		int fd;

		pool = objc_autoreleasePoolPush();
		fd = [objects[i] fileDescriptorForReading];

		if (FD_ISSET(fd, &readFDs) && [_delegate respondsToSelector:
		    @selector(objectIsReadyForReading:)])
			[_delegate objectIsReadyForReading: objects[i]];

		objc_autoreleasePoolPop(pool);
	}

	objects = [_writeObjects objects];
	count = [_writeObjects count];

	for (i = 0; i < count; i++) {
		int fd;

		pool = objc_autoreleasePoolPush();
		fd = [objects[i] fileDescriptorForWriting];

		if (FD_ISSET(fd, &writeFDs) && [_delegate respondsToSelector:
		    @selector(objectIsReadyForWriting:)])
			[_delegate objectIsReadyForWriting: objects[i]];

		objc_autoreleasePoolPop(pool);
	}
}
@end
