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

#import "OFOutOfRangeException.h"

@implementation OFStreamObserver
+ observer
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		readStreams = [[OFMutableArray alloc] init];
		writeStreams = [[OFMutableArray alloc] init];
#ifdef OF_HAVE_POLL
		fds = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct pollfd)];
		fdToStream = [[OFMutableDictionary alloc] init];
#else
		FD_ZERO(&readfds);
		FD_ZERO(&writefds);
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[(id)delegate release];
	[readStreams release];
	[writeStreams release];
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
	[readStreams addObject: stream];

#ifdef OF_HAVE_POLL
	[self _addStream: stream
	      withEvents: POLLIN];
#else
	[self _addStream: stream
	       withFDSet: &readfds];
#endif
}

- (void)addStreamToObserveForWriting: (OFStream*)stream
{
	[writeStreams addObject: stream];

#ifdef OF_HAVE_POLL
	[self _addStream: stream
	      withEvents: POLLOUT];
#else
	[self _addStream: stream
	       withFDSet: &writefds];
#endif
}

- (void)removeStreamToObserveForReading: (OFStream*)stream
{
	[readStreams removeObjectIdenticalTo: stream];

#ifdef OF_HAVE_POLL
	[self _removeStream: stream
		 withEvents: POLLIN];
#else
	[self _removeStream: stream
		  withFDSet: &readfds
		 otherFDSet: &writefds];
#endif
}

- (void)removeStreamToObserveForWriting: (OFStream*)stream
{
	[writeStreams removeObjectIdenticalTo: stream];

#ifdef OF_HAVE_POLL
	[self _removeStream: stream
		 withEvents: POLLOUT];
#else
	[self _removeStream: stream
		  withFDSet: &writefds
		 otherFDSet: &readfds];
#endif
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
	struct pollfd *fds_c = [fds cArray];
	/*
	 * There is no way to find out the maximum number of fds, so we just
	 * cast.
	 */
	nfds_t nfds = (nfds_t)[fds count];
#else
	fd_set readfds_;
	fd_set writefds_;
	fd_set exceptfds_;
	struct timeval tv;
#endif

	cArray = [readStreams cArray];
	count = [readStreams count];

	for (i = 0; i < count; i++) {
		if (cArray[i]->cache != NULL) {
			[delegate streamDidBecomeReadyForReading: cArray[i]];
			foundInCache = YES;
		}
	}

	/*
	 * As long as we have data in the cache for any stream, we don't want
	 * to block.
	 */
	if (foundInCache)
		return YES;

#ifdef OF_HAVE_POLL
	if (poll(fds_c, nfds, timeout) < 1)
		return NO;

	for (i = 0; i < nfds; i++) {
		OFNumber *num;
		OFStream *stream;

		if (fds_c[i].revents & POLLIN) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			stream = [fdToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
		}

		if (fds_c[i].revents & POLLOUT) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			stream = [fdToStream objectForKey: num];
			[delegate streamDidBecomeReadyForReading: stream];
		}

		if (fds_c[i].revents & POLLERR) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			stream = [fdToStream objectForKey: num];
			[delegate streamDidReceiveException: stream];
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

	for (i = 0; i < count; i++) {
		int fd = [cArray[i] fileDescriptor];

		if (FD_ISSET(fd, &readfds_))
			[delegate streamDidBecomeReadyForReading: cArray[i]];

		if (FD_ISSET(fd, &exceptfds_)) {
			[delegate streamDidReceiveException: cArray[i]];

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

		if (FD_ISSET(fd, &writefds_))
			[delegate streamDidBecomeReadyForWriting: cArray[i]];

		if (FD_ISSET(fd, &exceptfds_))
			[delegate streamDidReceiveException: cArray[i]];
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
