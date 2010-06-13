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

- (void)addSocketToObserveForReading: (OFSocket*)sock
{
	struct pollfd *fds_c = [fds cArray];
	size_t i, count = [fds count];
	BOOL found = NO;

	for (i = 0; i < count; i++) {
		if (fds_c[i].fd == sock->sock) {
			fds_c[i].events |= POLLIN;
			found = YES;
		}
	}

	if (!found) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		struct pollfd p = { sock->sock, POLLIN, 0 };
		[fds addItem: &p];
		[fdToSocket setObject: sock
			       forKey: [OFNumber numberWithInt: sock->sock]];
		[pool release];
	}
}

- (void)addSocketToObserveForWriting: (OFSocket*)sock
{
	struct pollfd *fds_c = [fds cArray];
	size_t i, nfds = [fds count];
	BOOL found = NO;

	for (i = 0; i < nfds; i++) {
		if (fds_c[i].fd == sock->sock) {
			fds_c[i].events |= POLLOUT;
			found = YES;
		}
	}

	if (!found) {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		struct pollfd p = { sock->sock, POLLOUT, 0 };
		[fds addItem: &p];
		[fdToSocket setObject: sock
			       forKey: [OFNumber numberWithInt: sock->sock]];
		[pool release];
	}
}

- (void)removeSocketToObserveForReading: (OFSocket*)sock
{
	struct pollfd *fds_c = [fds cArray];
	size_t i, nfds = [fds count];

	for (i = 0; i < nfds; i++) {
		if (fds_c[i].fd == sock->sock) {
			OFAutoreleasePool *pool;

			fds_c[i].events &= ~POLLIN;

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

- (void)removeSocketToObserveForWriting: (OFSocket*)sock
{
	struct pollfd *fds_c = [fds cArray];
	size_t i, nfds = [fds count];

	for (i = 0; i < nfds; i++) {
		if (fds_c[i].fd == sock->sock) {
			OFAutoreleasePool *pool;

			fds_c[i].events &= ~POLLOUT;

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
			[delegate socketDidGetReadyForReading: sock];
		}

		if (fds_c[i].revents & POLLOUT) {
			num = [OFNumber numberWithInt: fds_c[i].fd];
			sock = [fdToSocket objectForKey: num];
			[delegate socketDidGetReadyForReading: sock];
		}

		fds_c[i].revents = 0;
	}

	[pool release];

	return ret;
}
@end

@implementation OFObject (OFSocketObserverDelegate)
- (void)socketDidGetReadyForReading: (OFSocket*)sock
{
}

- (void)socketDidGetReadyForWriting: (OFSocket*)sock
{
}
@end
