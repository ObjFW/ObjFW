/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#if defined(OF_MACOS) || defined(OF_IOS)
# ifndef AF_MULTIPATH
#  define AF_MULTIPATH 39
# endif
#endif

enum {
	flagAllowsMPTCP = 1,
	flagMapIPv4 = 2,
	flagUseConnectX = 4
};

static const OFRunLoopMode connectRunLoopMode =
    @"OFTCPSocketConnectRunLoopMode";

static OFString *defaultSOCKS5Host = nil;
static uint16_t defaultSOCKS5Port = 1080;

#if defined(OF_LINUX) && defined(IPPROTO_MPTCP)
static OFSocketAddress
mapIPv4(const OFSocketAddress *IPv4Address)
{
	OFSocketAddress IPv6Address = {
		.family = OFSocketAddressFamilyIPv6,
		.length = sizeof(struct sockaddr_in6)
	};

	IPv6Address.sockaddr.in6.sin6_family = AF_INET6;
	IPv6Address.sockaddr.in6.sin6_port = IPv4Address->sockaddr.in.sin_port;
	memcpy(&IPv6Address.sockaddr.in6.sin6_addr.s6_addr[12],
	    &IPv4Address->sockaddr.in.sin_addr.s_addr, 4);
	IPv6Address.sockaddr.in6.sin6_addr.s6_addr[10] = 0xFF;
	IPv6Address.sockaddr.in6.sin6_addr.s6_addr[11] = 0xFF;

	return IPv6Address;
}
#endif

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
	objc_release(_exception);

	[super dealloc];
}

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	_done = true;
	_exception = objc_retain(exception);
}
@end

@implementation OFTCPSocket
@synthesize SOCKS5Host = _SOCKS5Host, SOCKS5Port = _SOCKS5Port;
@dynamic delegate;

+ (void)setSOCKS5Host: (OFString *)host
{
	id old = defaultSOCKS5Host;
	defaultSOCKS5Host = [host copy];
	objc_release(old);
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
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_SOCKS5Host);

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

#if defined(OF_LINUX) && defined(IPPROTO_MPTCP)
	if (_flags & flagAllowsMPTCP) {
		/*
		 * For MPTCP sockets, we always use AF_INET6, so that IPv4 and
		 * IPv6 can both be used for a single connection.
		 */
		_socket = socket(AF_INET6, SOCK_STREAM | SOCK_CLOEXEC,
		    IPPROTO_MPTCP);

		if (_socket != OFInvalidSocketHandle &&
		    address->family == OFSocketAddressFamilyIPv4)
			_flags |= flagMapIPv4;
		else
			_flags &= ~flagMapIPv4;
	}
#elif (defined(OF_MACOS) || defined(OF_IOS)) && defined(SAE_ASSOCID_ANY)
	if (_flags & flagAllowsMPTCP) {
		_socket = socket(AF_MULTIPATH, SOCK_STREAM | SOCK_CLOEXEC,
		    IPPROTO_TCP);

		if (_socket != OFInvalidSocketHandle)
			_flags |= flagUseConnectX;
		else
			_flags &= ~flagUseConnectX;
	}
#endif

	if (_socket == OFInvalidSocketHandle) {
		if ((_socket = socket(
		    ((struct sockaddr *)&address->sockaddr)->sa_family,
		    SOCK_STREAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle) {
			*errNo = _OFSocketErrNo();
			return false;
		}
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
#if defined(OF_LINUX) && defined(IPPROTO_MPTCP)
	OFSocketAddress mappedIPv4;
#endif

	if (_socket == OFInvalidSocketHandle) {
		@throw [OFNotOpenException exceptionWithObject: self];
	}

#if defined(OF_LINUX) && defined(IPPROTO_MPTCP)
	if (_flags & flagMapIPv4) {
		/*
		 * For MPTCP sockets, we always use AF_INET6, so that IPv4 and
		 * IPv6 can both be used for a single connection.
		 */
		mappedIPv4 = mapIPv4(address);
		address = &mappedIPv4;
	}
#endif

#if (defined(OF_MACOS) || defined(OF_IOS)) && defined(SAE_ASSOCID_ANY)
	if (_flags & flagUseConnectX) {
		sa_endpoints_t endpoints = {
			.sae_dstaddr = (struct sockaddr *)&address->sockaddr,
			.sae_dstaddrlen = address->length
		};

		if (connectx(_socket, &endpoints, SAE_ASSOCID_ANY, 0, NULL, 0,
		    NULL, NULL) != 0) {
			*errNo = _OFSocketErrNo();
			return false;
		}
	} else
#endif
		/*
		 * Cast needed for AmigaOS, where the argument is declared
		 * non-const.
		 */
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
	    objc_autorelease([[OFTCPSocketConnectDelegate alloc] init]);
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
		delegate = objc_autorelease([[OFTCPSocketSOCKS5Connector alloc]
		    initWithSocket: self
			      host: host
			      port: port
			  delegate: _delegate
#ifdef OF_HAVE_BLOCKS
			   handler: NULL
#endif
		    ]);
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	} else
		delegate = _delegate;

	[objc_autorelease([[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: delegate
			 handler: NULL
	    ]) startWithRunLoopMode: runLoopMode];

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
		delegate = objc_autorelease([[OFTCPSocketSOCKS5Connector alloc]
		    initWithSocket: self
			      host: host
			      port: port
			  delegate: nil
			   handler: handler]);
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	}

	[objc_autorelease([[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: delegate
			 handler: (delegate == nil ? handler : NULL)])
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

#if defined(OF_LINUX) && defined(IPPROTO_MPTCP)
	if (_flags & flagAllowsMPTCP) {
		/*
		 * For MPTCP sockets, we always use AF_INET6, so that IPv4 and
		 * IPv6 can both be used for a single connection.
		 */
		_socket = socket(AF_INET6, SOCK_STREAM | SOCK_CLOEXEC,
		    IPPROTO_MPTCP);

		if (_socket != OFInvalidSocketHandle &&
		    address.family == OFSocketAddressFamilyIPv4)
			address = mapIPv4(&address);
	}
#endif

	if (_socket == OFInvalidSocketHandle)
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

#if defined(OF_LINUX) && defined(IPPROTO_MPTCP)
- (instancetype)accept
{
	OFTCPSocket *sock = [super accept];
	sock.allowsMPTCP = self.allowsMPTCP;
	return sock;
}
#endif

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

- (void)setAllowsMPTCP: (bool)allowsMPTCP
{
	if (allowsMPTCP)
		_flags |= flagAllowsMPTCP;
	else
		_flags &= ~flagAllowsMPTCP;
}

- (bool)allowsMPTCP
{
	return (_flags & flagAllowsMPTCP);
}

- (void)close
{
#ifdef OF_WII
	_port = 0;
#endif

	[super close];
}
@end
