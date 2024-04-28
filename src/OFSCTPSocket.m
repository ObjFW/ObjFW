/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFSCTPSocket.h"
#import "OFAsyncIPSocketConnector.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"
#import "OFThread.h"

#import "OFAlreadyOpenException.h"
#import "OFBindIPSocketFailedException.h"
#import "OFGetOptionFailedException.h"
#import "OFNotOpenException.h"
#import "OFSetOptionFailedException.h"

static const OFRunLoopMode connectRunLoopMode =
    @"OFSCTPSocketConnectRunLoopMode";

@interface OFSCTPSocket () <OFAsyncIPSocketConnecting>
@end

@interface OFSCTPSocketConnectDelegate: OFObject <OFSCTPSocketDelegate>
{
@public
	bool _done;
	id _exception;
}
@end

@implementation OFSCTPSocketConnectDelegate
- (void)dealloc
{
	[_exception release];

	[super dealloc];
}

-     (void)socket: (OFSCTPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	_done = true;
	_exception = [exception retain];
}
@end

@implementation OFSCTPSocket
@dynamic delegate;

- (bool)of_createSocketForAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo
{
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if ((_socket = socket(
	    ((struct sockaddr *)&address->sockaddr)->sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, IPPROTO_SCTP)) ==
	    OFInvalidSocketHandle) {
		*errNo = OFSocketErrNo();
		return false;
	}

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	return true;
}

- (bool)of_connectSocketToAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (connect(_socket, (struct sockaddr *)&address->sockaddr,
	    address->length) != 0) {
		*errNo = OFSocketErrNo();
		return false;
	}

	return true;
}

- (void)of_closeSocket
{
	closesocket(_socket);
	_socket = OFInvalidSocketHandle;
}

- (void)connectToHost: (OFString *)host port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	id <OFSCTPSocketDelegate> delegate = _delegate;
	OFSCTPSocketConnectDelegate *connectDelegate =
	    [[[OFSCTPSocketConnectDelegate alloc] init] autorelease];
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];

	_delegate = connectDelegate;
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: connectRunLoopMode];

	while (!connectDelegate->_done)
		[runLoop runMode: connectRunLoopMode beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: connectRunLoopMode beforeDate: [OFDate date]];

	_delegate = delegate;

	if (connectDelegate->_exception != nil)
		@throw connectDelegate->_exception;

	objc_autoreleasePoolPop(pool);
}

- (void)asyncConnectToHost: (OFString *)host port: (uint16_t)port
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	[[[[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: _delegate
			   block: NULL
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (OFSCTPSocketAsyncConnectBlock)block
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: OFDefaultRunLoopMode
			   block: block];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFSCTPSocketAsyncConnectBlock)block
{
	void *pool = objc_autoreleasePoolPush();

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	[[[[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: nil
			   block: block] autorelease]
	    startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFSocketAddress)bindToHost: (OFString *)host port: (uint16_t)port
{
	const int one = 1;
	void *pool = objc_autoreleasePoolPush();
	OFData *socketAddresses;
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	socketAddresses = [[OFThread DNSResolver]
	    resolveAddressesForHost: host
		      addressFamily: OFSocketAddressFamilyAny];

	address = *(OFSocketAddress *)[socketAddresses itemAtIndex: 0];
	OFSocketAddressSetIPPort(&address, port);

	if ((_socket = socket(
	    ((struct sockaddr *)&address.sockaddr)->sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, IPPROTO_SCTP)) == OFInvalidSocketHandle)
		@throw [OFBindIPSocketFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	setsockopt(_socket, SOL_SOCKET, SO_REUSEADDR,
	    (char *)&one, (socklen_t)sizeof(one));

	if (bind(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPSocketFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
	}

	memset(&address, 0, sizeof(address));

	address.length = (socklen_t)sizeof(address.sockaddr);
	if (OFGetSockName(_socket, (struct sockaddr *)&address.sockaddr,
	    &address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPSocketFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
	}

	switch (((struct sockaddr *)&address.sockaddr)->sa_family) {
	case AF_INET:
		address.family = OFSocketAddressFamilyIPv4;
		break;
# ifdef OF_HAVE_IPV6
	case AF_INET6:
		address.family = OFSocketAddressFamilyIPv6;
		break;
# endif
	default:
		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPSocketFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: EAFNOSUPPORT];
	}

	objc_autoreleasePoolPop(pool);

	return address;
}

- (void)setCanDelaySendingPackets: (bool)canDelaySendingPackets
{
	int v = !canDelaySendingPackets;

	if (setsockopt(_socket, IPPROTO_SCTP, SCTP_NODELAY,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: OFSocketErrNo()];
}

- (bool)canDelaySendingPackets
{
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, IPPROTO_SCTP, SCTP_NODELAY,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: OFSocketErrNo()];

	return !v;
}
@end
