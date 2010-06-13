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

#ifdef OF_HAVE_POLL
# include <poll.h>
#endif

#import "OFSocketObserver.h"
#import "OFDataArray.h"
#import "OFDictionary.h"
#import "OFSocket.h"
#import "OFTCPSocket.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

@implementation OFSocketObserver
+ socketObserver
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
	fdToSocket = [[OFMutableDictionary alloc] init];

	return self;
}

- (void)dealloc
{
	[delegate release];
#ifdef OF_HAVE_POLL
	[fds release];
#endif
	[fdToSocket release];

	[super dealloc];
}

- (OFObject <OFSocketObserverDelegate>*)delegate
{
	return [[delegate retain] autorelease];
}

- (void)setDelegate: (OFObject <OFSocketObserverDelegate>*)delegate_
{
	[delegate_ retain];
	[delegate release];
	delegate = delegate_;
}

#ifdef OF_HAVE_POLL
- (void)_addSocket: (OFSocket*)sock
	withEvents: (short)events
{
	struct pollfd *fds_c = [fds cArray];
	size_t i, count = [fds count];
	BOOL found = NO;

	for (i = 0; i < count; i++) {
		if (fds_c[i].fd == sock->sock) {
			fds_c[i].events |= events;
			found = YES;
		}
	}

	if (!found) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		struct pollfd p = { sock->sock, events, 0 };
		[fds addItem: &p];
		[fdToSocket setObject: sock
			       forKey: [OFNumber numberWithInt: sock->sock]];
		[pool release];
	}
}

- (void)_removeSocket: (OFSocket*)sock
	   withEvents: (short)events
{
	struct pollfd *fds_c = [fds cArray];
	size_t i, nfds = [fds count];

	for (i = 0; i < nfds; i++) {
		if (fds_c[i].fd == sock->sock) {
			OFAutoreleasePool *pool;

			fds_c[i].events &= ~events;

			if (fds_c[i].events != 0)
				return;

			pool = [[OFAutoreleasePool alloc] init];

			[fds removeItemAtIndex: i];
			[fdToSocket removeObjectForKey:
			    [OFNumber numberWithInt: sock->sock]];

			[pool release];
		}
	}
}
#else
- (void)_addSocket: (OFSocket*)sock
	 withFDSet: (fd_set*)fdset
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	if (sock->sock >= FD_SETSIZE)
		@throw [OFOutOfRangeException newWithClass: isa];

	FD_SET(sock->sock, fdset);

	if (sock->sock >= nfds)
		nfds = sock->sock + 1;

	[fdToSocket setObject: sock
		       forKey: [OFNumber numberWithInt: sock->sock]];

	[pool release];
}

- (void)_removeSocket: (OFSocket*)sock
	    withFDSet: (fd_set*)fdset
{
	if (sock->sock >= FD_SETSIZE)
		@throw [OFOutOfRangeException newWithClass: isa];

	FD_CLR(sock->sock, fdset);

	if (!FD_ISSET(sock->sock, &readfds) &&
	    !FD_ISSET(sock->sock, &writefds)) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		[fdToSocket removeObjectForKey:
		    [OFNumber numberWithInt: sock->sock]];

		[pool release];
	}
}
#endif

- (void)addSocketToObserveForIncomingConnections: (OFTCPSocket*)sock
{
#ifdef OF_HAVE_POLL
	[self _addSocket: sock
	      withEvents: POLLIN];
#else
	[self _addSocket: sock
	       withFDSet: &readfds];
#endif
}

- (void)addSocketToObserveForReading: (OFSocket*)sock
{
#ifdef OF_HAVE_POLL
	[self _addSocket: sock
	      withEvents: POLLIN];
#else
	[self _addSocket: sock
	       withFDSet: &readfds];
#endif
}

- (void)addSocketToObserveForWriting: (OFSocket*)sock
{
#ifdef OF_HAVE_POLL
	[self _addSocket: sock
	      withEvents: POLLOUT];
#else
	[self _addSocket: sock
	       withFDSet: &writefds];
#endif
}

- (void)removeSocketToObserveForIncomingConnections: (OFTCPSocket*)sock
{
#ifdef OF_HAVE_POLL
	[self _removeSocket: sock
		 withEvents: POLLIN];
#else
	[self _removeSocket: sock
		  withFDSet: &readfds];
#endif
}

- (void)removeSocketToObserveForReading: (OFSocket*)sock
{
#ifdef OF_HAVE_POLL
	[self _removeSocket: sock
		 withEvents: POLLIN];
#else
	[self _removeSocket: sock
		  withFDSet: &readfds];
#endif
}

- (void)removeSocketToObserveForWriting: (OFSocket*)sock
{
#ifdef OF_HAVE_POLL
	[self _removeSocket: sock
		 withEvents: POLLOUT];
#else
	[self _removeSocket: sock
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
		OFSocket *sock;

		if (fds_c[i].revents & POLLIN) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			sock = [fdToSocket objectForKey: num];

			if (sock->listening)
				[delegate socketDidReceiveIncomingConnection:
				    (OFTCPSocket*)sock];
			else
				[delegate socketDidBecomeReadyForReading: sock];
		}

		if (fds_c[i].revents & POLLOUT) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			sock = [fdToSocket objectForKey: num];
			[delegate socketDidBecomeReadyForReading: sock];
		}

		fds_c[i].revents = 0;
	}
#else
	fd_set readfds_;
	fd_set writefds_;
	fd_set exceptfds_;
	struct timeval tv;
	OFEnumerator *enumerator;
	OFSocket *sock;

	readfds_ = readfds;
	writefds_ = writefds;
	FD_ZERO(&exceptfds_);

	if (select(nfds, &readfds_, &writefds_, &exceptfds_,
	    (timeout != -1 ? &tv : NULL)) < 1)
		return NO;

	enumerator = [[[fdToSocket copy] autorelease] objectEnumerator];

	while ((sock = [enumerator nextObject]) != nil) {
		if (FD_ISSET(sock->sock, &readfds_)) {
			if (sock->listening)
				[delegate socketDidReceiveIncomingConnection:
				    (OFTCPSocket*)sock];
			else
				[delegate socketDidBecomeReadyForReading: sock];
		}

		if (FD_ISSET(sock->sock, &writefds_))
			[delegate socketDidBecomeReadyForWriting: sock];
	}
#endif
	[pool release];

	return YES;
}
@end

@implementation OFObject (OFSocketObserverDelegate)
- (void)socketDidReceiveIncomingConnection: (OFTCPSocket*)sock
{
}

- (void)socketDidBecomeReadyForReading: (OFSocket*)sock
{
}

- (void)socketDidBecomeReadyForWriting: (OFSocket*)sock
{
}
@end
