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

#include <unistd.h>

#include <assert.h>

#import "OFStreamObserver.h"
#import "OFStreamObserver+Private.h"
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
# import "OFStreamObserver_kqueue.h"
#endif
#if defined(HAVE_POLL_H) || defined(__wii__)
# import "OFStreamObserver_poll.h"
#endif
#if defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
# import "OFStreamObserver_select.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFOutOfRangeException.h"

#import "autorelease.h"
#import "macros.h"
#import "socket_helpers.h"

enum {
	QUEUE_ADD = 0,
	QUEUE_REMOVE = 1,
	QUEUE_READ = 0,
	QUEUE_WRITE = 2
};
#define QUEUE_ACTION (QUEUE_ADD | QUEUE_REMOVE)

@implementation OFStreamObserver
+ (instancetype)observer
{
	return [[[self alloc] init] autorelease];
}

#if defined(HAVE_KQUEUE)
+ alloc
{
	if (self == [OFStreamObserver class])
		return [OFStreamObserver_kqueue alloc];

	return [super alloc];
}
#elif defined(HAVE_POLL_H) || defined(__wii__)
+ alloc
{
	if (self == [OFStreamObserver class])
		return [OFStreamObserver_poll alloc];

	return [super alloc];
}
#elif defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
+ alloc
{
	if (self == [OFStreamObserver class])
		return [OFStreamObserver_select alloc];

	return [super alloc];
}
#endif

- init
{
	self = [super init];

	@try {
#ifndef OF_HAVE_PIPE
		struct sockaddr_in cancelAddr2;
# ifndef __wii__
		socklen_t cancelAddrLen;
# endif
#endif

		_readStreams = [[OFMutableArray alloc] init];
		_writeStreams = [[OFMutableArray alloc] init];
		_queue = [[OFMutableArray alloc] init];
		_queueInfo = [[OFDataArray alloc]
		    initWithItemSize: sizeof(int)];
		_queueFDs = [[OFDataArray alloc] initWithItemSize: sizeof(int)];

#ifdef OF_HAVE_PIPE
		if (pipe(_cancelFD))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
#else
		/* Make sure network has been initialized */
		[OFStreamSocket class];

		_cancelFD[0] = socket(AF_INET, SOCK_DGRAM, 0);
		_cancelFD[1] = socket(AF_INET, SOCK_DGRAM, 0);

		if (_cancelFD[0] == INVALID_SOCKET ||
		    _cancelFD[1] == INVALID_SOCKET)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		_cancelAddr.sin_family = AF_INET;
		_cancelAddr.sin_port = 0;
		_cancelAddr.sin_addr.s_addr = inet_addr("127.0.0.1");
		cancelAddr2 = _cancelAddr;

# ifdef __wii__
		/* The Wii does not accept port 0 as "choose any free port" */
		_cancelAddr.sin_port = 65533;
		cancelAddr2.sin_port = 65534;
# endif

		if (bind(_cancelFD[0], (struct sockaddr*)&_cancelAddr,
		    sizeof(_cancelAddr)) || bind(_cancelFD[1],
		    (struct sockaddr*)&cancelAddr2, sizeof(cancelAddr2)))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

# ifndef __wii__
		cancelAddrLen = sizeof(_cancelAddr);
		if (getsockname(_cancelFD[0], (struct sockaddr*)&_cancelAddr,
		    &cancelAddrLen))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
# endif
#endif

		_maxFD = _cancelFD[0];
		_FDToStream = [self allocMemoryWithSize: sizeof(OFStream*)
						  count: _maxFD + 1];
		_FDToStream[_cancelFD[0]] = nil;

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
	close(_cancelFD[1]);

	[_readStreams release];
	[_writeStreams release];
	[_queue release];
	[_queueInfo release];
	[_queueFDs release];
#ifdef OF_HAVE_THREADS
	[_mutex release];
#endif

	[super dealloc];
}

- (id <OFStreamObserverDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate: (id <OFStreamObserverDelegate>)delegate
{
	_delegate = delegate;
}

- (void)addStreamForReading: (OFStream*)stream
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_ADD | QUEUE_READ;
		int fd = [stream fileDescriptorForReading];

		[_queue addObject: stream];
		[_queueInfo addItem: &qi];
		[_queueFDs addItem: &fd];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)addStreamForWriting: (OFStream*)stream
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_ADD | QUEUE_WRITE;
		int fd = [stream fileDescriptorForWriting];

		[_queue addObject: stream];
		[_queueInfo addItem: &qi];
		[_queueFDs addItem: &fd];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)removeStreamForReading: (OFStream*)stream
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_REMOVE | QUEUE_READ;
		int fd = [stream fileDescriptorForReading];

		[_queue addObject: stream];
		[_queueInfo addItem: &qi];
		[_queueFDs addItem: &fd];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)removeStreamForWriting: (OFStream*)stream
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		int qi = QUEUE_REMOVE | QUEUE_WRITE;
		int fd = [stream fileDescriptorForWriting];

		[_queue addObject: stream];
		[_queueInfo addItem: &qi];
		[_queueFDs addItem: &fd];
	} @finally {
#ifdef OF_HAVE_THREADS
		[_mutex unlock];
#endif
	}

	[self cancel];
}

- (void)OF_addFileDescriptorForReading: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_addFileDescriptorForWriting: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_removeFileDescriptorForReading: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_removeFileDescriptorForWriting: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_processQueue
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
#endif
	@try {
		OFStream **queueObjects = [_queue objects];
		int *queueInfoItems = [_queueInfo items];
		int *queueFDsItems = [_queueFDs items];
		size_t i, count = [_queue count];

		for (i = 0; i < count; i++) {
			OFStream *stream = queueObjects[i];
			int action = queueInfoItems[i];
			int fd = queueFDsItems[i];

			if ((action & QUEUE_ACTION) == QUEUE_ADD) {
				if (fd > _maxFD) {
					_maxFD = fd;
					_FDToStream = [self
					    resizeMemory: _FDToStream
						    size: sizeof(OFStream*)
						   count: _maxFD + 1];
				}

				_FDToStream[fd] = stream;
			}

			if ((action & QUEUE_ACTION) == QUEUE_REMOVE) {
				/* FIXME: Maybe downsize? */
				_FDToStream[fd] = nil;
			}

			switch (action) {
			case QUEUE_ADD | QUEUE_READ:
				[_readStreams addObject: stream];

				[self OF_addFileDescriptorForReading: fd];

				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[_writeStreams addObject: stream];

				[self OF_addFileDescriptorForWriting: fd];

				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[_readStreams removeObjectIdenticalTo: stream];

				[self OF_removeFileDescriptorForReading: fd];

				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[_writeStreams removeObjectIdenticalTo: stream];

				[self OF_removeFileDescriptorForWriting: fd];

				break;
			default:
				assert(0);
			}
		}

		[_queue removeAllObjects];
		[_queueInfo removeAllItems];
		[_queueFDs removeAllItems];
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

- (bool)observeForTimeInterval: (of_time_interval_t)timeInterval
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)observeUntilDate: (OFDate*)date
{
	return [self observeForTimeInterval: [date timeIntervalSinceNow]];
}

- (void)cancel
{
#ifdef OF_HAVE_PIPE
	OF_ENSURE(write(_cancelFD[1], "", 1) > 0);
#else
	OF_ENSURE(sendto(_cancelFD[1], "", 1, 0, (struct sockaddr*)&_cancelAddr,
	    sizeof(_cancelAddr)) > 0);
#endif
}

- (bool)OF_processCache
{
	OFStream **objects = [_readStreams objects];
	size_t i, count = [_readStreams count];
	bool foundInCache = false;

	for (i = 0; i < count; i++) {
		if ([objects[i] numberOfBytesInReadBuffer] > 0 &&
		    ![objects[i] OF_isWaitingForDelimiter]) {
			void *pool = objc_autoreleasePoolPush();

			if ([_delegate respondsToSelector:
			    @selector(streamIsReadyForReading:)])
				[_delegate streamIsReadyForReading: objects[i]];

			foundInCache = true;

			objc_autoreleasePoolPop(pool);
		}
	}

	/*
	 * As long as we have data in the cache for any stream, we don't want
	 * to block.
	 */
	if (foundInCache)
		return true;

	return false;
}
@end
