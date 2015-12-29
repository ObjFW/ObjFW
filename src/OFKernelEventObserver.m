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

#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#import "OFArray.h"
#import "OFStream.h"
#import "OFStream+Private.h"
#ifndef OF_HAVE_PIPE
# import "OFStreamSocket.h"
#endif
#import "OFDate.h"

#ifdef HAVE_KQUEUE
# import "OFKernelEventObserver_kqueue.h"
#endif
#ifdef HAVE_EPOLL
# import "OFKernelEventObserver_epoll.h"
#endif
#if defined(HAVE_POLL_H) || defined(__wii__)
# import "OFKernelEventObserver_poll.h"
#endif
#if defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
# import "OFKernelEventObserver_select.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

#import "socket.h"
#import "socket_helpers.h"

#ifdef __wii__
/* FIXME: Add a port registry for Wii */
static uint16_t freePort = 65535;
#endif

@implementation OFKernelEventObserver
+ (void)initialize
{
	if (self != [OFKernelEventObserver class])
		return;

	if (!of_socket_init())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)observer
{
	return [[[self alloc] init] autorelease];
}

+ alloc
{
	if (self == [OFKernelEventObserver class])
#if defined(HAVE_KQUEUE)
		return [OFKernelEventObserver_kqueue alloc];
#elif defined(HAVE_EPOLL)
		return [OFKernelEventObserver_epoll alloc];
#elif defined(HAVE_POLL_H) || defined(__wii__)
		return [OFKernelEventObserver_poll alloc];
#elif defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
		return [OFKernelEventObserver_select alloc];
#else
# error No kqueue / epoll / poll / select found!
#endif

	return [super alloc];
}

- init
{
	self = [super init];

	@try {
#if !defined(OF_HAVE_PIPE) && !defined(__wii__)
		socklen_t cancelAddrLen;
#endif

		_readObjects = [[OFMutableArray alloc] init];
		_writeObjects = [[OFMutableArray alloc] init];

#ifdef OF_HAVE_PIPE
		if (pipe(_cancelFD))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
#else
		_cancelFD[0] = _cancelFD[1] = socket(AF_INET, SOCK_DGRAM, 0);

		if (_cancelFD[0] == INVALID_SOCKET)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		_cancelAddr.sin_family = AF_INET;
		_cancelAddr.sin_port = 0;
		_cancelAddr.sin_addr.s_addr = inet_addr("127.0.0.1");

# ifdef __wii__
		_cancelAddr.sin_len = 8;
		/* The Wii does not accept port 0 as "choose any free port" */
		_cancelAddr.sin_port = freePort--;
# endif

		if (bind(_cancelFD[0], (struct sockaddr*)&_cancelAddr,
		    sizeof(_cancelAddr)))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

# ifndef __wii__
		cancelAddrLen = sizeof(_cancelAddr);
		if (of_getsockname(_cancelFD[0], (struct sockaddr*)&_cancelAddr,
		    &cancelAddrLen) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
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
	close(_cancelFD[0]);
	if (_cancelFD[1] != _cancelFD[0])
		close(_cancelFD[1]);

	[_readObjects release];
	[_writeObjects release];

	[super dealloc];
}

- (id <OFKernelEventObserverDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate: (id <OFKernelEventObserverDelegate>)delegate
{
	_delegate = delegate;
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)observe
{
	[self observeForTimeInterval: -1];
}

- (void)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)observeUntilDate: (OFDate*)date
{
	[self observeForTimeInterval: [date timeIntervalSinceNow]];
}

- (void)cancel
{
#ifdef OF_HAVE_PIPE
	OF_ENSURE(write(_cancelFD[1], "", 1) > 0);
#else
# ifndef __wii__
	OF_ENSURE(sendto(_cancelFD[1], "", 1, 0,
	    (struct sockaddr*)&_cancelAddr, sizeof(_cancelAddr)) > 0);
# else
	OF_ENSURE(sendto(_cancelFD[1], "", 1, 0,
	    (struct sockaddr*)&_cancelAddr, 8) > 0);
# endif
#endif
}

- (void)OF_processReadBuffers
{
	id const *objects = [_readObjects objects];
	size_t i, count = [_readObjects count];

	for (i = 0; i < count; i++) {
		void *pool = objc_autoreleasePoolPush();

		if ([objects[i] isKindOfClass: [OFStream class]] &&
		    [objects[i] hasDataInReadBuffer] &&
		    ![objects[i] OF_isWaitingForDelimiter] &&
		    [_delegate respondsToSelector:
		    @selector(objectIsReadyForReading:)])
			[_delegate objectIsReadyForReading: objects[i]];

		objc_autoreleasePoolPop(pool);
	}
}
@end
