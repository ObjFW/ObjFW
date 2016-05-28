/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#include <fcntl.h>

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
#import "OFGetOptionFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFListenFailedException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFSetOptionFailedException.h"

#import "socket.h"
#import "socket_helpers.h"
#import "resolver.h"

/* References for static linking */
void
_references_to_categories_of_OFTCPSocket(void)
{
	_OFTCPSocket_SOCKS5_reference = 1;
}

Class of_tls_socket_class = Nil;

static OFString *defaultSOCKS5Host = nil;
static uint16_t defaultSOCKS5Port = 1080;

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
@synthesize SOCKS5Host = _SOCKS5Host, SOCKS5Port = _SOCKS5Port;

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

- (void)connectToHost: (OFString*)host
		 port: (uint16_t)port
{
	OFString *destinationHost = host;
	uint16_t destinationPort = port;
	of_resolver_result_t **results, **iter;
	int errNo = 0;

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	_listening = false;

	/* Make sure to clear the read buffer in case the socket is reused */
	[self freeMemory: _readBuffer];
	_readBuffer = NULL;
	_readBufferLength = 0;

	if (_SOCKS5Host != nil) {
		/* Connect to the SOCKS5 proxy instead */
		host = _SOCKS5Host;
		port = _SOCKS5Port;
	}

	results = of_resolve_host(host, port, SOCK_STREAM);

	for (iter = results; *iter != NULL; iter++) {
		of_resolver_result_t *result = *iter;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
		int flags;
#endif

		if ((_socket = socket(result->family,
		    result->type | SOCK_CLOEXEC,
		    result->protocol)) == INVALID_SOCKET) {
			errNo = of_socket_errno();

			continue;
		}

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
		if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
			fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

		if (connect(_socket, result->address,
		    result->addressLength) == -1) {
			errNo = of_socket_errno();

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
							       socket: self
								errNo: errNo];

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
#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	union {
		struct sockaddr_storage storage;
		struct sockaddr_in in;
# ifdef HAVE_IPV6
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

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
		if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
			fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

		setsockopt(_socket, SOL_SOCKET, SO_REUSEADDR,
		    (const char*)&one, (socklen_t)sizeof(one));

#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
		if (port != 0) {
#endif
			if (bind(_socket, results[0]->address,
			    results[0]->addressLength) != 0) {
				int errNo = of_socket_errno();

				close(_socket);
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
					((struct sockaddr_in*)
					    results[0]->address)->sin_port =
					    OF_BSWAP16_IF_LE(rnd);
					break;
# ifdef HAVE_IPV6
				case AF_INET6:
					((struct sockaddr_in6*)
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

					close(_socket);
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
	addrLen = (socklen_t)sizeof(addr.storage);
	if (of_getsockname(_socket, (struct sockaddr*)&addr.storage,
	    &addrLen) != 0) {
		int errNo = of_socket_errno();

		close(_socket);
		_socket = INVALID_SOCKET;

		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: errNo];
	}

	if (addr.storage.ss_family == AF_INET)
		return OF_BSWAP16_IF_LE(addr.in.sin_port);
# ifdef HAVE_IPV6
	if (addr.storage.ss_family == AF_INET6)
		return OF_BSWAP16_IF_LE(addr.in6.sin6_port);
# endif
#endif

	close(_socket);
	_socket = INVALID_SOCKET;
	@throw [OFBindFailedException exceptionWithHost: host
						   port: port
						 socket: self
						  errNo: EAFNOSUPPORT];
}

- (void)listen
{
	[self listenWithBackLog: SOMAXCONN];
}

- (void)listenWithBackLog: (int)backLog
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (listen(_socket, backLog) == -1)
		@throw [OFListenFailedException
		    exceptionWithSocket: self
				backLog: backLog
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

	client->_address = [client
	    allocMemoryWithSize: sizeof(struct sockaddr_storage)];
	client->_addressLength = (socklen_t)sizeof(struct sockaddr_storage);

#if defined(HAVE_PACCEPT) && defined(SOCK_CLOEXEC)
	if ((client->_socket = paccept(_socket, client->_address,
	   &client->_addressLength, NULL, SOCK_CLOEXEC)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];
#elif defined(HAVE_ACCEPT4) && defined(SOCK_CLOEXEC)
	if ((client->_socket = accept4(_socket, client->_address,
	   &client->_addressLength, SOCK_CLOEXEC)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];
#else
	if ((client->_socket = accept(_socket, client->_address,
	   &client->_addressLength)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];

# if defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(client->_socket, F_GETFD, 0)) != -1)
		fcntl(client->_socket, F_SETFD, flags | FD_CLOEXEC);
# endif
#endif

	assert(client->_addressLength <=
	    (socklen_t)sizeof(struct sockaddr_storage));

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

- (OFString*)remoteAddress
{
	OFString *ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_address == NULL)
		@throw [OFInvalidArgumentException exception];

	of_address_to_string_and_port(_address, _addressLength, &ret, NULL);

	return ret;
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
	    (char*)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithStream: self
				  errNo: of_socket_errno()];
}

- (bool)isKeepAliveEnabled
{
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, SOL_SOCKET, SO_KEEPALIVE,
	    (char*)&v, &len) != 0 || len != sizeof(v))
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
	    (char*)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithStream: self
				  errNo: of_socket_errno()];
}

- (bool)isTCPNoDelayEnabled
{
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, IPPROTO_TCP, TCP_NODELAY,
	    (char*)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithStream: self
				  errNo: of_socket_errno()];

	return v;
}
#endif
@end
