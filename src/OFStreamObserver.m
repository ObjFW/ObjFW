/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
#import "OFNumber.h"
#ifdef _WIN32
# import "OFTCPSocket.h"
#endif
#import "OFAutoreleasePool.h"

#ifdef HAVE_POLL_H
# import "OFStreamObserver_poll.h"
#endif
#if defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
# import "OFStreamObserver_select.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

enum {
	QUEUE_ADD = 0,
	QUEUE_REMOVE = 1,
	QUEUE_READ = 0,
	QUEUE_WRITE = 2
};

@implementation OFStreamObserver
+ observer
{
	return [[[self alloc] init] autorelease];
}

#if defined(HAVE_POLL_H)
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
		queueInfo = [[OFMutableArray alloc] init];

#ifndef _WIN32
		if (pipe(cancelFD))
			@throw [OFInitializationFailedException
			    newWithClass: isa];
#else
		/* Make sure WSAStartup has been called */
		[OFTCPSocket class];

		cancelFD[0] = socket(AF_INET, SOCK_DGRAM, 0);
		cancelFD[1] = socket(AF_INET, SOCK_DGRAM, 0);

		if (cancelFD[0] == INVALID_SOCKET ||
		    cancelFD[1] == INVALID_SOCKET)
			@throw [OFInitializationFailedException
			    newWithClass: isa];

		cancelAddr.sin_family = AF_INET;
		cancelAddr.sin_port = 0;
		cancelAddr.sin_addr.s_addr = inet_addr("127.0.0.1");
		cancelAddr2 = cancelAddr;

		if (bind(cancelFD[0], (struct sockaddr*)&cancelAddr,
		    sizeof(cancelAddr)) || bind(cancelFD[1],
		    (struct sockaddr*)&cancelAddr2, sizeof(cancelAddr2)))
			@throw [OFInitializationFailedException
			    newWithClass: isa];

		cancelAddrLen = sizeof(cancelAddr);

		if (getsockname(cancelFD[0], (struct sockaddr*)&cancelAddr,
		    &cancelAddrLen))
			@throw [OFInitializationFailedException
			    newWithClass: isa];
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

	[(id)delegate release];
	[readStreams release];
	[writeStreams release];
	[queue release];
	[queueInfo release];

	[super dealloc];
}

- (id <OFStreamObserverDelegate>)delegate
{
	OF_GETTER(delegate, YES)
}

- (void)setDelegate: (id <OFStreamObserverDelegate>)delegate_
{
	OF_SETTER(delegate, delegate_, YES, NO)
}

- (void)addStreamToObserveForReading: (OFStream*)stream
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFNumber *qi = [OFNumber numberWithInt: QUEUE_ADD | QUEUE_READ];

	@synchronized (queue) {
		[queue addObject: stream];
		[queueInfo addObject: qi];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif

	[pool release];
}

- (void)addStreamToObserveForWriting: (OFStream*)stream
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFNumber *qi = [OFNumber numberWithInt: QUEUE_ADD | QUEUE_WRITE];

	@synchronized (queue) {
		[queue addObject: stream];
		[queueInfo addObject: qi];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif

	[pool release];
}

- (void)removeStreamToObserveForReading: (OFStream*)stream
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFNumber *qi = [OFNumber numberWithInt: QUEUE_REMOVE | QUEUE_READ];

	@synchronized (queue) {
		[queue addObject: stream];
		[queueInfo addObject: qi];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif

	[pool release];
}

- (void)removeStreamToObserveForWriting: (OFStream*)stream
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFNumber *qi = [OFNumber numberWithInt: QUEUE_REMOVE | QUEUE_WRITE];

	@synchronized (queue) {
		[queue addObject: stream];
		[queueInfo addObject: qi];
	}

#ifndef _WIN32
	assert(write(cancelFD[1], "", 1) > 0);
#else
	assert(sendto(cancelFD[1], "", 1, 0, (struct sockaddr*)&cancelAddr,
	    sizeof(cancelAddr)) > 0);
#endif

	[pool release];
}

- (void)observe
{
	[self observeWithTimeout: -1];
}

- (BOOL)observeWithTimeout: (int)timeout
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (BOOL)_processCache
{
	OFAutoreleasePool *pool;
	OFStream **cArray = [readStreams cArray];
	size_t i, count = [readStreams count];
	BOOL foundInCache = NO;

	pool = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count; i++) {
		if ([cArray[i] pendingBytes] > 0) {
			[delegate streamDidBecomeReadyForReading: cArray[i]];
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
- (void)streamDidBecomeReadyForReading: (OFStream*)stream
{
}

- (void)streamDidBecomeReadyForWriting: (OFStream*)stream
{
}

- (void)streamDidReceiveException: (OFStream*)stream
{
}
@end
