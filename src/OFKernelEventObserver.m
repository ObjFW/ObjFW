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

#include <assert.h>

#import "OFKernelEventObserver.h"
#import "OFKernelEventObserver+Private.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFStream.h"
#import "OFStream+Private.h"
#import "OFDataArray.h"
#ifndef OF_HAVE_PIPE
# import "OFStreamSocket.h"
#endif
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif
#import "OFDate.h"

#ifdef HAVE_KQUEUE
# import "OFKernelEventObserver_kqueue.h"
#endif
#ifdef HAVE_EPOLL
# import "OFKernelEventObserver_epoll.h"
#endif
#if defined(HAVE_POLL_H) || defined(OF_WII)
# import "OFKernelEventObserver_poll.h"
#endif
#if defined(HAVE_SYS_SELECT_H) || defined(OF_WINDOWS)
# import "OFKernelEventObserver_select.h"
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

+ alloc
{
	if (self == [OFKernelEventObserver class])
#if defined(HAVE_KQUEUE)
		return [OFKernelEventObserver_kqueue alloc];
#elif defined(HAVE_EPOLL)
		return [OFKernelEventObserver_epoll alloc];
#elif defined(HAVE_POLL_H) || defined(OF_WII)
		return [OFKernelEventObserver_poll alloc];
#elif defined(HAVE_SYS_SELECT_H) || defined(OF_WINDOWS)
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
#if !defined(OF_HAVE_PIPE) && !defined(OF_WII)
		socklen_t cancelAddrLen;
#endif

		_readObjects = [[OFMutableArray alloc] init];
		_writeObjects = [[OFMutableArray alloc] init];
		_queue = [[OFMutableArray alloc] init];
		_queueActions = [[OFDataArray alloc]
		    initWithItemSize: sizeof(int)];

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

# ifdef OF_WII
		_cancelAddr.sin_len = 8;
		/* The Wii does not accept port 0 as "choose any free port" */
		_cancelAddr.sin_port = of_socket_port_find(SOCK_DGRAM);
# endif

		if (bind(_cancelFD[0], (struct sockaddr*)&_cancelAddr,
		    sizeof(_cancelAddr)))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

# ifndef OF_WII
		cancelAddrLen = sizeof(_cancelAddr);
		if (of_getsockname(_cancelFD[0], (struct sockaddr*)&_cancelAddr,
		    &cancelAddrLen) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
# endif
#endif

#ifdef OF_HAVE_THREADS
		_mutex = [[OFMutex alloc] init];
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

#ifdef OF_WII
	of_socket_port_free(_cancelAddr.sin_port, SOCK_DGRAM);
#endif

	[_readObjects release];
	[_writeObjects release];
	[_queue release];
	[_queueActions release];
#ifdef OF_HAVE_THREADS
	[_mutex release];
#endif

	[super dealloc];
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_ADD | QUEUE_READ;

		[_queue addObject: object];
		[_queueActions addItem: &qi];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_ADD | QUEUE_WRITE;

		[_queue addObject: object];
		[_queueActions addItem: &qi];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_REMOVE | QUEUE_READ;

		[_queue addObject: object];
		[_queueActions addItem: &qi];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_REMOVE | QUEUE_WRITE;

		[_queue addObject: object];
		[_queueActions addItem: &qi];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)OF_addObjectForReading: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_addObjectForWriting: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_removeObjectForReading: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_removeObjectForWriting: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_processQueueAndStoreRemovedIn: (OFMutableArray*)removed
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		id const *queueObjects = [_queue objects];
		int *queueActionItems = [_queueActions items];
		size_t i, count = [_queue count];

		for (i = 0; i < count; i++) {
			id object = queueObjects[i];
			int action = queueActionItems[i];

			switch (action) {
			case QUEUE_ADD | QUEUE_READ:
				[_readObjects addObject: object];

				[self OF_addObjectForReading: object];

				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[_writeObjects addObject: object];

				[self OF_addObjectForWriting: object];

				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[self OF_removeObjectForReading: object];

				[removed addObject: object];
				[_readObjects removeObjectIdenticalTo: object];

				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[self OF_removeObjectForWriting: object];

				[removed addObject: object];
				[_writeObjects removeObjectIdenticalTo: object];

				break;
			default:
				assert(0);
			}
		}

		[_queue removeAllObjects];
		[_queueActions removeAllItems];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}
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
# ifndef OF_WII
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
