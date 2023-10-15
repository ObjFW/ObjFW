/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

+ (void)initialize
{
	if (self != [OFKernelEventObserver class])
		return;

	if (!OFSocketInit())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

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

- (instancetype)init
{
	self = [super init];

	@try {
#if !defined(OF_HAVE_PIPE) && !defined(OF_WII) && !defined(OF_AMIGAOS) && \
    !defined(OF_NINTENDO_3DS)
		socklen_t cancelAddrLen;
#endif

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
		if (OFGetSockName(_cancelFD[0],
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

			if (OFSocketErrNo() != EADDRINUSE)
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

- (bool)of_processReadBuffers
{
	void *pool = objc_autoreleasePoolPush();
	bool foundInReadBuffer = false;

	for (id object in [[_readObjects copy] autorelease]) {
		void *pool2;

		if (![object isKindOfClass: [OFStream class]])
			continue;

		pool2 = objc_autoreleasePoolPush();

		if ([object hasDataInReadBuffer] &&
		    (![object of_isWaitingForDelimiter] ||
		    [object lowlevelHasDataInReadBuffer])) {
			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading: object];

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
	OFEnsure(write(_cancelFD[1], "", 1) > 0);
#elif defined(OF_WII)
	OFEnsure(sendto(_cancelFD[1], "", 1, 0,
	    (struct sockaddr *)&_cancelAddr, 8) > 0);
#else
	OFEnsure(sendto(_cancelFD[1], (void *)"", 1, 0,
	    (struct sockaddr *)&_cancelAddr, sizeof(_cancelAddr)) > 0);
#endif
}
@end
