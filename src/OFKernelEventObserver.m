/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFKernelEventObserver+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif
#import "OFStream.h"
#import "OFStream+Private.h"
#ifndef OF_HAVE_PIPE
# import "OFStreamSocket.h"
#endif

#ifdef HAVE_KQUEUE
# import "OFKqueueKernelEventObserver.h"
#endif
#ifdef HAVE_EPOLL
# import "OFEpollKernelEventObserver.h"
#endif
#ifdef HAVE_POLL
# import "OFPollKernelEventObserver.h"
#endif
#ifdef HAVE_SELECT
# import "OFSelectKernelEventObserver.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

#import "socket.h"
#import "socket_helpers.h"

enum {
	QUEUE_ADD = 0,
	QUEUE_REMOVE = 1,
	QUEUE_READ = 0,
	QUEUE_WRITE = 2
};
#define QUEUE_ACTION (QUEUE_ADD | QUEUE_REMOVE)

@implementation OFKernelEventObserver
@synthesize delegate = _delegate;

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
#if !defined(OF_HAVE_PIPE) && !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
		socklen_t cancelAddrLen;
#endif

		_readObjects = [[OFMutableArray alloc] init];
		_writeObjects = [[OFMutableArray alloc] init];

#ifdef OF_HAVE_PIPE
		if (pipe(_cancelFD))
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
#else
		_cancelFD[0] = _cancelFD[1] = socket(AF_INET, SOCK_DGRAM, 0);

		if (_cancelFD[0] == INVALID_SOCKET)
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
		if (of_getsockname(_cancelFD[0],
		    (struct sockaddr *)&_cancelAddr, &cancelAddrLen) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
# else
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = (uint16_t)rand();

			_cancelAddr.sin_port = OF_BSWAP16_IF_LE(rnd);
			ret = bind(_cancelFD[0],
			    (struct sockaddr *)&_cancelAddr,
			    sizeof(_cancelAddr));

			if (ret == 0)
				break;

			if (of_socket_errno() != EADDRINUSE)
				@throw [OFInitializationFailedException
				    exceptionWithClass: self.class];
		}
# endif
#endif

#ifdef OF_HAVE_THREADS
		_mutex = [[OFMutex alloc] init];
#endif

		_queueActions = [[OFMutableData alloc]
		    initWithItemSize: sizeof(int)];
		_queueObjects = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
#ifdef OF_HAVE_PIPE
	close(_cancelFD[0]);
	if (_cancelFD[1] != _cancelFD[0])
		close(_cancelFD[1]);
#else
	closesocket(_cancelFD[0]);
	if (_cancelFD[1] != _cancelFD[0])
		closesocket(_cancelFD[1]);
#endif

	[_readObjects release];
	[_writeObjects release];

#ifdef OF_HAVE_THREADS
	[_mutex release];
#endif

	[_queueActions release];
	[_queueObjects release];

	[super dealloc];
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int action = QUEUE_ADD | QUEUE_READ;

		[_queueActions addItem: &action];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int action = QUEUE_ADD | QUEUE_WRITE;

		[_queueActions addItem: &action];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int action = QUEUE_REMOVE | QUEUE_READ;

		[_queueActions addItem: &action];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int action = QUEUE_REMOVE | QUEUE_WRITE;

		[_queueActions addItem: &action];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)of_addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)of_addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)of_removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)of_removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)of_processQueue
{
	void *pool = objc_autoreleasePoolPush();

#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		const int *queueActions = _queueActions.items;
		id const *queueObjects = _queueObjects.objects;
		size_t count = _queueActions.count;

		OF_ENSURE(_queueObjects.count == count);

		for (size_t i = 0; i < count; i++) {
			int action = queueActions[i];
			id object = queueObjects[i];

			switch (action) {
			case QUEUE_ADD | QUEUE_READ:
				[_readObjects addObject: object];

				@try {
					[self of_addObjectForReading: object];
				} @catch (id e) {
					[_readObjects
					    removeObjectIdenticalTo: object];

					@throw e;
				}

				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[_writeObjects addObject: object];

				@try {
					[self of_addObjectForWriting: object];
				} @catch (id e) {
					[_writeObjects
					    removeObjectIdenticalTo: object];

					@throw e;
				}

				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[self of_removeObjectForReading: object];

				[_readObjects removeObjectIdenticalTo: object];

				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[self of_removeObjectForWriting: object];

				[_writeObjects removeObjectIdenticalTo: object];

				break;
			default:
				OF_ENSURE(0);
			}
		}

		[_queueActions removeAllItems];
		[_queueObjects removeAllObjects];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	objc_autoreleasePoolPop(pool);
}

- (bool)of_processReadBuffers
{
	bool foundInReadBuffer = false;

	for (id object in _readObjects) {
		void *pool = objc_autoreleasePoolPush();

		if ([object isKindOfClass: [OFStream class]] &&
		    [object hasDataInReadBuffer] &&
		    ![object of_isWaitingForDelimiter]) {
			if ([_delegate respondsToSelector:
			    @selector(objectIsReadyForReading:)])
				[_delegate objectIsReadyForReading: object];

			foundInReadBuffer = true;
		}

		objc_autoreleasePoolPop(pool);
	}

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

- (void)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)observeUntilDate: (OFDate *)date
{
	[self observeForTimeInterval: date.timeIntervalSinceNow];
}

- (void)cancel
{
#ifdef OF_HAVE_PIPE
	OF_ENSURE(write(_cancelFD[1], "", 1) > 0);
#elif defined(OF_WII)
	OF_ENSURE(sendto(_cancelFD[1], "", 1, 0,
	    (struct sockaddr *)&_cancelAddr, 8) > 0);
#else
	OF_ENSURE(sendto(_cancelFD[1], (void *)"", 1, 0,
	    (struct sockaddr *)&_cancelAddr, sizeof(_cancelAddr)) > 0);
#endif
}
@end
