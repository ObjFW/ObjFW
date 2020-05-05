/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#define __NO_EXT_QNX

#include "config.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFTCPSocket.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFString.h"
#import "OFTCPSocketSOCKS5Connector.h"
#import "OFThread.h"
#import "OFTimer.h"

#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"
#import "OFConnectionFailedException.h"
#import "OFGetOptionFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFSetOptionFailedException.h"

#import "socket.h"
#import "socket_helpers.h"

static const of_run_loop_mode_t connectRunLoopMode =
    @"of_tcp_socket_connect_mode";

Class of_tls_socket_class = Nil;

static OFString *defaultSOCKS5Host = nil;
static uint16_t defaultSOCKS5Port = 1080;

@interface OFTCPSocket ()
- (bool)of_createSocketForAddress: (const of_socket_address_t *)address
			    errNo: (int *)errNo;
- (bool)of_connectSocketToAddress: (const of_socket_address_t *)address
			    errNo: (int *)errNo;
- (void)of_closeSocket;
@end

@interface OFTCPSocketAsyncConnectDelegate: OFObject <OFTCPSocketDelegate,
    OFRunLoopConnectDelegate, OFDNSResolverHostDelegate>
{
	OFTCPSocket *_socket;
	OFString *_host;
	uint16_t _port;
	id <OFTCPSocketDelegate> _delegate;
#ifdef OF_HAVE_BLOCKS
	of_tcp_socket_async_connect_block_t _block;
#endif
	id _exception;
	OFData *_socketAddresses;
	size_t _socketAddressesIndex;
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id <OFTCPSocketDelegate>)delegate
#ifdef OF_HAVE_BLOCKS
			 block: (of_tcp_socket_async_connect_block_t)block
#endif
;
- (void)didConnect;
- (void)tryNextAddressWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;
- (void)startWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;
@end

@interface OFTCPSocketConnectDelegate: OFObject <OFTCPSocketDelegate>
{
@public
	bool _done;
	id _exception;
}
@end

@implementation OFTCPSocketAsyncConnectDelegate
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id <OFTCPSocketDelegate>)delegate
#ifdef OF_HAVE_BLOCKS
			 block: (of_tcp_socket_async_connect_block_t)block
#endif
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_host = [host copy];
		_port = port;
		_delegate = [delegate retain];
#ifdef OF_HAVE_BLOCKS
		_block = [block copy];
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_socket release];
	[_host release];
	[_delegate release];
#ifdef OF_HAVE_BLOCKS
	[_block release];
#endif
	[_exception release];
	[_socketAddresses release];

	[super dealloc];
}

- (void)didConnect
{
	if (_exception == nil)
		_socket.blocking = true;

#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block(_exception);
	else {
#endif
		if ([_delegate respondsToSelector:
		    @selector(socket:didConnectToHost:port:exception:)])
			[_delegate    socket: _socket
			    didConnectToHost: _host
					port: _port
				   exception: _exception];
#ifdef OF_HAVE_BLOCKS
	}
#endif
}

- (void)of_socketDidConnect: (id)sock
		  exception: (id)exception
{
	if (exception != nil) {
		/*
		 * self might be retained only by the pending async requests,
		 * which we're about to cancel.
		 */
		[[self retain] autorelease];

		[sock cancelAsyncRequests];
		[sock of_closeSocket];

		if (_socketAddressesIndex >= _socketAddresses.count) {
			_exception = [exception retain];
			[self didConnect];
		} else {
			/*
			 * We must not call it before returning, as otherwise
			 * the new socket would be removed from the queue upon
			 * return.
			 */
			OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
			SEL selector =
			    @selector(tryNextAddressWithRunLoopMode:);
			OFTimer *timer = [OFTimer
			    timerWithTimeInterval: 0
					   target: self
					 selector: selector
					   object: runLoop.currentMode
					  repeats: false];
			[runLoop addTimer: timer
				  forMode: runLoop.currentMode];
		}

		return;
	}

	[self didConnect];
}

- (id)of_connectionFailedExceptionForErrNo: (int)errNo
{
	return [OFConnectionFailedException exceptionWithHost: _host
							 port: _port
						       socket: _socket
							errNo: errNo];
}

- (void)tryNextAddressWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
{
	of_socket_address_t address = *(const of_socket_address_t *)
	    [_socketAddresses itemAtIndex: _socketAddressesIndex++];
	int errNo;

	of_socket_address_set_port(&address, _port);

	if (![_socket of_createSocketForAddress: &address
					  errNo: &errNo]) {
		if (_socketAddressesIndex >= _socketAddresses.count) {
			_exception = [[OFConnectionFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: _socket
				   errNo: errNo];
			[self didConnect];
			return;
		}

		[self tryNextAddressWithRunLoopMode: runLoopMode];
		return;
	}

#if defined(OF_NINTENDO_3DS) || defined(OF_WII)
	/*
	 * On Wii and 3DS, connect() fails if non-blocking is enabled.
	 *
	 * Additionally, on Wii, there is no getsockopt(), so it would not be
	 * possible to get the error (or success) after connecting anyway.
	 *
	 * So for now, connecting is blocking on Wii and 3DS.
	 *
	 * FIXME: Use a different thread as a work around.
	 */
	_socket.blocking = true;
#else
	_socket.blocking = false;
#endif

	if (![_socket of_connectSocketToAddress: &address
					  errNo: &errNo]) {
#if !defined(OF_NINTENDO_3DS) && !defined(OF_WII)
		if (errNo == EINPROGRESS) {
			[OFRunLoop of_addAsyncConnectForSocket: _socket
							  mode: runLoopMode
						      delegate: self];
			return;
		} else {
#endif
			[_socket of_closeSocket];

			if (_socketAddressesIndex >= _socketAddresses.count) {
				_exception = [[OFConnectionFailedException
				    alloc] initWithHost: _host
						   port: _port
						 socket: _socket
						  errNo: errNo];
				[self didConnect];
				return;
			}

			[self tryNextAddressWithRunLoopMode: runLoopMode];
			return;
#if !defined(OF_NINTENDO_3DS) && !defined(OF_WII)
		}
#endif
	}

#if defined(OF_NINTENDO_3DS) || defined(OF_WII)
	_socket.blocking = false;
#endif

	[self didConnect];
}

- (void)resolver: (OFDNSResolver *)resolver
  didResolveHost: (OFString *)host
       addresses: (OFData *)addresses
       exception: (id)exception
{
	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return;
	}

	_socketAddresses = [addresses copy];

	[self tryNextAddressWithRunLoopMode:
	    [OFRunLoop currentRunLoop].currentMode];
}

- (void)startWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
{
	@try {
		of_socket_address_t address =
		    of_socket_address_parse_ip(_host, _port);

		_socketAddresses = [[OFData alloc]
		    initWithItems: &address
			 itemSize: sizeof(address)
			    count: 1];

		[self tryNextAddressWithRunLoopMode: runLoopMode];
		return;
	} @catch (OFInvalidFormatException *e) {
	}

	[[OFThread DNSResolver]
	    asyncResolveAddressesForHost: _host
			   addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY
			     runLoopMode: runLoopMode
				delegate: self];
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
		_socket = INVALID_SOCKET;
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

- (bool)of_createSocketForAddress: (const of_socket_address_t *)address
			    errNo: (int *)errNo
{
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	if ((_socket = socket(address->sockaddr.sockaddr.sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, 0)) == INVALID_SOCKET) {
		*errNo = of_socket_errno();
		return false;
	}

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	return true;
}

- (bool)of_connectSocketToAddress: (const of_socket_address_t *)address
			    errNo: (int *)errNo
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	/* Cast needed for AmigaOS, where the argument is declared non-const */
	if (connect(_socket, (struct sockaddr *)&address->sockaddr.sockaddr,
	    address->length) != 0) {
		*errNo = of_socket_errno();
		return false;
	}

	return true;
}

- (void)of_closeSocket
{
	closesocket(_socket);
	_socket = INVALID_SOCKET;
}

- (void)connectToHost: (OFString *)host
		 port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	id <OFTCPSocketDelegate> delegate = [_delegate retain];
	OFTCPSocketConnectDelegate *connectDelegate =
	    [[[OFTCPSocketConnectDelegate alloc] init] autorelease];
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];

	self.delegate = connectDelegate;
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: connectRunLoopMode];

	while (!connectDelegate->_done)
		[runLoop runMode: connectRunLoopMode
		      beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: connectRunLoopMode
	      beforeDate: [OFDate date]];

	if (connectDelegate->_exception != nil)
		@throw connectDelegate->_exception;

	self.delegate = delegate;

	objc_autoreleasePoolPop(pool);
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: of_run_loop_mode_default];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (of_run_loop_mode_t)runLoopMode
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
			     block: NULL
#endif
		    ] autorelease];
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	} else
		delegate = _delegate;

	[[[[OFTCPSocketAsyncConnectDelegate alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: delegate
#ifdef OF_HAVE_BLOCKS
			   block: NULL
#endif
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (of_tcp_socket_async_connect_block_t)block
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: of_run_loop_mode_default
			   block: block];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (of_run_loop_mode_t)runLoopMode
		     block: (of_tcp_socket_async_connect_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	id <OFTCPSocketDelegate> delegate = nil;

	if (_SOCKS5Host != nil) {
		delegate = [[[OFTCPSocketSOCKS5Connector alloc]
		    initWithSocket: self
			      host: host
			      port: port
			  delegate: nil
			     block: block] autorelease];
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	}

	[[[[OFTCPSocketAsyncConnectDelegate alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: delegate
			   block: (delegate == nil ? block : NULL)] autorelease]
	    startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}
#endif

- (uint16_t)bindToHost: (OFString *)host
		  port: (uint16_t)port
{
	const int one = 1;
	void *pool = objc_autoreleasePoolPush();
	OFData *socketAddresses;
	of_socket_address_t address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	if (_SOCKS5Host != nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	socketAddresses = [[OFThread DNSResolver]
	    resolveAddressesForHost: host
		      addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY];

	address = *(of_socket_address_t *)[socketAddresses itemAtIndex: 0];
	of_socket_address_set_port(&address, port);

	if ((_socket = socket(address.sockaddr.sockaddr.sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: of_socket_errno()];

	_blocking = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	setsockopt(_socket, SOL_SOCKET, SO_REUSEADDR,
	    (char *)&one, (socklen_t)sizeof(one));

#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	if (port != 0) {
#endif
		if (bind(_socket, &address.sockaddr.sockaddr,
		    address.length) != 0) {
			int errNo = of_socket_errno();

			closesocket(_socket);
			_socket = INVALID_SOCKET;

			@throw [OFBindFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
		}
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	} else {
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = (uint16_t)rand();

			of_socket_address_set_port(&address, rnd);

			if ((ret = bind(_socket, &address.sockaddr.sockaddr,
			    address.length)) == 0) {
				port = rnd;
				break;
			}

			if (of_socket_errno() != EADDRINUSE) {
				int errNo = of_socket_errno();

				closesocket(_socket);
				_socket = INVALID_SOCKET;

				@throw [OFBindFailedException
				    exceptionWithHost: host
						 port: port
					       socket: self
						errNo: errNo];
			}
		}
	}
#endif

	objc_autoreleasePoolPop(pool);

	if (port > 0)
		return port;

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	memset(&address, 0, sizeof(address));

	address.length = (socklen_t)sizeof(address.sockaddr);
	if (of_getsockname(_socket, &address.sockaddr.sockaddr,
	    &address.length) != 0) {
		int errNo = of_socket_errno();

		closesocket(_socket);
		_socket = INVALID_SOCKET;

		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: errNo];
	}

	if (address.sockaddr.sockaddr.sa_family == AF_INET)
		return OF_BSWAP16_IF_LE(address.sockaddr.in.sin_port);
# ifdef OF_HAVE_IPV6
	else if (address.sockaddr.sockaddr.sa_family == AF_INET6)
		return OF_BSWAP16_IF_LE(address.sockaddr.in6.sin6_port);
# endif
	else {
		closesocket(_socket);
		_socket = INVALID_SOCKET;

		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: EAFNOSUPPORT];
	}
#else
	closesocket(_socket);
	_socket = INVALID_SOCKET;
	@throw [OFBindFailedException exceptionWithHost: host
						   port: port
						 socket: self
						  errNo: EADDRNOTAVAIL];
#endif
}

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
- (void)setKeepAliveEnabled: (bool)enabled
{
	int v = enabled;

	if (setsockopt(_socket, SOL_SOCKET, SO_KEEPALIVE,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: of_socket_errno()];
}

- (bool)isKeepAliveEnabled
{
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, SOL_SOCKET, SO_KEEPALIVE,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: of_socket_errno()];

	return v;
}
#endif

#ifndef OF_WII
- (void)setNoDelayEnabled: (bool)enabled
{
	int v = enabled;

	if (setsockopt(_socket, IPPROTO_TCP, TCP_NODELAY,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: of_socket_errno()];
}

- (bool)isNoDelayEnabled
{
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, IPPROTO_TCP, TCP_NODELAY,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: of_socket_errno()];

	return v;
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
