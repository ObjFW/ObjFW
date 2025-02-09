/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

#import "OFKernelEventObserver.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#ifdef HAVE_EPOLL
# import "OFEpollKernelEventObserver.h"
#endif
#ifdef HAVE_KQUEUE
# import "OFKqueueKernelEventObserver.h"
#endif
#ifdef HAVE_POLL
# import "OFPollKernelEventObserver.h"
#endif
#ifdef HAVE_SELECT
# import "OFSelectKernelEventObserver.h"
#endif
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFStream.h"
#import "OFStream+Private.h"
#ifndef OF_HAVE_PIPE
# import "OFStreamSocket.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# undef Class
#endif

@implementation OFKernelEventObserver
@synthesize delegate = _delegate;
#ifdef OF_AMIGAOS
@synthesize execSignalMask = _execSignalMask;
#endif

+ (instancetype)observer
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)alloc
{
	if (self == [OFKernelEventObserver class])
#if defined(HAVE_KQUEUE)
		return [OFKqueueKernelEventObserver alloc];
#elif defined(HAVE_EPOLL)
		return [OFEpollKernelEventObserver alloc];
#elif defined(HAVE_POLL)
		return [OFPollKernelEventObserver alloc];
#elif defined(HAVE_SELECT)
		return [OFSelectKernelEventObserver alloc];
#else
# error No kqueue / epoll / poll / select found!
#endif

	return [super alloc];
}

+ (bool)handlesForeignEvents
{
	return false;
}

- (instancetype)init
{
	return [self initWithRunLoopMode: nil];
}

- (instancetype)initWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	self = [super init];

	@try {
#if !defined(OF_HAVE_PIPE) && !defined(OF_WII) && !defined(OF_AMIGAOS) && \
    !defined(OF_NINTENDO_3DS)
		socklen_t cancelAddrLen;
#endif

		if (!_OFSocketInit())
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_readObjects = [[OFMutableArray alloc] init];
		_writeObjects = [[OFMutableArray alloc] init];

#if defined(OF_HAVE_PIPE) && !defined(OF_AMIGAOS)
		if (pipe(_cancelFD))
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
#elif !defined(OF_AMIGAOS)
		_cancelFD[0] = _cancelFD[1] = socket(AF_INET, SOCK_DGRAM, 0);

		if (_cancelFD[0] == OFInvalidSocketHandle)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_cancelAddr.sin_family = AF_INET;
		_cancelAddr.sin_port = 0;
		_cancelAddr.sin_addr.s_addr = inet_addr((void *)"127.0.0.1");
# ifdef OF_WII
		_cancelAddr.sin_len = 8;
# endif

# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
		if (bind(_cancelFD[0], (struct sockaddr *)&_cancelAddr,
		    sizeof(_cancelAddr)) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		cancelAddrLen = sizeof(_cancelAddr);
		if (_OFGetSockName(_cancelFD[0],
		    (struct sockaddr *)&_cancelAddr, &cancelAddrLen) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
# else
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = (uint16_t)rand();

			_cancelAddr.sin_port = OFToBigEndian16(rnd);
			ret = bind(_cancelFD[0],
			    (struct sockaddr *)&_cancelAddr,
			    sizeof(_cancelAddr));

			if (ret == 0)
				break;

			if (_OFSocketErrNo() != EADDRINUSE)
				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];
		}
# endif
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
#if defined(OF_HAVE_PIPE) && !defined(OF_AMIGAOS)
	close(_cancelFD[0]);
	if (_cancelFD[1] != _cancelFD[0])
		close(_cancelFD[1]);
#elif !defined(OF_AMIGAOS)
	closesocket(_cancelFD[0]);
	if (_cancelFD[1] != _cancelFD[0])
		closesocket(_cancelFD[1]);
#endif

	[_readObjects release];
	[_writeObjects release];

	[super dealloc];
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[_readObjects addObject: object];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	[_writeObjects addObject: object];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[_readObjects removeObjectIdenticalTo: object];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	[_writeObjects removeObjectIdenticalTo: object];
}

- (bool)processReadBuffers
{
	void *pool = objc_autoreleasePoolPush();
	bool foundInReadBuffer = false;

	for (OFStream *stream in [[_readObjects copy] autorelease]) {
		void *pool2;

		if (![stream isKindOfClass: [OFStream class]])
			continue;

		pool2 = objc_autoreleasePoolPush();

		if (stream.hasDataInReadBuffer &&
		    (!stream.of_waitingForDelimiter ||
		    [stream lowlevelHasDataInReadBuffer])) {
			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading: stream];

			foundInReadBuffer = true;
		}

		objc_autoreleasePoolPop(pool2);
	}

	objc_autoreleasePoolPop(pool);

	/*
	 * As long as we have data in the read buffer for any stream, we don't
	 * want to block.
	 */
	return foundInReadBuffer;
}

- (void)observe
{
	[self observeForTimeInterval: -1];
}

- (void)observeForTimeInterval: (OFTimeInterval)timeInterval
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)observeUntilDate: (OFDate *)date
{
	[self observeForTimeInterval: date.timeIntervalSinceNow];
}

- (void)cancel
{
#if defined(OF_AMIGAOS)
	Forbid();

	if (_waitingTask != NULL) {
		Signal(_waitingTask, (1ul << _cancelSignal));
		_waitingTask = NULL;
	}

	Permit();
#elif defined(OF_HAVE_PIPE)
	do {
		if (write(_cancelFD[1], "", 1) == 1)
			break;

		OFEnsure(errno == EINTR);
	} while (true);
#elif defined(OF_WII)
	do {
		if (sendto(_cancelFD[1], "", 1, 0,
		    (struct sockaddr *)&_cancelAddr, 8) == 1)
			break;

		OFEnsure(_OFSocketErrNo() == EINTR);
	} while (true);
#else
	do {
		if (sendto(_cancelFD[1], (void *)"", 1, 0,
		    (struct sockaddr *)&_cancelAddr, sizeof(_cancelAddr)) == 1)
			break;

		OFEnsure(_OFSocketErrNo() == EINTR);
	} while (true);
#endif
}
@end
