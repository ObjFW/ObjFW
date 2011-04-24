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

#include <string.h>

#include <assert.h>

#include <unistd.h>

#ifdef OF_HAVE_POLL
# include <poll.h>
#endif

#import "OFStreamObserver.h"
#import "OFDataArray.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFStream.h"
#import "OFNumber.h"
#ifdef _WIN32
# import "OFTCPSocket.h"
#endif
#import "OFAutoreleasePool.h"

#import "OFInitializationFailedException.h"
#import "OFOutOfRangeException.h"

#ifdef _WIN32
# define close(sock) closesocket(sock)
#endif

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

- init
{
	self = [super init];

	@try {
#ifdef _WIN32
		struct sockaddr_in cancelAddr2;
		socklen_t cancelAddrLen;
#endif
#ifdef OF_HAVE_POLL
		struct pollfd p = { 0, POLLIN, 0 };
#endif

		readStreams = [[OFMutableArray alloc] init];
		writeStreams = [[OFMutableArray alloc] init];
		queue = [[OFMutableArray alloc] init];
		queueInfo = [[OFMutableArray alloc] init];
#ifdef OF_HAVE_POLL
		FDs = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct pollfd)];
		FDToStream = [[OFMutableDictionary alloc] init];
#else
		FD_ZERO(&readFDs);
		FD_ZERO(&writeFDs);
#endif

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

#ifdef OF_HAVE_POLL
		p.fd = cancelFD[0];
		[FDs addItem: &p];
#else
		FD_SET(cancelFD[0], &readFDs);
		nFDs = cancelFD[0] + 1;
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
#ifdef OF_HAVE_POLL
	[FDToStream release];
	[FDs release];
#endif

	[super dealloc];
}

- (void)finalize
{
	close(cancelFD[0]);
	close(cancelFD[1]);

	[super finalize];
}

- (id <OFStreamObserverDelegate>)delegate
{
	return [[(id)delegate retain] autorelease];
}

- (void)setDelegate: (id <OFStreamObserverDelegate>)delegate_
{
	[(id)delegate_ retain];
	[(id)delegate release];
	delegate = delegate_;
}

#ifdef OF_HAVE_POLL
- (void)_addStream: (OFStream*)stream
	withEvents: (short)events
{
	struct pollfd *FDsCArray = [FDs cArray];
	size_t i, count = [FDs count];
	int fileDescriptor = [stream fileDescriptor];
	BOOL found = NO;

	for (i = 0; i < count; i++) {
		if (FDsCArray[i].fd == fileDescriptor) {
			FDsCArray[i].events |= events;
			found = YES;
		}
	}

	if (!found) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		struct pollfd p = { fileDescriptor, events | POLLERR, 0 };
		[FDs addItem: &p];
		[FDToStream setObject: stream
			       forKey: [OFNumber numberWithInt:
				       fileDescriptor]];
		[pool release];
	}
}

- (void)_removeStream: (OFStream*)stream
	   withEvents: (short)events
{
	struct pollfd *FDsCArray = [FDs cArray];
	size_t i, nFDs = [FDs count];
	int fileDescriptor = [stream fileDescriptor];

	for (i = 0; i < nFDs; i++) {
		if (FDsCArray[i].fd == fileDescriptor) {
			OFAutoreleasePool *pool;

			FDsCArray[i].events &= ~events;

			if ((FDsCArray[i].events & ~POLLERR) != 0)
				return;

			pool = [[OFAutoreleasePool alloc] init];

			[FDs removeItemAtIndex: i];
			[FDToStream removeObjectForKey:
			    [OFNumber numberWithInt: fileDescriptor]];

			[pool release];
		}
	}
}
#else
- (void)_addStream: (OFStream*)stream
	 withFDSet: (fd_set*)FDSet
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	int fileDescriptor = [stream fileDescriptor];

	FD_SET(fileDescriptor, FDSet);
	FD_SET(fileDescriptor, &exceptFDs);

	if (fileDescriptor >= nFDs)
		nFDs = fileDescriptor + 1;

	[pool release];
}

- (void)_removeStream: (OFStream*)stream
	    withFDSet: (fd_set*)FDSet
	   otherFDSet: (fd_set*)otherFDSet
{
	int fileDescriptor = [stream fileDescriptor];

	FD_CLR(fileDescriptor, FDSet);

	if (!FD_ISSET(fileDescriptor, otherFDSet))
		FD_CLR(fileDescriptor, &exceptFDs);
}
#endif

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

- (void)_processQueue
{
	@synchronized (queue) {
		OFStream **queueCArray = [queue cArray];
		OFNumber **queueInfoCArray = [queueInfo cArray];
		size_t i, count = [queue count];

		for (i = 0; i < count; i++) {
			switch ([queueInfoCArray[i] intValue]) {
			case QUEUE_ADD | QUEUE_READ:
				[readStreams addObject: queueCArray[i]];
#ifdef OF_HAVE_POLL
				[self _addStream: queueCArray[i]
				      withEvents: POLLIN];
#else
				[self _addStream: queueCArray[i]
				       withFDSet: &readFDs];
#endif
				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[writeStreams addObject: queueCArray[i]];
#ifdef OF_HAVE_POLL
				[self _addStream: queueCArray[i]
				      withEvents: POLLOUT];
#else
				[self _addStream: queueCArray[i]
				       withFDSet: &writeFDs];
#endif
				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[readStreams removeObjectIdenticalTo:
				    queueCArray[i]];
#ifdef OF_HAVE_POLL
				[self _removeStream: queueCArray[i]
					 withEvents: POLLIN];
#else
				[self _removeStream: queueCArray[i]
					  withFDSet: &readFDs
					 otherFDSet: &writeFDs];
#endif
				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[writeStreams removeObjectIdenticalTo:
				    queueCArray[i]];
#ifdef OF_HAVE_POLL
				[self _removeStream: queueCArray[i]
					 withEvents: POLLOUT];
#else
				[self _removeStream: queueCArray[i]
					  withFDSet: &writeFDs
					 otherFDSet: &readFDs];
#endif
				break;
			default:
				assert(0);
			}
		}

		[queue removeNObjects: count];
		[queueInfo removeNObjects: count];
	}
}

- (void)observe
{
	[self observeWithTimeout: -1];
}

- (BOOL)observeWithTimeout: (int)timeout
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	BOOL foundInCache = NO;
	OFStream **cArray;
	size_t i, count;
#ifdef OF_HAVE_POLL
	struct pollfd *FDsCArray;
	size_t nFDs;
#else
	fd_set readFDs_;
	fd_set writeFDs_;
	fd_set exceptFDs_;
	struct timeval time;
#endif

	[self _processQueue];

	cArray = [readStreams cArray];
	count = [readStreams count];

	for (i = 0; i < count; i++) {
		if ([cArray[i] pendingBytes] > 0) {
			[delegate streamDidBecomeReadyForReading: cArray[i]];
			foundInCache = YES;
			[pool releaseObjects];
		}
	}

	/*
	 * As long as we have data in the cache for any stream, we don't want
	 * to block.
	 */
	if (foundInCache)
		return YES;

#ifdef OF_HAVE_POLL
	FDsCArray = [FDs cArray];
	nFDs = [FDs count];

# ifdef OPEN_MAX
	if (nFDs > OPEN_MAX)
		@throw [OFOutOfRangeException newWithClass: isa];
# endif

	if (poll(FDsCArray, (nfds_t)nFDs, timeout) < 1)
		return NO;

	for (i = 0; i < nFDs; i++) {
		OFNumber *num;
		OFStream *stream;

		if (FDsCArray[i].revents & POLLIN) {
			if (FDsCArray[i].fd == cancelFD[0]) {
				char buffer;

				assert(read(cancelFD[0], &buffer, 1) > 0);
				FDsCArray[i].revents = 0;

				continue;
			}

			num = [OFNumber numberWithInt: FDsCArray[i].fd];
			stream = [FDToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
			[pool releaseObjects];
		}

		if (FDsCArray[i].revents & POLLOUT) {
			num = [OFNumber numberWithInt: FDsCArray[i].fd];
			stream = [FDToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
			[pool releaseObjects];
		}

		if (FDsCArray[i].revents & POLLERR) {
			num = [OFNumber numberWithInt: FDsCArray[i].fd];
			stream = [FDToStream objectForKey: num];
			[delegate streamDidReceiveException: stream];
			[pool releaseObjects];
		}

		FDsCArray[i].revents = 0;
	}
#else
# ifdef FD_COPY
	FD_COPY(&readFDs, &readFDs_);
	FD_COPY(&writeFDs, &writeFDs_);
	FD_COPY(&exceptFDs, &exceptFDs_);
# else
	readFDs_ = readFDs;
	writeFDs_ = writeFDs;
	exceptFDs_ = exceptFDs;
# endif

	time.tv_sec = timeout / 1000;
	time.tv_usec = (timeout % 1000) * 1000;

	if (select(nFDs, &readFDs_, &writeFDs_, &exceptFDs_,
	    (timeout != -1 ? &time : NULL)) < 1)
		return NO;

	if (FD_ISSET(cancelFD[0], &readFDs_)) {
		char buffer;
#ifndef _WIN32
		assert(read(cancelFD[0], &buffer, 1) > 0);
#else
		assert(recvfrom(cancelFD[0], &buffer, 1, 0, NULL, NULL) > 0);
#endif
	}

	for (i = 0; i < count; i++) {
		int fileDescriptor = [cArray[i] fileDescriptor];

		if (FD_ISSET(fileDescriptor, &readFDs_)) {
			[delegate streamDidBecomeReadyForReading: cArray[i]];
			[pool releaseObjects];
		}

		if (FD_ISSET(fileDescriptor, &exceptFDs_)) {
			[delegate streamDidReceiveException: cArray[i]];
			[pool releaseObjects];

			/*
			 * Prevent calling it twice in case the FD is in both
			 * sets.
			 */
			FD_CLR(fileDescriptor, &exceptFDs_);
		}
	}

	cArray = [writeStreams cArray];
	count = [writeStreams count];

	for (i = 0; i < count; i++) {
		int fileDescriptor = [cArray[i] fileDescriptor];

		if (FD_ISSET(fileDescriptor, &writeFDs_)) {
			[delegate streamDidBecomeReadyForWriting: cArray[i]];
			[pool releaseObjects];
		}

		if (FD_ISSET(fileDescriptor, &exceptFDs_)) {
			[delegate streamDidReceiveException: cArray[i]];
			[pool releaseObjects];
		}
	}
#endif

	[pool release];

	return YES;
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
