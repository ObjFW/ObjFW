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

#include <poll.h>

#import "OFSocketObserver.h"
#import "OFDataArray.h"
#import "OFDictionary.h"
#import "OFSocket.h"
#import "OFTCPSocket.h"
#import "OFNumber.h"
#import "OFAutoreleasePool.h"

@implementation OFSocketObserver
+ socketObserver
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	fds = [[OFDataArray alloc] initWithItemSize: sizeof(struct pollfd)];
	fdToSocket = [[OFMutableDictionary alloc] init];

	return self;
}

- (void)dealloc
{
	[delegate release];
	[fds release];
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

- (void)addSocketToObserveForIncomingConnections: (OFTCPSocket*)sock
{
	[self _addSocket: sock
	      withEvents: POLLIN];
}

- (void)addSocketToObserveForReading: (OFSocket*)sock
{
	[self _addSocket: sock
	      withEvents: POLLIN];
}

- (void)addSocketToObserveForWriting: (OFSocket*)sock
{
	[self _addSocket: sock
	      withEvents: POLLOUT];
}

- (void)removeSocketToObserveForIncomingConnections: (OFTCPSocket*)sock
{
	[self _removeSocket: sock
		 withEvents: POLLIN];
}

- (void)removeSocketToObserveForReading: (OFSocket*)sock
{
	[self _removeSocket: sock
		 withEvents: POLLIN];
}

- (void)removeSocketToObserveForWriting: (OFSocket*)sock
{
	[self _removeSocket: sock
		 withEvents: POLLOUT];
}

- (int)observe
{
	return [self observeWithTimeout: -1];
}

- (int)observeWithTimeout: (int)timeout
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	struct pollfd *fds_c = [fds cArray];
	size_t i, nfds = [fds count];
	int ret = poll(fds_c, nfds, timeout);

	if (ret <= 0)
		return ret;

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

	[pool release];

	return ret;
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
