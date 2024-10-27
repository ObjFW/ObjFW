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

#ifndef _XOPEN_SOURCE_EXTENDED
# define _XOPEN_SOURCE_EXTENDED
#endif
#define _HPUX_ALT_XOPEN_SOCKET_API

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFTCPSocket.h"
#import "OFAsyncIPSocketConnector.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"
#import "OFTCPSocketSOCKS5Connector.h"
#import "OFThread.h"

#import "OFAlreadyOpenException.h"
#import "OFBindIPSocketFailedException.h"
#import "OFGetOptionFailedException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFSetOptionFailedException.h"

static const OFRunLoopMode connectRunLoopMode =
    @"OFTCPSocketConnectRunLoopMode";

static OFString *defaultSOCKS5Host = nil;
static uint16_t defaultSOCKS5Port = 1080;

@interface OFTCPSocket () <OFAsyncIPSocketConnecting>
@end

@interface OFTCPSocketConnectDelegate: OFObject <OFTCPSocketDelegate>
{
@public
	bool _done;
	id _exception;
}
@end

@implementation OFTCPSocketConnectDelegate
- (void)dealloc
{
	[_exception release];

	[super dealloc];
}

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	_done = true;
	_exception = [exception retain];
}
@end

@implementation OFTCPSocket
@synthesize SOCKS5Host = _SOCKS5Host, SOCKS5Port = _SOCKS5Port;
@dynamic delegate;

+ (void)setSOCKS5Host: (OFString *)host
{
	id old = defaultSOCKS5Host;
	defaultSOCKS5Host = [host copy];
	[old release];
}

+ (OFString *)SOCKS5Host
{
	return defaultSOCKS5Host;
}

+ (void)setSOCKS5Port: (uint16_t)port
{
	defaultSOCKS5Port = port;
}

+ (uint16_t)SOCKS5Port
{
	return defaultSOCKS5Port;
}

- (instancetype)init
{
	self = [super init];

	@try {
		_SOCKS5Host = [defaultSOCKS5Host copy];
		_SOCKS5Port = defaultSOCKS5Port;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_SOCKS5Host release];

	[super dealloc];
}

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
	    SOCK_STREAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle) {
		*errNo = _OFSocketErrNo();
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

	/* Cast needed for AmigaOS, where the argument is declared non-const */
	if (connect(_socket, (struct sockaddr *)&address->sockaddr,
	    address->length) != 0) {
		*errNo = _OFSocketErrNo();
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
	id <OFTCPSocketDelegate> delegate = _delegate;
	OFTCPSocketConnectDelegate *connectDelegate =
	    [[[OFTCPSocketConnectDelegate alloc] init] autorelease];
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
	id <OFTCPSocketDelegate> delegate;

	if (_SOCKS5Host != nil) {
		delegate = [[[OFTCPSocketSOCKS5Connector alloc]
		    initWithSocket: self
			      host: host
			      port: port
			  delegate: _delegate
#ifdef OF_HAVE_BLOCKS
			   handler: NULL
#endif
		    ] autorelease];
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	} else
		delegate = _delegate;

	[[[[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: delegate
			 handler: NULL
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (OFTCPSocketAsyncConnectBlock)block
{
	OFTCPSocketConnectedHandler handler = ^ (OFTCPSocket *socket,
	    OFString *host_, uint16_t port_, id exception) {
		block(exception);
	};

	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: OFDefaultRunLoopMode
			 handler: handler];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		   handler: (OFTCPSocketConnectedHandler)handler
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: OFDefaultRunLoopMode
			 handler: handler];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFTCPSocketAsyncConnectBlock)block
{
	OFTCPSocketConnectedHandler handler = ^ (OFTCPSocket *socket,
	    OFString *host_, uint16_t port_, id exception) {
		block(exception);
	};

	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: runLoopMode
			 handler: handler];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		   handler: (OFTCPSocketConnectedHandler)handler
{
	void *pool = objc_autoreleasePoolPush();
	id <OFTCPSocketDelegate> delegate = nil;

	if (_SOCKS5Host != nil) {
		delegate = [[[OFTCPSocketSOCKS5Connector alloc]
		    initWithSocket: self
			      host: host
			      port: port
			  delegate: nil
			   handler: handler] autorelease];
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	}

	[[[[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: delegate
			 handler: (delegate == nil
				      ? handler : NULL)] autorelease]
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

	if (_SOCKS5Host != nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	socketAddresses = [[OFThread DNSResolver]
	    resolveAddressesForHost: host
		      addressFamily: OFSocketAddressFamilyAny];

	address = *(OFSocketAddress *)[socketAddresses itemAtIndex: 0];
	OFSocketAddressSetIPPort(&address, port);

	if ((_socket = socket(
	    ((struct sockaddr *)&address.sockaddr)->sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle)
		@throw [OFBindIPSocketFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: _OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	setsockopt(_socket, SOL_SOCKET, SO_REUSEADDR,
	    (char *)&one, (socklen_t)sizeof(one));

#if defined(OF_HPUX) || defined(OF_WII) || defined(OF_NINTENDO_3DS)
	if (port != 0) {
#endif
		if (bind(_socket, (struct sockaddr *)&address.sockaddr,
		    address.length) != 0) {
			int errNo = _OFSocketErrNo();

			closesocket(_socket);
			_socket = OFInvalidSocketHandle;

			@throw [OFBindIPSocketFailedException
			    exceptionWithHost: host
					 port: port
				       socket: self
					errNo: errNo];
		}
#if defined(OF_HPUX) || defined(OF_WII) || defined(OF_NINTENDO_3DS)
	} else {
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = (uint16_t)rand();

			OFSocketAddressSetIPPort(&address, rnd);

			if ((ret = bind(_socket,
			    (struct sockaddr *)&address.sockaddr,
			    address.length)) == 0)
				break;

			if (_OFSocketErrNo() != EADDRINUSE) {
				int errNo = _OFSocketErrNo();

				closesocket(_socket);
				_socket = OFInvalidSocketHandle;

				@throw [OFBindIPSocketFailedException
				    exceptionWithHost: host
						 port: port
					       socket: self
						errNo: errNo];
			}
		}
	}
#endif

#if !defined(OF_HPUX) && !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	memset(&address, 0, sizeof(address));

	address.length = (socklen_t)sizeof(address.sockaddr);
	if (_OFGetSockName(_socket, (struct sockaddr *)&address.sockaddr,
	    &address.length) != 0) {
		int errNo = _OFSocketErrNo();

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
#endif

	objc_autoreleasePoolPop(pool);

	return address;
}

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
- (void)setSendsKeepAlives: (bool)sendsKeepAlives
{
	int v = sendsKeepAlives;

	if (setsockopt(_socket, SOL_SOCKET, SO_KEEPALIVE,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];
}

- (bool)sendsKeepAlives
{
	int v;
	socklen_t len = (socklen_t)sizeof(v);

	if (getsockopt(_socket, SOL_SOCKET, SO_KEEPALIVE,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	return v;
}
#endif

#ifndef OF_WII
- (void)setCanDelaySendingSegments: (bool)canDelaySendingSegments
{
	int v = !canDelaySendingSegments;

	if (setsockopt(_socket, IPPROTO_TCP, TCP_NODELAY,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];
}

- (bool)canDelaySendingSegments
{
	int v;
	socklen_t len = (socklen_t)sizeof(v);

	if (getsockopt(_socket, IPPROTO_TCP, TCP_NODELAY,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	return !v;
}
#endif

- (void)close
{
#ifdef OF_WII
	_port = 0;
#endif

	[super close];
}
@end
