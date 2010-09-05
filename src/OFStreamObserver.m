/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#ifdef OF_HAVE_POLL
# include <poll.h>
#endif

#import "OFStreamObserver.h"
#import "OFDataArray.h"
#import "OFDictionary.h"
#import "OFStream.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

@implementation OFStreamObserver
+ streamObserver
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

#ifdef OF_HAVE_POLL
	fds = [[OFDataArray alloc] initWithItemSize: sizeof(struct pollfd)];
#else
	FD_ZERO(&readfds);
	FD_ZERO(&writefds);
#endif
	fdToStream = [[OFMutableDictionary alloc] init];

	return self;
}

- (void)dealloc
{
	[(id)delegate release];
#ifdef OF_HAVE_POLL
	[fds release];
#endif
	[fdToStream release];

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
		struct pollfd p = { fd, events, 0 };
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

			if (fds_c[i].events != 0)
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

	if (fd >= nfds)
		nfds = fd + 1;

	[fdToStream setObject: stream
		       forKey: [OFNumber numberWithInt: fd]];

	[pool release];
}

- (void)_removeStream: (OFStream*)stream
	    withFDSet: (fd_set*)fdset
{
	int fd = [stream fileDescriptor];

	if (fd >= FD_SETSIZE)
		@throw [OFOutOfRangeException newWithClass: isa];

	FD_CLR(fd, fdset);

	if (!FD_ISSET(fd, &readfds) && !FD_ISSET(fd, &writefds)) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		[fdToStream removeObjectForKey: [OFNumber numberWithInt: fd]];

		[pool release];
	}
}
#endif

- (void)addStreamToObserveForReading: (OFStream*)stream
{
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
#ifdef OF_HAVE_POLL
	[self _removeStream: stream
		 withEvents: POLLIN];
#else
	[self _removeStream: stream
		  withFDSet: &readfds];
#endif
}

- (void)removeStreamToObserveForWriting: (OFStream*)stream
{
#ifdef OF_HAVE_POLL
	[self _removeStream: stream
		 withEvents: POLLOUT];
#else
	[self _removeStream: stream
		  withFDSet: &writefds];
#endif
}

- (void)observe
{
	[self observeWithTimeout: -1];
}

- (BOOL)observeWithTimeout: (int)timeout
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
#ifdef OF_HAVE_POLL
	struct pollfd *fds_c = [fds cArray];
	size_t i, nfds = [fds count];

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

		fds_c[i].revents = 0;
	}
#else
	fd_set readfds_;
	fd_set writefds_;
	fd_set exceptfds_;
	struct timeval tv;
	OFEnumerator *enumerator;
	OFStream *stream;

	readfds_ = readfds;
	writefds_ = writefds;
	FD_ZERO(&exceptfds_);

	if (select(nfds, &readfds_, &writefds_, &exceptfds_,
	    (timeout != -1 ? &tv : NULL)) < 1)
		return NO;

	enumerator = [[[fdToStream copy] autorelease] objectEnumerator];

	while ((stream = [enumerator nextObject]) != nil) {
		int fd = [stream fileDescriptor];

		if (FD_ISSET(fd, &readfds_))
			[delegate streamDidBecomeReadyForReading: stream];

		if (FD_ISSET(fd, &writefds_))
			[delegate streamDidBecomeReadyForWriting: stream];
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
@end
