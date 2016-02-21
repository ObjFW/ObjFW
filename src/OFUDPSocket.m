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

#include "config.h"

#include <assert.h>
#include <errno.h>
#include <string.h>

#include <fcntl.h>

#import "OFUDPSocket.h"
#ifdef OF_HAVE_THREADS
# import "OFThread.h"
#endif
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"

#import "OFBindFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#import "socket.h"
#import "socket_helpers.h"
#import "resolver.h"

#ifdef OF_HAVE_THREADS
@interface OFUDPSocket_ResolveThread: OFThread
{
	OFThread *_sourceThread;
	OFString *_host;
	uint16_t _port;
	id _target;
	SEL _selector;
# ifdef OF_HAVE_BLOCKS
	of_udp_socket_async_resolve_block_t _block;
# endif
	of_udp_socket_address_t _address;
	OFException *_exception;
}

- initWithSourceThread: (OFThread*)sourceThread
		  host: (OFString*)host
		  port: (uint16_t)port
		target: (id)target
	      selector: (SEL)selector;
# ifdef OF_HAVE_BLOCKS
- initWithSourceThread: (OFThread*)sourceThread
		  host: (OFString*)host
		  port: (uint16_t)port
		 block: (of_udp_socket_async_resolve_block_t)block;
# endif
@end

@implementation OFUDPSocket_ResolveThread
- initWithSourceThread: (OFThread*)sourceThread
		  host: (OFString*)host
		  port: (uint16_t)port
		target: (id)target
	      selector: (SEL)selector
{
	self = [super init];

	@try {
		_sourceThread = [sourceThread retain];
		_host = [host retain];
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
		  host: (OFString*)host
		  port: (uint16_t)port
		 block: (of_udp_socket_async_resolve_block_t)block
{
	self = [super init];

	@try {
		_sourceThread = [sourceThread retain];
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
	[_host release];
	[_target release];
# ifdef OF_HAVE_BLOCKS
	[_block release];
# endif
	[_exception release];

	[super dealloc];
}

- (void)didResolve
{
	[self join];

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block(_host, _port, _address, _exception);
	else {
# endif
		void (*func)(id, SEL, OFString*, uint16_t,
		    of_udp_socket_address_t, OFException*) =
		    (void(*)(id, SEL, OFString*, uint16_t,
		    of_udp_socket_address_t, OFException*))[_target
		    methodForSelector: _selector];

		func(_target, _selector, _host, _port, _address, _exception);
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (id)main
{
	void *pool = objc_autoreleasePoolPush();

	@try {
		[OFUDPSocket resolveAddressForHost: _host
					      port: _port
					   address: &_address];
	} @catch (OFException *e) {
		_exception = e;
	}

	[self performSelector: @selector(didResolve)
		     onThread: _sourceThread
		waitUntilDone: false];

	objc_autoreleasePoolPop(pool);

	return nil;
}
@end
#endif

bool
of_udp_socket_address_equal(of_udp_socket_address_t *address1,
    of_udp_socket_address_t *address2)
{
	struct sockaddr_in *sin_1, *sin_2;
#ifdef AF_INET6
	struct sockaddr_in6 *sin6_1, *sin6_2;
#endif

	if (address1->address.ss_family != address2->address.ss_family)
		return false;

	switch (address1->address.ss_family) {
	case AF_INET:
#ifndef OF_WII
		if (address1->length < sizeof(struct sockaddr_in) ||
		    address2->length < sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];
#else
		if (address1->length < 8 || address2->length < 8)
			@throw [OFInvalidArgumentException exception];
#endif

		sin_1 = (struct sockaddr_in*)&address1->address;
		sin_2 = (struct sockaddr_in*)&address2->address;

		if (sin_1->sin_port != sin_2->sin_port)
			return false;
		if (sin_1->sin_addr.s_addr != sin_2->sin_addr.s_addr)
			return false;

		break;
#ifdef AF_INET6
	case AF_INET6:
		if (address1->length < sizeof(struct sockaddr_in6) ||
		    address2->length < sizeof(struct sockaddr_in6))
			@throw [OFInvalidArgumentException exception];

		sin6_1 = (struct sockaddr_in6*)&address1->address;
		sin6_2 = (struct sockaddr_in6*)&address2->address;

		if (sin6_1->sin6_port != sin6_2->sin6_port)
			return false;
		if (memcmp(sin6_1->sin6_addr.s6_addr,
		    sin6_2->sin6_addr.s6_addr,
		    sizeof(sin6_1->sin6_addr.s6_addr)) != 0)
			return false;

		break;
#endif
	default:
		@throw [OFInvalidArgumentException exception];
	}

	return true;
}

uint32_t
of_udp_socket_address_hash(of_udp_socket_address_t *address)
{
	uint32_t hash = of_hash_seed;
	struct sockaddr_in *sin;
#ifdef AF_INET6
	struct sockaddr_in6 *sin6;
	uint32_t subhash;
#endif

	hash += address->address.ss_family;

	switch (address->address.ss_family) {
	case AF_INET:
#ifndef OF_WII
		if (address->length < sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];
#else
		if (address->length < 8)
			@throw [OFInvalidArgumentException exception];
#endif

		sin = (struct sockaddr_in*)&address->address;

		hash += (sin->sin_port << 1);
		hash ^= sin->sin_addr.s_addr;

		break;
#ifdef AF_INET6
	case AF_INET6:
		if (address->length < sizeof(struct sockaddr_in6))
			@throw [OFInvalidArgumentException exception];

		sin6 = (struct sockaddr_in6*)&address->address;

		hash += (sin6->sin6_port << 1);

		OF_HASH_INIT(subhash);

		for (size_t i = 0; i < sizeof(sin6->sin6_addr.s6_addr); i++)
			OF_HASH_ADD(subhash, sin6->sin6_addr.s6_addr[i]);

		OF_HASH_FINALIZE(subhash);

		hash ^= subhash;

		break;
#endif
	default:
		@throw [OFInvalidArgumentException exception];
	}

	return hash;
}

@implementation OFUDPSocket
+ (void)initialize
{
	if (self != [OFUDPSocket class])
		return;

	if (!of_socket_init())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

+ (void)resolveAddressForHost: (OFString*)host
			 port: (uint16_t)port
		      address: (of_udp_socket_address_t*)address
{
	of_resolver_result_t **results =
	    of_resolve_host(host, port, SOCK_DGRAM);

	assert(results[0]->addressLength <= sizeof(address->address));

	memcpy(&address->address, results[0]->address,
	    results[0]->addressLength);
	address->length = results[0]->addressLength;

	of_resolver_free(results);
}

#ifdef OF_HAVE_THREADS
+ (void)asyncResolveAddressForHost: (OFString*)host
			      port: (uint16_t)port
			    target: (id)target
			  selector: (SEL)selector
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFUDPSocket_ResolveThread alloc]
	    initWithSourceThread: [OFThread currentThread]
			    host: host
			    port: port
			  target: target
			selector: selector] autorelease] start];

	objc_autoreleasePoolPop(pool);
}

# ifdef OF_HAVE_BLOCKS
+ (void)asyncResolveAddressForHost: (OFString*)host
			      port: (uint16_t)port
			     block: (of_udp_socket_async_resolve_block_t)block
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFUDPSocket_ResolveThread alloc]
	    initWithSourceThread: [OFThread currentThread]
			    host: host
			    port: port
			   block: block] autorelease] start];

	objc_autoreleasePoolPop(pool);
}
# endif
#endif

+ (void)getHost: (OFString *__autoreleasing*)host
	andPort: (uint16_t*)port
     forAddress: (of_udp_socket_address_t*)address
{
	of_address_to_string_and_port(
	    (struct sockaddr*)&address->address, address->length, host, port);
}

- init
{
	self = [super init];

	_socket = INVALID_SOCKET;

	return self;
}

- (void)dealloc
{
	if (_socket != INVALID_SOCKET)
		[self close];

	[super dealloc];
}

- copy
{
	return [self retain];
}

- (uint16_t)bindToHost: (OFString*)host
		  port: (uint16_t)port
{
	of_resolver_result_t **results;
#ifndef OF_WII
	union {
		struct sockaddr_storage storage;
		struct sockaddr_in in;
# ifdef AF_INET6
		struct sockaddr_in6 in6;
# endif
	} addr;
	socklen_t addrLen;
#endif

#ifdef OF_WII
	if (port == 0)
		port = of_socket_port_find(SOCK_DGRAM);
	else if (!of_socket_port_register(port, SOCK_DGRAM))
		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: EADDRINUSE];
#endif

	@try {
		results = of_resolve_host(host, port, SOCK_DGRAM);
	} @catch (id e) {
#ifdef OF_WII
		of_socket_port_free(port, SOCK_DGRAM);
#endif
		@throw e;
	}

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

		if (bind(_socket, results[0]->address,
		    results[0]->addressLength) == -1) {
			int errNo = of_socket_errno();

			close(_socket);
			_socket = INVALID_SOCKET;

			@throw [OFBindFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
		}
	} @catch (id e) {
#ifdef OF_WII
		of_socket_port_free(port, SOCK_DGRAM);
#endif
		@throw e;
	} @finally {
		of_resolver_free(results);
	}

	if (port > 0) {
#ifdef OF_WII
		_port = port;
#endif
		return port;
	}

#ifndef OF_WII
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
# ifdef AF_INET6
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

- (size_t)receiveIntoBuffer: (void*)buffer
		     length: (size_t)length
		     sender: (of_udp_socket_address_t*)sender
{
	ssize_t ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	sender->length = (socklen_t)sizeof(sender->address);

#ifndef OF_WINDOWS
	if ((ret = recvfrom(_socket, buffer, length, 0,
	    (struct sockaddr*)&sender->address, &sender->length)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = recvfrom(_socket, buffer, (int)length, 0,
	    (struct sockaddr*)&sender->address, &sender->length)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#endif

	return ret;
}

- (void)asyncReceiveIntoBuffer: (void*)buffer
			length: (size_t)length
			target: (id)target
		      selector: (SEL)selector
{
	[OFRunLoop OF_addAsyncReceiveForUDPSocket: self
					   buffer: buffer
					   length: length
					   target: target
					 selector: selector];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncReceiveIntoBuffer: (void*)buffer
			length: (size_t)length
			 block: (of_udp_socket_async_receive_block_t)block
{
	[OFRunLoop OF_addAsyncReceiveForUDPSocket: self
					   buffer: buffer
					   length: length
					    block: block];
}
#endif

- (void)sendBuffer: (const void*)buffer
	    length: (size_t)length
	  receiver: (const of_udp_socket_address_t*)receiver
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (sendto(_socket, buffer, length, 0,
	    (struct sockaddr*)&receiver->address,
	    receiver->length) != (ssize_t)length)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if (sendto(_socket, buffer, (int)length, 0,
	    (struct sockaddr*)&receiver->address,
	    receiver->length) != (int)length)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#endif
}

- (void)cancelAsyncRequests
{
	[OFRunLoop OF_cancelAsyncRequestsForObject: self];
}

- (int)fileDescriptorForReading
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (void)close
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	close(_socket);
	_socket = INVALID_SOCKET;

#ifdef OF_WII
	if (_port > 0) {
		of_socket_port_free(_port, SOCK_DGRAM);
		_port = 0;
	}
#endif
}
@end
