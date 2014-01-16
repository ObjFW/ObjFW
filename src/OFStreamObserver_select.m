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

#include "config.h"

#define __NO_EXT_QNX

#include <string.h>
#include <math.h>
#include <unistd.h>

#include <sys/time.h>

#import "OFStreamObserver.h"
#import "OFStreamObserver+Private.h"
#import "OFStreamObserver_select.h"
#import "OFStream.h"
#import "OFArray.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFStreamObserver_select
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
	FD_SET(fd, &_exceptFDs);
}

- (void)OF_addFileDescriptorForWriting: (int)fd
{
	FD_SET(fd, &_writeFDs);
	FD_SET(fd, &_exceptFDs);
}

- (void)OF_removeFileDescriptorForReading: (int)fd
{
	FD_CLR(fd, &_readFDs);

	if (!FD_ISSET(fd, &_writeFDs))
		FD_CLR(fd, &_exceptFDs);
}

- (void)OF_removeFileDescriptorForWriting: (int)fd
{
	FD_CLR(fd, &_writeFDs);

	if (!FD_ISSET(fd, &_readFDs))
		FD_CLR(fd, &_exceptFDs);
}

- (bool)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	void *pool = objc_autoreleasePoolPush();
	OFStream **objects;
	fd_set readFDs;
	fd_set writeFDs;
	fd_set exceptFDs;
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
	FD_COPY(&_exceptFDs, &exceptFDs);
#else
	readFDs = _readFDs;
	writeFDs = _writeFDs;
	exceptFDs = _exceptFDs;
#endif

	/*
	 * We cast to int before assigning to tv_usec in order to avoid a
	 * warning with Apple GCC on PPC. POSIX defines this as suseconds_t,
	 * however, this is not available on Win32. As an int should always
	 * satisfy the required range, we just cast to int.
	 */
	timeout.tv_sec = (time_t)timeInterval;
	timeout.tv_usec = (int)lrint((timeInterval - timeout.tv_sec) * 1000);

	if (select((int)_maxFD + 1, &readFDs, &writeFDs, &exceptFDs,
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

	objects = [_readStreams objects];
	count = [_readStreams count];

	for (i = 0; i < count; i++) {
		int fd = [objects[i] fileDescriptorForReading];

		pool = objc_autoreleasePoolPush();

		if (FD_ISSET(fd, &readFDs)) {
			if ([_delegate respondsToSelector:
			    @selector(streamIsReadyForReading:)])
				[_delegate streamIsReadyForReading: objects[i]];

			realEvents++;
		}

		if (FD_ISSET(fd, &exceptFDs)) {
			if ([_delegate respondsToSelector:
			    @selector(streamDidReceiveException:)])
				[_delegate streamDidReceiveException:
				    objects[i]];

			/*
			 * Prevent calling it twice in case the FD is in both
			 * sets.
			 */
			FD_CLR(fd, &exceptFDs);

			realEvents++;
		}

		objc_autoreleasePoolPop(pool);
	}

	objects = [_writeStreams objects];
	count = [_writeStreams count];

	for (i = 0; i < count; i++) {
		int fd = [objects[i] fileDescriptorForWriting];

		pool = objc_autoreleasePoolPush();

		if (FD_ISSET(fd, &writeFDs)) {
			if ([_delegate respondsToSelector:
			    @selector(streamIsReadyForWriting:)])
				[_delegate streamIsReadyForWriting: objects[i]];

			realEvents++;
		}

		if (FD_ISSET(fd, &exceptFDs)) {
			if ([_delegate respondsToSelector:
			    @selector(streamDidReceiveException:)])
				[_delegate streamDidReceiveException:
				    objects[i]];

			realEvents++;
		}

		objc_autoreleasePoolPop(pool);
	}

	if (realEvents == 0)
		return false;

	return true;
}
@end
