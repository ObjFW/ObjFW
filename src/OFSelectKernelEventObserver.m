/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include "platform.h"

#if defined(OF_MACOS) || defined(OF_IOS)
# define _DARWIN_UNLIMITED_SELECT
#endif

#ifdef OF_WINDOWS
/* Win32 has a ridiculous default of 64, even though it supports much more. */
# define FD_SETSIZE 1024
#endif

#include <errno.h>
#include <math.h>
#include <string.h>

#include <sys/time.h>

#import "OFSelectKernelEventObserver.h"
#import "OFSet.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFInitializationFailedException.h"
#import "OFObserveKernelEventsFailedException.h"
#import "OFOutOfRangeException.h"

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# undef Class
#endif

#ifdef OF_HPUX
/* FD_SET causes warnings on HP-UX/IA64. */
# pragma GCC diagnostic ignored "-Wstrict-aliasing"
#endif

static void
growFDSets(fd_set **readFDs, fd_set **writeFDs, fd_set **exceptFDs,
    int maxFD, int newFD)
{
#if defined(OF_MACOS) || defined(OF_IOS)
	size_t oldSize = OFRoundUpToPowerOf2(sizeof(fd_mask),
	    (maxFD + 1) / NFDBITS + ((maxFD + 1) % NFDBITS > 0 ? 1 : 0));
	size_t newSize = OFRoundUpToPowerOf2(sizeof(fd_mask),
	    (newFD + 1) / NFDBITS + ((newFD + 1) % NFDBITS > 0 ? 1 : 0));

	if (newSize == oldSize)
		return;

	*readFDs = OFResizeMemory(*readFDs, newSize, sizeof(fd_mask));
	*writeFDs = OFResizeMemory(*writeFDs, newSize, sizeof(fd_mask));
	*exceptFDs = OFResizeMemory(*exceptFDs, newSize, sizeof(fd_mask));

	for (int i = maxFD + 1; i <= newFD; i++) {
		FD_CLR(i, *readFDs);
		FD_CLR(i, *writeFDs);
		FD_CLR(i, *exceptFDs);
	}
#endif
}

static fd_set *
copyFDSet(fd_set *set, int maxFD)
{
#if defined(OF_MACOS) || defined(OF_IOS)
	size_t size = OFRoundUpToPowerOf2(sizeof(fd_mask),
	    (maxFD + 1) / NFDBITS + ((maxFD + 1) % NFDBITS > 0 ? 1 : 0));

	fd_set *copy = OFAllocMemory(size, sizeof(fd_mask));
	OFCopyMemory(copy, set, size * sizeof(fd_mask));
#else
	fd_set *copy = OFAllocMemory(1, sizeof(fd_set));
# ifdef FD_COPY
	FD_COPY(set, copy);
# else
	*copy = *set;
# endif
#endif

	return copy;
}

@implementation OFSelectKernelEventObserver
- (instancetype)initWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	self = [super initWithRunLoopMode: runLoopMode];

	@try {
#if defined(OF_MACOS) || defined(OF_IOS)
		size_t size = OFRoundUpToPowerOf2(sizeof(fd_mask),
		    (_cancelFD[0] + 1) / NFDBITS +
		    ((_cancelFD[0] + 1) % NFDBITS > 0 ? 1 : 0));

		_readFDs = OFAllocZeroedMemory(size, sizeof(fd_mask));
		_writeFDs = OFAllocZeroedMemory(size, sizeof(fd_mask));
		_exceptFDs = OFAllocZeroedMemory(size, sizeof(fd_mask));
#else
		_readFDs = OFAllocMemory(1, sizeof(*_readFDs));
		_writeFDs = OFAllocMemory(1, sizeof(*_writeFDs));
		_exceptFDs = OFAllocMemory(1, sizeof(*_exceptFDs));

		FD_ZERO(_readFDs);
		FD_ZERO(_writeFDs);
		FD_ZERO(_exceptFDs);
#endif

#ifdef OF_AMIGAOS
		_maxFD = -1;
#else
# ifndef OF_WINDOWS
		if (_cancelFD[0] >= (int)FD_SETSIZE)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
# endif

		FD_SET(_cancelFD[0], _readFDs);

		if (_cancelFD[0] > INT_MAX)
			@throw [OFOutOfRangeException exception];

		_maxFD = (int)_cancelFD[0];
#endif
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_readFDs);
	OFFreeMemory(_writeFDs);
	OFFreeMemory(_exceptFDs);

	[super dealloc];
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	int fd = object.fileDescriptorForReading;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];

	if (fd > INT_MAX - 1)
		@throw [OFOutOfRangeException exception];

#ifndef OF_WINDOWS
	if (fd >= (int)FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	if (fd > _maxFD) {
		growFDSets(&_readFDs, &_writeFDs, &_exceptFDs, _maxFD, fd);
		_maxFD = fd;
	}

	FD_SET((OFSocketHandle)fd, _readFDs);

	[super addObjectForReading: object];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	int fd = object.fileDescriptorForWriting;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];

	if (fd > INT_MAX - 1)
		@throw [OFOutOfRangeException exception];

#ifndef OF_WINDOWS
	if (fd >= (int)FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	if (fd > _maxFD) {
		growFDSets(&_readFDs, &_writeFDs, &_exceptFDs, _maxFD, fd);
		_maxFD = fd;
	}

	FD_SET((OFSocketHandle)fd, _writeFDs);

	[super addObjectForWriting: object];
}

- (void)addObjectForConnecting: (id <OFReadyForConnectingObserving>)object
{
	int fd = object.fileDescriptorForConnecting;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];

	if (fd > INT_MAX - 1)
		@throw [OFOutOfRangeException exception];

#ifndef OF_WINDOWS
	if (fd >= (int)FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	if (fd > _maxFD) {
		growFDSets(&_readFDs, &_writeFDs, &_exceptFDs, _maxFD, fd);
		_maxFD = fd;
	}

	FD_SET((OFSocketHandle)fd, _writeFDs);
#ifdef OF_WINDOWS
	FD_SET((OFSocketHandle)fd, _exceptFDs);
#endif

	[super addObjectForConnecting: object];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	/* TODO: Adjust _maxFD */

	int fd = object.fileDescriptorForReading;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];

#ifndef OF_WINDOWS
	if (fd >= (int)FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	FD_CLR((OFSocketHandle)fd, _readFDs);

	[super removeObjectForReading: object];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	/* TODO: Adjust _maxFD */

	int fd = object.fileDescriptorForWriting;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];


#ifndef OF_WINDOWS
	if (fd >= (int)FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	if (![_connectObjects containsObject: (id)object])
		FD_CLR((OFSocketHandle)fd, _writeFDs);

	[super removeObjectForWriting: object];
}

- (void)removeObjectForConnecting: (id <OFReadyForConnectingObserving>)object
{
	/* TODO: Adjust _maxFD */

	int fd = object.fileDescriptorForConnecting;

	if (fd < 0)
		@throw [OFObserveKernelEventsFailedException
		    exceptionWithObserver: self
				    errNo: EBADF];


#ifndef OF_WINDOWS
	if (fd >= (int)FD_SETSIZE)
		@throw [OFOutOfRangeException exception];
#endif

	if (![_writeObjects containsObject: (id)object])
		FD_CLR((OFSocketHandle)fd, _writeFDs);
#ifdef OF_WINDOWS
	FD_CLR((OFSocketHandle)fd, _exceptFDs);
#endif

	[super removeObjectForConnecting: object];
}

- (void)observeForTimeInterval: (OFTimeInterval)timeInterval
{
	if ([self processReadBuffers])
		return;

	if (timeInterval < 0.0)
		timeInterval = 0.0;

	fd_set *readFDs = NULL, *writeFDs = NULL, *exceptFDs = NULL;
	@try {
		readFDs = copyFDSet(_readFDs, _maxFD);
		writeFDs = copyFDSet(_writeFDs, _maxFD);
		exceptFDs = copyFDSet(_exceptFDs, _maxFD);

		/*
		 * We cast to int before assigning to tv_usec in order to avoid
		 * a warning with Apple GCC on PowerPC. POSIX defines this as
		 * suseconds_t, however, this is not available on Win32. As an
		 * int should always satisfy the required range, we just cast
		 * to int.
		 */
		struct timeval timeout = {
#ifndef OF_WINDOWS
			.tv_sec = (time_t)floor(timeInterval),
#else
			.tv_sec = (long)floor(timeInterval),
#endif
			.tv_usec = (int)
			    ((timeInterval - floor(timeInterval)) * 1000000.0)
		};

#ifdef OF_AMIGAOS
		BYTE cancelSignal;
		if ((cancelSignal = AllocSignal(-1)) == (BYTE)-1)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: EAGAIN];

		ULONG execSignalMask = _execSignalMask | (1ul << cancelSignal);

		Forbid();

		_waitingTask = FindTask(NULL);
		_cancelSignal = cancelSignal;

		int events = WaitSelect(_maxFD + 1, readFDs, writeFDs,
		    exceptFDs, (void *)(timeInterval != 64060588800.0 ?
		    &timeout : NULL), &execSignalMask);

		execSignalMask &= ~(1ul << cancelSignal);

		_waitingTask = NULL;
		FreeSignal(_cancelSignal);

		Permit();

		if (events < 0) {
			int errNo = _OFSocketErrNo();

			if (errNo != EINTR)
				@throw [OFObserveKernelEventsFailedException
				    exceptionWithObserver: self
						    errNo: errNo];
		} else if (execSignalMask != 0 && [_delegate respondsToSelector:
		    @selector(execSignalWasReceived:)])
			[_delegate execSignalWasReceived: execSignalMask];
#else
		int events;
		while ((events = select(_maxFD + 1, readFDs, writeFDs,
		    exceptFDs, (timeInterval != 64060588800.0 ?
		    &timeout : NULL))) < 0) {
			int errNo = _OFSocketErrNo();

			if (errNo != EINTR)
				@throw [OFObserveKernelEventsFailedException
				    exceptionWithObserver: self
						    errNo: errNo];
		}

		if (FD_ISSET(_cancelFD[0], readFDs)) {
			char buffer;
# ifdef OF_HAVE_PIPE
			OFEnsure(read(_cancelFD[0], &buffer, 1) == 1);
# else
			OFEnsure(recvfrom(_cancelFD[0], (void *)&buffer, 1, 0,
			    NULL, NULL) == 1);
# endif
		}
#endif

		void *pool = objc_autoreleasePoolPush();

		for (id <OFReadyForReadingObserving> object in
		    objc_autorelease([_readObjects copy])) {
			void *pool2 = objc_autoreleasePoolPush();
			int fd = object.fileDescriptorForReading;

			if (FD_ISSET((OFSocketHandle)fd, readFDs) &&
			    [_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading: object];

			objc_autoreleasePoolPop(pool2);
		}

		for (id <OFReadyForWritingObserving> object in
		    objc_autorelease([_writeObjects copy])) {
			void *pool2 = objc_autoreleasePoolPush();
			int fd = object.fileDescriptorForWriting;

			if (FD_ISSET((OFSocketHandle)fd, writeFDs) &&
			    [_delegate respondsToSelector:
			    @selector(objectIsReadyForWriting:)])
				[_delegate objectIsReadyForWriting: object];

			objc_autoreleasePoolPop(pool2);
		}

		for (id <OFReadyForConnectingObserving> object in
		    objc_autorelease([_connectObjects copy])) {
			void *pool2 = objc_autoreleasePoolPush();
			int fd = object.fileDescriptorForConnecting;

#ifdef OF_WINDOWS
			if ((FD_ISSET((OFSocketHandle)fd, writeFDs) ||
			    FD_ISSET((OFSocketHandle)fd, exceptFDs)) &&
			    [_delegate respondsToSelector:
			    @selector(objectIsReadyForConnecting:)])
				[_delegate objectIsReadyForConnecting: object];
#else
			if (FD_ISSET((OFSocketHandle)fd, writeFDs) &&
			    [_delegate respondsToSelector:
			    @selector(objectIsReadyForConnecting:)])
				[_delegate objectIsReadyForConnecting: object];
#endif

			objc_autoreleasePoolPop(pool2);
		}

		objc_autoreleasePoolPop(pool);
	} @finally {
		OFFreeMemory(readFDs);
		OFFreeMemory(writeFDs);
		OFFreeMemory(exceptFDs);
	}
}
@end
