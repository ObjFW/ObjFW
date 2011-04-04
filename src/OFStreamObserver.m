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
#import "OFAutoreleasePool.h"

#import "OFInitializationFailedException.h"
#import "OFOutOfRangeException.h"

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
#ifdef OF_HAVE_POLL
		struct pollfd p = { 0, POLLIN, 0 };
#endif

		readStreams = [[OFMutableArray alloc] init];
		writeStreams = [[OFMutableArray alloc] init];
		queue = [[OFMutableArray alloc] init];
		queueInfo = [[OFMutableArray alloc] init];
#ifdef OF_HAVE_POLL
		fds = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct pollfd)];
		fdToStream = [[OFMutableDictionary alloc] init];
#else
		FD_ZERO(&readfds);
		FD_ZERO(&writefds);
#endif

		if (pipe(cancelFd))
			@throw [OFInitializationFailedException
			    newWithClass: isa];

#ifdef OF_HAVE_POLL
		p.fd = cancelFd[0];
		[fds addItem: &p];
#else
		FD_SET(cancelFd[0], &readfds);
		nfds = cancelFd[0] + 1;
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	close(cancelFd[0]);
	close(cancelFd[1]);

	[(id)delegate release];
	[readStreams release];
	[writeStreams release];
	[queue release];
	[queueInfo release];
#ifdef OF_HAVE_POLL
	[fdToStream release];
	[fds release];
#endif

	[super dealloc];
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
	struct pollfd *fds_c = [fds cArray];
	size_t i, count = [fds count];
	int fd = [stream fileDescriptor];
	BOOL found = NO;

	for (i = 0; i < count; i++) {
		if (fds_c[i].fd == fd) {
			fds_c[i].events |= events;
			found = YES;
		}
	}

	if (!found) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		struct pollfd p = { fd, events | POLLERR, 0 };
		[fds addItem: &p];
		[fdToStream setObject: stream
			       forKey: [OFNumber numberWithInt: fd]];
		[pool release];
	}
}

- (void)_removeStream: (OFStream*)stream
	   withEvents: (short)events
{
	struct pollfd *fds_c = [fds cArray];
	size_t i, nfds = [fds count];
	int fd = [stream fileDescriptor];

	for (i = 0; i < nfds; i++) {
		if (fds_c[i].fd == fd) {
			OFAutoreleasePool *pool;

			fds_c[i].events &= ~events;

			if ((fds_c[i].events & ~POLLERR) != 0)
				return;

			pool = [[OFAutoreleasePool alloc] init];

			[fds removeItemAtIndex: i];
			[fdToStream removeObjectForKey:
			    [OFNumber numberWithInt: fd]];

			[pool release];
		}
	}
}
#else
- (void)_addStream: (OFStream*)stream
	 withFDSet: (fd_set*)fdset
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	int fd = [stream fileDescriptor];

	if (fd >= FD_SETSIZE)
		@throw [OFOutOfRangeException newWithClass: isa];

	FD_SET(fd, fdset);
	FD_SET(fd, &exceptfds);

	if (fd >= nfds)
		nfds = fd + 1;

	[pool release];
}

- (void)_removeStream: (OFStream*)stream
	    withFDSet: (fd_set*)fdset
	   otherFDSet: (fd_set*)other_fdset
{
	int fd = [stream fileDescriptor];

	if (fd >= FD_SETSIZE)
		@throw [OFOutOfRangeException newWithClass: isa];

	FD_CLR(fd, fdset);

	if (!FD_ISSET(fd, other_fdset))
		FD_CLR(fd, &exceptfds);
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

	assert(!write(cancelFd[1], "", 1));

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

	assert(!write(cancelFd[1], "", 1));

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

	assert(!write(cancelFd[1], "", 1));

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

	assert(!write(cancelFd[1], "", 1));

	[pool release];
}

- (void)_processQueue
{
	@synchronized (queue) {
		OFStream **queue_c = [queue cArray];
		OFNumber **queueInfo_c = [queueInfo cArray];
		size_t i, count = [queue count];

		for (i = 0; i < count; i++) {
			switch ([queueInfo_c[i] intValue]) {
			case QUEUE_ADD | QUEUE_READ:
				[readStreams addObject: queue_c[i]];
#ifdef OF_HAVE_POLL
				[self _addStream: queue_c[i]
				      withEvents: POLLIN];
#else
				[self _addStream: queue_c[i]
				       withFDSet: &readfds];
#endif
				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[writeStreams addObject: queue_c[i]];
#ifdef OF_HAVE_POLL
				[self _addStream: queue_c[i]
				      withEvents: POLLOUT];
#else
				[self _addStream: queue_c[i]
				       withFDSet: &writefds];
#endif
				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[readStreams removeObjectIdenticalTo:
				    queue_c[i]];
#ifdef OF_HAVE_POLL
				[self _removeStream: queue_c[i]
					 withEvents: POLLIN];
#else
				[self _removeStream: queue_c[i]
					  withFDSet: &readfds
					 otherFDSet: &writefds];
#endif
				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[writeStreams removeObjectIdenticalTo:
				    queue_c[i]];
#ifdef OF_HAVE_POLL
				[self _removeStream: queue_c[i]
					 withEvents: POLLOUT];
#else
				[self _removeStream: queue_c[i]
					  withFDSet: &writefds
					 otherFDSet: &readfds];
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
	struct pollfd *fds_c;
	size_t nfds;
#else
	fd_set readfds_;
	fd_set writefds_;
	fd_set exceptfds_;
	struct timeval tv;
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
	fds_c = [fds cArray];
	nfds = [fds count];

# ifdef OPEN_MAX
	if (nfds > OPEN_MAX)
		@throw [OFOutOfRangeException newWithClass: isa];
# endif

	if (poll(fds_c, (nfds_t)nfds, timeout) < 1)
		return NO;

	for (i = 0; i < nfds; i++) {
		OFNumber *num;
		OFStream *stream;

		if (fds_c[i].revents & POLLIN) {
			if (fds_c[i].fd == cancelFd[0]) {
				char buf;

				assert(!read(cancelFd[0], &buf, 1));
				fds_c[i].revents = 0;

				continue;
			}

			num = [OFNumber numberWithInt: fds_c[i].fd];
			stream = [fdToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
			[pool releaseObjects];
		}

		if (fds_c[i].revents & POLLOUT) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			stream = [fdToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
			[pool releaseObjects];
		}

		if (fds_c[i].revents & POLLERR) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			stream = [fdToStream objectForKey: num];
			[delegate streamDidReceiveException: stream];
			[pool releaseObjects];
		}

		fds_c[i].revents = 0;
	}
#else
# ifdef FD_COPY
	FD_COPY(&readfds, &readfds_);
	FD_COPY(&writefds, &writefds_);
	FD_COPY(&exceptfds, &exceptfds_);
# else
	readfds_ = readfds;
	writefds_ = writefds;
	exceptfds_ = exceptfds;
# endif

	if (select(nfds, &readfds_, &writefds_, &exceptfds_,
	    (timeout != -1 ? &tv : NULL)) < 1)
		return NO;

	if (FD_ISSET(cancelFd[0], &readfds_)) {
		char buf;
		assert(!read(cancelFd[0], &buf, 1));
	}

	for (i = 0; i < count; i++) {
		int fd = [cArray[i] fileDescriptor];

		if (FD_ISSET(fd, &readfds_)) {
			[delegate streamDidBecomeReadyForReading: cArray[i]];
			[pool releaseObjects];
		}

		if (FD_ISSET(fd, &exceptfds_)) {
			[delegate streamDidReceiveException: cArray[i]];
			[pool releaseObjects];

			/*
			 * Prevent calling it twice in case the fd is in both
			 * sets.
			 */
			FD_CLR(fd, &exceptfds_);
		}
	}

	cArray = [writeStreams cArray];
	count = [writeStreams count];

	for (i = 0; i < count; i++) {
		int fd = [cArray[i] fileDescriptor];

		if (FD_ISSET(fd, &writefds_)) {
			[delegate streamDidBecomeReadyForWriting: cArray[i]];
			[pool releaseObjects];
		}

		if (FD_ISSET(fd, &exceptfds_)) {
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
