/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#define _WIN32_WINNT 0x0501
#define __NO_EXT_QNX

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

#import "OFTCPSocket.h"
#import "OFTCPSocket+SOCKS5.h"
#import "OFString.h"
#import "OFThread.h"
#import "OFTimer.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"

#import "OFAcceptFailedException.h"
#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"
#import "OFConnectionFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFListenFailedException.h"
#import "OFNotConnectedException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfMemoryException.h"
#import "OFSetOptionFailedException.h"

#import "autorelease.h"
#import "macros.h"
#import "resolver.h"
#import "socket_helpers.h"

/* References for static linking */
void _references_to_categories_of_OFTCPSocket(void)
{
	_OFTCPSocket_SOCKS5_reference = 1;
}

Class of_tls_socket_class = Nil;

static OFString *defaultSOCKS5Host = nil;
static uint16_t defaultSOCKS5Port = 1080;

#ifdef __wii__
static uint16_t freePort = 65532;
#endif

#ifdef OF_HAVE_THREADS
@interface OFTCPSocket_ConnectThread: OFThread
{
	OFThread *_sourceThread;
	OFTCPSocket *_socket;
	OFString *_host;
	uint16_t _port;
	id _target;
	SEL _selector;
# ifdef OF_HAVE_BLOCKS
	of_tcp_socket_async_connect_block_t _block;
# endif
	OFException *_exception;
}

- initWithSourceThread: (OFThread*)sourceThread
		socket: (OFTCPSocket*)socket
		  host: (OFString*)host
		  port: (uint16_t)port
		target: (id)target
	      selector: (SEL)selector;
# ifdef OF_HAVE_BLOCKS
- initWithSourceThread: (OFThread*)sourceThread
		socket: (OFTCPSocket*)socket
		  host: (OFString*)host
		  port: (uint16_t)port
		 block: (of_tcp_socket_async_connect_block_t)block;
# endif
@end

@implementation OFTCPSocket_ConnectThread
- initWithSourceThread: (OFThread*)sourceThread
		socket: (OFTCPSocket*)socket
		  host: (OFString*)host
		  port: (uint16_t)port
		target: (id)target
	      selector: (SEL)selector
{
	self = [super init];

	@try {
		_sourceThread = [sourceThread retain];
		_socket = [socket retain];
		_host = [host copy];
		_port = port;
		_target = [target retain];
		_selector = selector;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

# ifdef OF_HAVE_BLOCKS
- initWithSourceThread: (OFThread*)sourceThread
		socket: (OFTCPSocket*)socket
		  host: (OFString*)host
		  port: (uint16_t)port
		 block: (of_tcp_socket_async_connect_block_t)block
{
	self = [super init];

	@try {
		_sourceThread = [sourceThread retain];
		_socket = [socket retain];
		_host = [host copy];
		_port = port;
		_block = [block copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
# endif

- (void)dealloc
{
	[_sourceThread release];
	[_socket release];
	[_host release];
	[_target release];
# ifdef OF_HAVE_BLOCKS
	[_block release];
# endif
	[_exception release];

	[super dealloc];
}

- (void)didConnect
{
	[self join];

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block(_socket, _exception);
	else {
# endif
		void (*func)(id, SEL, OFTCPSocket*, OFException*) =
		    (void(*)(id, SEL, OFTCPSocket*, OFException*))[_target
		    methodForSelector: _selector];

		func(_target, _selector, _socket, _exception);
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (id)main
{
	void *pool = objc_autoreleasePoolPush();

	@try {
		[_socket connectToHost: _host
				  port: _port];
	} @catch (OFException *e) {
		_exception = e;
	}

	[self performSelector: @selector(didConnect)
		     onThread: _sourceThread
		waitUntilDone: false];

	objc_autoreleasePoolPop(pool);

	return nil;
}
@end
#endif

@implementation OFTCPSocket
+ (void)setSOCKS5Host: (OFString*)host
{
	id old = defaultSOCKS5Host;
	defaultSOCKS5Host = [host copy];
	[old release];
}

+ (OFString*)SOCKS5Host
{
	return [[defaultSOCKS5Host copy] autorelease];
}

+ (void)setSOCKS5Port: (uint16_t)port
{
	defaultSOCKS5Port = port;
}

+ (uint16_t)SOCKS5Port
{
	return defaultSOCKS5Port;
}

- init
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

- (void)setSOCKS5Host: (OFString*)SOCKS5Host
{
	OF_SETTER(_SOCKS5Host, SOCKS5Host, true, 1)
}

- (OFString*)SOCKS5Host
{
	OF_GETTER(_SOCKS5Host, true)
}

- (void)setSOCKS5Port: (uint16_t)SOCKS5Port
{
	_SOCKS5Port = SOCKS5Port;
}

- (uint16_t)SOCKS5Port
{
	return _SOCKS5Port;
}

- (void)connectToHost: (OFString*)host
		 port: (uint16_t)port
{
	OFString *destinationHost = host;
	uint16_t destinationPort = port;
	of_resolver_result_t **results, **iter;

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	if (_SOCKS5Host != nil) {
		/* Connect to the SOCKS5 proxy instead */
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	}

	results = of_resolve_host(host, port, SOCK_STREAM);

	for (iter = results; *iter != NULL; iter++) {
		of_resolver_result_t *result = *iter;

		if ((_socket = socket(result->family, result->type,
		    result->protocol)) == INVALID_SOCKET)
			continue;

		if (connect(_socket, result->address,
		    result->addressLength) == -1) {
			close(_socket);
			_socket = INVALID_SOCKET;
			continue;
		}

		break;
	}

	of_resolver_free(results);

	if (_socket == INVALID_SOCKET)
		@throw [OFConnectionFailedException exceptionWithHost: host
								 port: port
							       socket: self];

	if (_SOCKS5Host != nil)
		[self OF_SOCKS5ConnectToHost: destinationHost
					port: destinationPort];
}

#ifdef OF_HAVE_THREADS
- (void)asyncConnectToHost: (OFString*)host
		      port: (uint16_t)port
		    target: (id)target
		  selector: (SEL)selector
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFTCPSocket_ConnectThread alloc]
	    initWithSourceThread: [OFThread currentThread]
			  socket: self
			    host: host
			    port: port
			  target: target
			selector: selector] autorelease] start];

	objc_autoreleasePoolPop(pool);
}

# ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToHost: (OFString*)host
		      port: (uint16_t)port
		     block: (of_tcp_socket_async_connect_block_t)block
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFTCPSocket_ConnectThread alloc]
	    initWithSourceThread: [OFThread currentThread]
			  socket: self
			    host: host
			    port: port
			   block: block] autorelease] start];

	objc_autoreleasePoolPop(pool);
}
# endif
#endif

- (uint16_t)bindToHost: (OFString*)host
		  port: (uint16_t)port
{
	of_resolver_result_t **results;
	const int one = 1;
#ifndef __wii__
	union {
		struct sockaddr_storage storage;
		struct sockaddr_in in;
# ifdef AF_INET6
		struct sockaddr_in6 in6;
# endif
	} addr;
	socklen_t addrLen;
#endif

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	if (_SOCKS5Host != nil)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

#ifdef __wii__
	if (port == 0)
		port = freePort--;
#endif

	results = of_resolve_host(host, port, SOCK_STREAM);
	@try {
		if ((_socket = socket(results[0]->family, results[0]->type,
		    results[0]->protocol)) == INVALID_SOCKET)
			@throw [OFBindFailedException exceptionWithHost: host
								   port: port
								 socket: self];

		if (setsockopt(_socket, SOL_SOCKET, SO_REUSEADDR,
		    (const char*)&one, sizeof(one)))
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self];

		if (bind(_socket, results[0]->address,
		    results[0]->addressLength) == -1) {
			close(_socket);
			_socket = INVALID_SOCKET;
			@throw [OFBindFailedException exceptionWithHost: host
								   port: port
								 socket: self];
		}
	} @finally {
		of_resolver_free(results);
	}

	if (port > 0)
		return port;

#ifndef __wii__
	addrLen = sizeof(addr.storage);
	if (getsockname(_socket, (struct sockaddr*)&addr.storage, &addrLen)) {
		close(_socket);
		_socket = INVALID_SOCKET;
		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self];
	}

	if (addr.storage.ss_family == AF_INET)
		return OF_BSWAP16_IF_LE(addr.in.sin_port);
# ifdef AF_INET6
	if (addr.storage.ss_family == AF_INET6)
		return OF_BSWAP16_IF_LE(addr.in6.sin6_port);
# endif
#endif

	close(_socket);
	_socket = INVALID_SOCKET;
	@throw [OFBindFailedException exceptionWithHost: host
						   port: port
						 socket: self];
}

- (void)listen
{
	[self listenWithBackLog: SOMAXCONN];
}

- (void)listenWithBackLog: (int)backLog
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithSocket: self];

	if (listen(_socket, backLog) == -1)
		@throw [OFListenFailedException exceptionWithSocket: self
							    backLog: backLog];

	_listening = true;
}

- (instancetype)accept
{
	OFTCPSocket *client = [[[[self class] alloc] init] autorelease];

	client->_address = [client
	    allocMemoryWithSize: sizeof(struct sockaddr_storage)];
	client->_addressLength = sizeof(struct sockaddr_storage);

	if ((client->_socket = accept(_socket, client->_address,
	   &client->_addressLength)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException exceptionWithSocket: self];

	assert(client->_addressLength <= sizeof(struct sockaddr_storage));

	if (client->_addressLength != sizeof(struct sockaddr_storage)) {
		@try {
			client->_address = [client
			    resizeMemory: client->_address
				    size: client->_addressLength];
		} @catch (OFOutOfMemoryException *e) {
			/* We don't care, as we only made it smaller */
		}
	}

	return client;
}

- (void)asyncAcceptWithTarget: (id)target
		     selector: (SEL)selector
{
	[OFRunLoop OF_addAsyncAcceptForTCPSocket: self
					  target: target
					selector: selector];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncAcceptWithBlock: (of_tcp_socket_async_accept_block_t)block
{
	[OFRunLoop OF_addAsyncAcceptForTCPSocket: self
					   block: block];
}
#endif

- (void)setKeepAlivesEnabled: (bool)enable
{
	int v = enable;

	if (setsockopt(_socket, SOL_SOCKET, SO_KEEPALIVE, (char*)&v, sizeof(v)))
		@throw [OFSetOptionFailedException exceptionWithStream: self];
}

- (OFString*)remoteAddress
{
	OFString *ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithSocket: self];

	if (_address == NULL)
		@throw [OFInvalidArgumentException exception];

	of_address_to_string_and_port(_address, _addressLength, &ret, NULL);

	return ret;
}

- (bool)isListening
{
	return _listening;
}

- (void)close
{
	[super close];

	_listening = false;
}
@end
