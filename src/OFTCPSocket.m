/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

#define OF_TCP_SOCKET_M
#define __NO_EXT_QNX

#include "config.h"

#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFTCPSocket.h"
#import "OFTCPSocket+Private.h"
#import "OFDate.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFString.h"
#import "OFThread.h"
#import "OFTimer.h"

#import "OFAcceptFailedException.h"
#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"
#import "OFConnectionFailedException.h"
#import "OFGetOptionFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFListenFailedException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFSetOptionFailedException.h"

#import "socket.h"
#import "socket_helpers.h"
#import "resolver.h"

Class of_tls_socket_class = Nil;

static of_run_loop_mode_t connectRunLoopMode = @"of_tcp_socket_connect_mode";
static OFString *defaultSOCKS5Host = nil;
static uint16_t defaultSOCKS5Port = 1080;

@interface OFTCPSocket_AsyncConnectContext: OFObject
{
	OFTCPSocket *_socket;
	OFString *_host;
	uint16_t _port;
	OFString *_SOCKS5Host;
	uint16_t _SOCKS5Port;
	id _target;
	SEL _selector;
	id _context;
#ifdef OF_HAVE_BLOCKS
	of_tcp_socket_async_connect_block_t _block;
#endif
	id _exception;
	OFData *_socketAddresses;
	size_t _socketAddressesIndex;
	/* Longest read is domain name (max 255 bytes) + port */
	unsigned char _buffer[257];
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		    SOCKS5Host: (OFString *)SOCKS5Host
		    SOCKS5Port: (uint16_t)SOCKS5Port
			target: (id)target
		      selector: (SEL)selector
		       context: (id)context;
#ifdef OF_HAVE_BLOCKS
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		    SOCKS5Host: (OFString *)SOCKS5Host
		    SOCKS5Port: (uint16_t)SOCKS5Port
			 block: (of_tcp_socket_async_connect_block_t)block;
#endif
- (void)didConnect;
- (void)socketDidConnect: (OFTCPSocket *)sock
		 context: (id)context
	       exception: (id)exception;
- (void)tryNextAddressWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;
-	(void)resolver: (OFDNSResolver *)resolver
  didResolveDomainName: (OFString *)domainName
       socketAddresses: (OFData *)socketAddresses
	       context: (id)context
	     exception: (id)exception;
- (void)startWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;
- (void)sendSOCKS5Request;
-	       (size_t)socket: (OFTCPSocket *)sock
  didSendSOCKS5Authentication: (const void *)request
		 bytesWritten: (size_t)bytesWritten
		      context: (id)context
		    exception: (id)exception;
-	 (bool)socket: (OFTCPSocket *)sock
  didReadSOCKSVersion: (unsigned char *)SOCKSVersion
	       length: (size_t)length
	      context: (id)context
	    exception: (id)exception;
-	(size_t)socket: (OFTCPSocket *)sock
  didSendSOCKS5Request: (const void *)request
	  bytesWritten: (size_t)bytesWritten
	       context: (id)context
	     exception: (id)exception;
-	   (bool)socket: (OFTCPSocket *)sock
  didReadSOCKS5Response: (unsigned char *)response
		 length: (size_t)length
		context: (id)context
	      exception: (id)exception;
-	  (bool)socket: (OFTCPSocket *)sock
  didReadSOCKS5Address: (unsigned char *)address
		length: (size_t)length
	       context: (id)context
	     exception: (id)exception;
-		(bool)socket: (OFTCPSocket *)sock
  didReadSOCKS5AddressLength: (unsigned char *)addressLength
		      length: (size_t)length
		     context: (id)context
		   exception: (id)exception;
@end

@interface OFTCPSocket_ConnectContext: OFObject
{
@public
	bool _connected;
	id _exception;
}

- (void)socketDidConnect: (OFTCPSocket *)sock
		 context: (id)context
	       exception: (id)exception;
@end

@implementation OFTCPSocket_AsyncConnectContext
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		    SOCKS5Host: (OFString *)SOCKS5Host
		    SOCKS5Port: (uint16_t)SOCKS5Port
			target: (id)target
		      selector: (SEL)selector
		       context: (id)context
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_host = [host copy];
		_port = port;
		_SOCKS5Host = [SOCKS5Host copy];
		_SOCKS5Port = SOCKS5Port;
		_target = [target retain];
		_selector = selector;
		_context = [context retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_BLOCKS
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		    SOCKS5Host: (OFString *)SOCKS5Host
		    SOCKS5Port: (uint16_t)SOCKS5Port
			 block: (of_tcp_socket_async_connect_block_t)block
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_host = [host copy];
		_port = port;
		_SOCKS5Host = [SOCKS5Host copy];
		_SOCKS5Port = SOCKS5Port;
		_block = [block copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[_socket release];
	[_host release];
	[_SOCKS5Host release];
	[_target release];
	[_context release];
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
		[_socket setBlocking: true];

#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block(_socket, _exception);
	else {
#endif
		void (*func)(id, SEL, OFTCPSocket *, id, id) =
		    (void (*)(id, SEL, OFTCPSocket *, id, id))
		    [_target methodForSelector: _selector];

		func(_target, _selector, _socket, _context, _exception);
#ifdef OF_HAVE_BLOCKS
	}
#endif
}

- (void)socketDidConnect: (OFTCPSocket *)sock
		 context: (id)context
	       exception: (id)exception
{
	if (exception != nil) {
		if (_socketAddressesIndex >= [_socketAddresses count]) {
			_exception = [exception retain];
			[self didConnect];
		} else {
			[self tryNextAddressWithRunLoopMode:
			    [[OFRunLoop currentRunLoop] currentMode]];
		}

		return;
	}

	if (_SOCKS5Host != nil)
		[self sendSOCKS5Request];
	else
		[self didConnect];
}

- (void)tryNextAddressWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
{
	of_socket_address_t address = *(const of_socket_address_t *)
	    [_socketAddresses itemAtIndex: _socketAddressesIndex++];
	int errNo;

	if (_SOCKS5Host != nil)
		of_socket_address_set_port(&address, _SOCKS5Port);
	else
		of_socket_address_set_port(&address, _port);

	if (![_socket of_createSocketForAddress: &address
					  errNo: &errNo]) {
		if (_socketAddressesIndex >= [_socketAddresses count]) {
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

	[_socket setBlocking: false];

	if (![_socket of_connectSocketToAddress: &address
					  errNo: &errNo]) {
		if (errNo == EINPROGRESS) {
			SEL selector = @selector(socketDidConnect:context:
			    exception:);

			[OFRunLoop of_addAsyncConnectForTCPSocket: _socket
							     mode: runLoopMode
							   target: self
							 selector: selector
							  context: nil];
			return;
		} else {
			[_socket of_closeSocket];

			if (_socketAddressesIndex >= [_socketAddresses count]) {
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
		}
	}

	[self didConnect];
}

-	(void)resolver: (OFDNSResolver *)resolver
  didResolveDomainName: (OFString *)domainName
       socketAddresses: (OFData *)socketAddresses
	       context: (id)context
	     exception: (id)exception
{
	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return;
	}

	_socketAddresses = [socketAddresses copy];

	[self tryNextAddressWithRunLoopMode:
	    [[OFRunLoop currentRunLoop] currentMode]];
}

- (void)startWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
{
	OFString *host;
	uint16_t port;

	if (_SOCKS5Host != nil) {
		if ([_host UTF8StringLength] > 255)
			@throw [OFOutOfRangeException exception];

		host = _SOCKS5Host;
		port = _SOCKS5Port;
	} else {
		host = _host;
		port = _port;
	}

	@try {
		of_socket_address_t address =
		    of_socket_address_parse_ip(host, port);

		_socketAddresses = [[OFData alloc]
		    initWithItems: &address
			 itemSize: sizeof(address)
			    count: 1];

		[self tryNextAddressWithRunLoopMode: runLoopMode];
		return;
	} @catch (OFInvalidFormatException *e) {
	}

	[[OFThread DNSResolver]
	    asyncResolveSocketAddressesForHost: host
				 addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY
				   runLoopMode: runLoopMode
					target: self
				      selector: @selector(resolver:
						    didResolveDomainName:
						    socketAddresses:context:
						    exception:)
				       context: nil];
}

- (void)sendSOCKS5Request
{
	[_socket asyncWriteBuffer: "\x05\x01\x00"
			   length: 3
		      runLoopMode: [[OFRunLoop currentRunLoop] currentMode]
			   target: self
			 selector: @selector(socket:didSendSOCKS5Authentication:
				       bytesWritten:context:exception:)
			  context: nil];
}

-	       (size_t)socket: (OFTCPSocket *)sock
  didSendSOCKS5Authentication: (const void *)request
		 bytesWritten: (size_t)bytesWritten
		      context: (id)context
		    exception: (id)exception
{
	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return 0;
	}

	[_socket asyncReadIntoBuffer: _buffer
			 exactLength: 2
			 runLoopMode: [[OFRunLoop currentRunLoop] currentMode]
			      target: self
			    selector: @selector(socket:didReadSOCKSVersion:
					  length:context:exception:)
			     context: nil];

	return 0;
}

-	 (bool)socket: (OFTCPSocket *)sock
  didReadSOCKSVersion: (unsigned char *)SOCKSVersion
	       length: (size_t)length
	      context: (id)context
	    exception: (id)exception
{
	OFMutableData *request;
	uint8_t hostLength;
	unsigned char port[2];

	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return false;
	}

	if (SOCKSVersion[0] != 5 || SOCKSVersion[1] != 0) {
		_exception = [[OFConnectionFailedException alloc]
		    initWithHost: _host
			    port: _port
			  socket: self
			   errNo: EPROTONOSUPPORT];
		[self didConnect];
		return false;
	}

	request = [OFMutableData data];
	[request addItems: "\x05\x01\x00\x03"
		    count: 4];

	hostLength = (uint8_t)[_host UTF8StringLength];
	[request addItem: &hostLength];
	[request addItems: [_host UTF8String]
		    count: hostLength];

	port[0] = _port >> 8;
	port[1] = _port & 0xFF;
	[request addItems: port
		    count: 2];

	/* Use request as context to retain it */
	[_socket asyncWriteBuffer: [request items]
			   length: [request count]
		      runLoopMode: [[OFRunLoop currentRunLoop] currentMode]
			   target: self
			 selector: @selector(socket:didSendSOCKS5Request:
				       bytesWritten:context:exception:)
			  context: request];

	return false;
}

-	(size_t)socket: (OFTCPSocket *)sock
  didSendSOCKS5Request: (const void *)request
	  bytesWritten: (size_t)bytesWritten
	       context: (id)context
	     exception: (id)exception
{
	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return 0;
	}

	[_socket asyncReadIntoBuffer: _buffer
			 exactLength: 4
			 runLoopMode: [[OFRunLoop currentRunLoop] currentMode]
			      target: self
			    selector: @selector(socket:didReadSOCKS5Response:
					  length:context:exception:)
			     context: nil];

	return 0;
}

-	   (bool)socket: (OFTCPSocket *)sock
  didReadSOCKS5Response: (unsigned char *)response
		 length: (size_t)length
		context: (id)context
	      exception: (id)exception
{
	of_run_loop_mode_t runLoopMode;

	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return false;
	}

	if (response[0] != 5 || response[2] != 0) {
		_exception = [[OFConnectionFailedException alloc]
		    initWithHost: _host
			    port: _port
			  socket: self
			   errNo: EPROTONOSUPPORT];
		[self didConnect];
		return false;
	}

	if (response[1] != 0) {
		int errNo;

		switch (response[1]) {
		case 0x02:
			errNo = EACCES;
			break;
		case 0x03:
			errNo = ENETUNREACH;
			break;
		case 0x04:
			errNo = EHOSTUNREACH;
			break;
		case 0x05:
			errNo = ECONNREFUSED;
			break;
		case 0x06:
			errNo = ETIMEDOUT;
			break;
		case 0x07:
			errNo = EPROTONOSUPPORT;
			break;
		case 0x08:
			errNo = EAFNOSUPPORT;
			break;
		default:
			errNo = EPROTO;
			break;
		}

		_exception = [[OFConnectionFailedException alloc]
		    initWithHost: _host
			    port: _port
			  socket: _socket
			   errNo: errNo];
		[self didConnect];
		return false;
	}

	runLoopMode = [[OFRunLoop currentRunLoop] currentMode];

	/* Skip the rest of the response */
	switch (response[3]) {
	case 1: /* IPv4 */
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: 4 + 2
				 runLoopMode: runLoopMode
				      target: self
				    selector: @selector(socket:
						  didReadSOCKS5Address:length:
						  context:exception:)
				     context: nil];
		return false;
	case 3: /* Domain name */
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: 1
				 runLoopMode: runLoopMode
				      target: self
				    selector: @selector(socket:
						  didReadSOCKS5AddressLength:
						  length:context:exception:)
				     context: nil];
		return false;
	case 4: /* IPv6 */
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: 16 + 2
				 runLoopMode: runLoopMode
				      target: self
				    selector: @selector(socket:
						  didReadSOCKS5Address:length:
						  context:exception:)
				     context: nil];
		return false;
	default:
		_exception = [[OFConnectionFailedException alloc]
		    initWithHost: _host
			    port: _port
			  socket: self
			   errNo: EPROTONOSUPPORT];
		[self didConnect];
		return false;
	}

	return false;
}

-	  (bool)socket: (OFTCPSocket *)sock
  didReadSOCKS5Address: (unsigned char *)address
		length: (size_t)length
	       context: (id)context
	     exception: (id)exception
{
	_exception = [exception retain];
	[self didConnect];
	return false;
}

-		(bool)socket: (OFTCPSocket *)sock
  didReadSOCKS5AddressLength: (unsigned char *)addressLength
		      length: (size_t)length
		     context: (id)context
		   exception: (id)exception
{
	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return false;
	}

	[_socket asyncReadIntoBuffer: _buffer
			 exactLength: addressLength[0] + 2
			 runLoopMode: [[OFRunLoop currentRunLoop] currentMode]
			      target: self
			    selector: @selector(socket:didReadSOCKS5Address:
					  length:context:exception:)
			     context: nil];
	return false;
}
@end

@implementation OFTCPSocket_ConnectContext
- (void)dealloc
{
	[_exception release];

	[super dealloc];
}

- (void)socketDidConnect: (OFTCPSocket *)sock
		 context: (id)context
	       exception: (id)exception
{
	if (exception != nil)
		_exception = [exception retain];

	_connected = true;
}
@end

@implementation OFTCPSocket
@synthesize SOCKS5Host = _SOCKS5Host, SOCKS5Port = _SOCKS5Port;

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

	if (connect(_socket, &address->sockaddr.sockaddr,
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

- (int)of_socketError
{
	int errNo;
	socklen_t len = sizeof(errNo);

	if (getsockopt(_socket, SOL_SOCKET, SO_ERROR, &errNo, &len) != 0)
		return of_socket_errno();

	return errNo;
}

- (void)connectToHost: (OFString *)host
		 port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	OFTCPSocket_ConnectContext *context =
	    [[[OFTCPSocket_ConnectContext alloc] init] autorelease];
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];

	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: connectRunLoopMode
			  target: context
			selector: @selector(socketDidConnect:context:exception:)
			 context: nil];

	while (!context->_connected)
		[runLoop runMode: connectRunLoopMode
		      beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: connectRunLoopMode
	      beforeDate: [OFDate date]];

	if (context->_exception != nil)
		@throw context->_exception;

	objc_autoreleasePoolPop(pool);
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		    target: (id)target
		  selector: (SEL)selector
		   context: (id)context
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: of_run_loop_mode_default
			  target: target
			selector: selector
			 context: context];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (of_run_loop_mode_t)runLoopMode
		    target: (id)target
		  selector: (SEL)selector
		   context: (id)context
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFTCPSocket_AsyncConnectContext alloc]
	    initWithSocket: self
		      host: host
		      port: port
		SOCKS5Host: _SOCKS5Host
		SOCKS5Port: _SOCKS5Port
		    target: target
		  selector: selector
		   context: context] autorelease]
	    startWithRunLoopMode: runLoopMode];

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

	[[[[OFTCPSocket_AsyncConnectContext alloc]
	    initWithSocket: self
		      host: host
		      port: port
		SOCKS5Host: _SOCKS5Host
		SOCKS5Port: _SOCKS5Port
		     block: block] autorelease]
	    startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}
#endif

- (uint16_t)bindToHost: (OFString *)host
		  port: (uint16_t)port
{
	of_resolver_result_t **results;
	const int one = 1;
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	of_socket_address_t address;
#endif

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	if (_SOCKS5Host != nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	results = of_resolve_host(host, port, SOCK_STREAM);
	@try {
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
		int flags;
#endif

		if ((_socket = socket(results[0]->family,
		    results[0]->type | SOCK_CLOEXEC,
		    results[0]->protocol)) == INVALID_SOCKET)
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
		    (const char *)&one, (socklen_t)sizeof(one));

#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
		if (port != 0) {
#endif
			if (bind(_socket, results[0]->address,
			    results[0]->addressLength) != 0) {
				int errNo = of_socket_errno();

				closesocket(_socket);
				_socket = INVALID_SOCKET;

				@throw [OFBindFailedException
				    exceptionWithHost: host
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

				switch (results[0]->family) {
				case AF_INET:
					((struct sockaddr_in *)
					    results[0]->address)->sin_port =
					    OF_BSWAP16_IF_LE(rnd);
					break;
# ifdef OF_HAVE_IPV6
				case AF_INET6:
					((struct sockaddr_in6 *)
					    results[0]->address)->sin6_port =
					    OF_BSWAP16_IF_LE(rnd);
					break;
# endif
				default:
					@throw [OFInvalidArgumentException
					    exception];
				}

				ret = bind(_socket, results[0]->address,
				    results[0]->addressLength);

				if (ret == 0) {
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
	} @finally {
		of_resolver_free(results);
	}

	if (port > 0)
		return port;

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
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
	if (address.sockaddr.sockaddr.sa_family == AF_INET6)
		return OF_BSWAP16_IF_LE(address.sockaddr.in6.sin6_port);
# endif
#endif

	closesocket(_socket);
	_socket = INVALID_SOCKET;
	@throw [OFBindFailedException exceptionWithHost: host
						   port: port
						 socket: self
						  errNo: EAFNOSUPPORT];
}

- (void)listen
{
	[self listenWithBacklog: SOMAXCONN];
}

- (void)listenWithBacklog: (int)backlog
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (listen(_socket, backlog) == -1)
		@throw [OFListenFailedException
		    exceptionWithSocket: self
				backlog: backlog
				  errNo: of_socket_errno()];

	_listening = true;
}

- (instancetype)accept
{
	OFTCPSocket *client = [[[[self class] alloc] init] autorelease];
#if (!defined(HAVE_PACCEPT) && !defined(HAVE_ACCEPT4)) || !defined(SOCK_CLOEXEC)
# if defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
# endif
#endif

	client->_remoteAddress.length =
	    (socklen_t)sizeof(client->_remoteAddress.sockaddr);

#if defined(HAVE_PACCEPT) && defined(SOCK_CLOEXEC)
	if ((client->_socket = paccept(_socket,
	    &client->_remoteAddress.sockaddr.sockaddr,
	    &client->_remoteAddress.length, NULL, SOCK_CLOEXEC)) ==
	    INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];
#elif defined(HAVE_ACCEPT4) && defined(SOCK_CLOEXEC)
	if ((client->_socket = accept4(_socket,
	    &client->_remoteAddress.sockaddr.sockaddr,
	    &client->_remoteAddress.length, SOCK_CLOEXEC)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];
#else
	if ((client->_socket = accept(_socket,
	    &client->_remoteAddress.sockaddr.sockaddr,
	    &client->_remoteAddress.length)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];

# if defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(client->_socket, F_GETFD, 0)) != -1)
		fcntl(client->_socket, F_SETFD, flags | FD_CLOEXEC);
# endif
#endif

	assert(client->_remoteAddress.length <=
	    (socklen_t)sizeof(client->_remoteAddress.sockaddr));

	switch (client->_remoteAddress.sockaddr.sockaddr.sa_family) {
	case AF_INET:
		client->_remoteAddress.family = OF_SOCKET_ADDRESS_FAMILY_IPV4;
		break;
#ifdef OF_HAVE_IPV6
	case AF_INET6:
		client->_remoteAddress.family = OF_SOCKET_ADDRESS_FAMILY_IPV6;
		break;
#endif
	default:
		client->_remoteAddress.family =
		    OF_SOCKET_ADDRESS_FAMILY_UNKNOWN;
		break;
	}

	return client;
}

- (void)asyncAcceptWithTarget: (id)target
		     selector: (SEL)selector
		      context: (id)context
{
	[self asyncAcceptWithRunLoopMode: of_run_loop_mode_default
				  target: target
				selector: selector
				 context: context];
}

- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
			    target: (id)target
			  selector: (SEL)selector
			   context: (id)context
{
	[OFRunLoop of_addAsyncAcceptForTCPSocket: self
					    mode: runLoopMode
					  target: target
					selector: selector
					 context: context];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncAcceptWithBlock: (of_tcp_socket_async_accept_block_t)block
{
	[self asyncAcceptWithRunLoopMode: of_run_loop_mode_default
				   block: block];
}

- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
			     block: (of_tcp_socket_async_accept_block_t)block
{
	[OFRunLoop of_addAsyncAcceptForTCPSocket: self
					    mode: runLoopMode
					   block: block];
}
#endif

- (const of_socket_address_t *)remoteAddress
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_remoteAddress.length == 0)
		@throw [OFInvalidArgumentException exception];

	if (_remoteAddress.length > (socklen_t)sizeof(_remoteAddress.sockaddr))
		@throw [OFOutOfRangeException exception];

	return &_remoteAddress;
}

- (bool)isListening
{
	return _listening;
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
		    exceptionWithStream: self
				  errNo: of_socket_errno()];

	return v;
}
#endif

#ifndef OF_WII
- (void)setTCPNoDelayEnabled: (bool)enabled
{
	int v = enabled;

	if (setsockopt(_socket, IPPROTO_TCP, TCP_NODELAY,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: of_socket_errno()];
}

- (bool)isTCPNoDelayEnabled
{
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, IPPROTO_TCP, TCP_NODELAY,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithStream: self
				  errNo: of_socket_errno()];

	return v;
}
#endif

- (void)close
{
	_listening = false;

	memset(&_remoteAddress, 0, sizeof(_remoteAddress));

#ifdef OF_WII
	_port = 0;
#endif

	[super close];
}
@end
