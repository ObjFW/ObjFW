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

#include <string.h>

#include <assert.h>

#import "OFUDPSocket.h"

#import "OFBindFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotConnectedException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#import "macros.h"
#import "resolver.h"
#import "socket_helpers.h"

#ifdef __wii__
static uint16_t freePort = 65532;
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
		if (address1->length < sizeof(struct sockaddr_in) ||
		    address2->length < sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];

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
		    sizeof(sin6_1->sin6_addr.s6_addr)))
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
	size_t i;
#endif

	hash += address->address.ss_family;

	switch (address->address.ss_family) {
	case AF_INET:
		if (address->length < sizeof(struct sockaddr_in))
			@throw [OFInvalidArgumentException exception];

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

		for (i = 0; i < sizeof(sin6->sin6_addr.s6_addr); i++)
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

+ (OFString*)hostForAddress: (of_udp_socket_address_t*)address
		       port: (uint16_t*)port
{
	return of_address_to_string_and_port(
	    (struct sockaddr*)&address->address, address->length, port);
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

- (uint16_t)bindToHost: (OFString*)host
		  port: (uint16_t)port
{
	of_resolver_result_t **results;
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

#ifdef __wii__
	if (port == 0)
		port = freePort--;
#endif

	results = of_resolve_host(host, port, SOCK_DGRAM);
	@try {
		if ((_socket = socket(results[0]->family, results[0]->type,
		    results[0]->protocol)) == INVALID_SOCKET)
			@throw [OFBindFailedException exceptionWithHost: host
								   port: port
								 socket: self];

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

- (size_t)receiveIntoBuffer: (void*)buffer
		     length: (size_t)length
		     sender: (of_udp_socket_address_t*)sender
{
	ssize_t ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithSocket: self];

	sender->length = sizeof(sender->address);

	if ((ret = recvfrom(_socket, buffer, length, 0,
	    (struct sockaddr*)&sender->address, &sender->length)) < 0)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

	return ret;
}

- (void)sendBuffer: (const void*)buffer
	    length: (size_t)length
	  receiver: (of_udp_socket_address_t*)receiver
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithSocket: self];

	if (sendto(_socket, buffer, length, 0,
	    (struct sockaddr*)&receiver->address, receiver->length) < length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length];
}

- (int)fileDescriptorForReading
{
	return _socket;
}

- (int)fileDescriptorForWriting
{
	return _socket;
}

- (void)close
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithSocket: self];

	close(_socket);
	_socket = INVALID_SOCKET;
}
@end
