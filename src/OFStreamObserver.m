/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define OF_STREAM_OBSERVER_M
#define __NO_EXT_QNX

#include <assert.h>
#include <unistd.h>

#import "OFStreamObserver.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFStream.h"
#import "OFDataArray.h"
#ifdef _WIN32
# import "OFTCPSocket.h"
#endif
#import "OFThread.h"
#import "OFAutoreleasePool.h"

#ifdef HAVE_KQUEUE
# import "OFStreamObserver_kqueue.h"
#endif
#ifdef HAVE_POLL_H
# import "OFStreamObserver_poll.h"
#endif
#if defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
# import "OFStreamObserver_select.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

enum {
	QUEUE_ADD = 0,
	QUEUE_REMOVE = 1,
	QUEUE_READ = 0,
	QUEUE_WRITE = 2
};
#define QUEUE_ACTION (QUEUE_ADD | QUEUE_REMOVE)

@implementation OFStreamObserver
+ observer
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
#elif defined(HAVE_POLL_H)
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
#ifdef _WIN32
		struct sockaddr_in cancelAddr2;
		socklen_t cancelAddrLen;
#endif

		readStreams = [[OFMutableArray alloc] init];
		writeStreams = [[OFMutableArray alloc] init];
		queue = [[OFMutableArray alloc] init];
		queueInfo = [[OFDataArray alloc] initWithItemSize: sizeof(int)];
		queueFDs = [[OFDataArray alloc] initWithItemSize: sizeof(int)];

#ifndef _WIN32
		if (pipe(cancelFD))
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];
#else
		/* Make sure WSAStartup has been called */
		[OFTCPSocket class];

		cancelFD[0] = socket(AF_INET, SOCK_DGRAM, 0);
		cancelFD[1] = socket(AF_INET, SOCK_DGRAM, 0);

		if (cancelFD[0] == INVALID_SOCKET ||
		    cancelFD[1] == INVALID_SOCKET)
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		cancelAddr.sin_family = AF_INET;
		cancelAddr.sin_port = 0;
		cancelAddr.sin_addr.s_addr = inet_addr("127.0.0.1");
		cancelAddr2 = cancelAddr;

		if (bind(cancelFD[0], (struct sockaddr*)&cancelAddr,
		    sizeof(cancelAddr)) || bind(cancelFD[1],
		    (struct sockaddr*)&cancelAddr2, sizeof(cancelAddr2)))
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		cancelAddrLen = sizeof(cancelAddr);

		if (getsockname(cancelFD[0], (struct sockaddr*)&cancelAddr,
		    &cancelAddrLen))
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];
#endif

		maxFD = cancelFD[0];
		FDToStream = [self allocMemoryWithItemSize: sizeof(OFStream*)
						     count: maxFD + 1];
		FDToStream[cancelFD[0]] = nil;

#ifdef OF_THREADS
		mutex = [[OFMutex alloc] init];
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	close(cancelFD[0]);
	close(cancelFD[1]);

	[readStreams release];
	[writeStreams release];
	[queue release];
	[queueInfo release];
	[queueFDs release];
#ifdef OF_THREADS
	[mutex release];
#endif

	[super dealloc];
}

- (id <OFStreamObserverDelegate>)delegate
{
	return delegate;
}

- (void)setDelegate: (id <OFStreamObserverDelegate>)delegate_
{
	delegate = delegate_;
}

- (void)addStreamForReading: (OFStream*)stream
{
	[mutex lock];
	@try {
		int qi = QUEUE_ADD | QUEUE_READ;
		int fd = [stream fileDescriptor];

		[queue addObject: stream];
		[queueInfo addItem: &qi];
		[queueFDs addItem: &fd];
	} @finally {
		[mutex unlock];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif
}

- (void)addStreamForWriting: (OFStream*)stream
{
	[mutex lock];
	@try {
		int qi = QUEUE_ADD | QUEUE_WRITE;
		int fd = [stream fileDescriptor];

		[queue addObject: stream];
		[queueInfo addItem: &qi];
		[queueFDs addItem: &fd];
	} @finally {
		[mutex unlock];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif
}

- (void)removeStreamForReading: (OFStream*)stream
{
	[mutex lock];
	@try {
		int qi = QUEUE_REMOVE | QUEUE_READ;
		int fd = [stream fileDescriptor];

		[queue addObject: stream];
		[queueInfo addItem: &qi];
		[queueFDs addItem: &fd];
	} @finally {
		[mutex unlock];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif
}

- (void)removeStreamForWriting: (OFStream*)stream
{
	[mutex lock];
	@try {
		int qi = QUEUE_REMOVE | QUEUE_WRITE;
		int fd = [stream fileDescriptor];

		[queue addObject: stream];
		[queueInfo addItem: &qi];
		[queueFDs addItem: &fd];
	} @finally {
		[mutex unlock];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif
}

- (void)_addFileDescriptorForReading: (int)fd
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)_addFileDescriptorForWriting: (int)fd
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)_removeFileDescriptorForReading: (int)fd
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)_removeFileDescriptorForWriting: (int)fd
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)_processQueue
{
	[mutex lock];
	@try {
		OFStream **queueObjects = [queue objects];
		int *queueInfoCArray = [queueInfo cArray];
		int *queueFDsCArray = [queueFDs cArray];
		size_t i, count = [queue count];

		for (i = 0; i < count; i++) {
			OFStream *stream = queueObjects[i];
			int action = queueInfoCArray[i];
			int fd = queueFDsCArray[i];

			if ((action & QUEUE_ACTION) == QUEUE_ADD) {
				if (fd > maxFD) {
					maxFD = fd;
					FDToStream = [self
					    resizeMemory: FDToStream
						itemSize: sizeof(OFStream*)
						   count: maxFD + 1];
				}

				FDToStream[fd] = stream;
			}

			if ((action & QUEUE_ACTION) == QUEUE_REMOVE) {
				/* FIXME: Maybe downsize? */
				FDToStream[fd] = nil;
			}

			switch (action) {
			case QUEUE_ADD | QUEUE_READ:
				[readStreams addObject: stream];

				[self _addFileDescriptorForReading: fd];

				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[writeStreams addObject: stream];

				[self _addFileDescriptorForWriting: fd];

				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[readStreams removeObjectIdenticalTo: stream];

				[self _removeFileDescriptorForReading: fd];

				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[writeStreams removeObjectIdenticalTo: stream];

				[self _removeFileDescriptorForWriting: fd];

				break;
			default:
				assert(0);
			}
		}

		[queue removeAllObjects];
		[queueInfo removeAllItems];
		[queueFDs removeAllItems];
	} @finally {
		[mutex unlock];
	}
}

- (void)observe
{
	[self observeWithTimeout: -1];
}

- (BOOL)observeWithTimeout: (int)timeout
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (BOOL)_processCache
{
	OFAutoreleasePool *pool;
	OFStream **objects = [readStreams objects];
	size_t i, count = [readStreams count];
	BOOL foundInCache = NO;

	pool = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count; i++) {
		if ([objects[i] pendingBytes] > 0 &&
		    ![objects[i] _isWaitingForDelimiter]) {
			[delegate streamIsReadyForReading: objects[i]];
			foundInCache = YES;
			[pool releaseObjects];
		}
	}

	[pool release];

	/*
	 * As long as we have data in the cache for any stream, we don't want
	 * to block.
	 */
	if (foundInCache)
		return YES;

	return NO;
}
@end

@implementation OFObject (OFStreamObserverDelegate)
- (void)streamIsReadyForReading: (OFStream*)stream
{
}

- (void)streamIsReadyForWriting: (OFStream*)stream
{
}

- (void)streamDidReceiveException: (OFStream*)stream
{
}
@end
