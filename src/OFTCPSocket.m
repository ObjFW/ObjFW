/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#import "OFTCPSocket.h"
#import "OFExceptions.h"

#ifndef INVALID_SOCKET
#define INVALID_SOCKET -1
#endif

@implementation OFTCPSocket
+ tcpSocket
{
	return [[[OFTCPSocket alloc] init] autorelease];
}

#ifdef _WIN32
+ (void)initialize
{
	WSADATA wsa;

	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		@throw [OFInitializationFailedException newWithClass: self];
}
#endif

- init
{
	if ((self = [super init])) {
		sock = INVALID_SOCKET;
		saddr = NULL;
		saddr_len = 0;
	}

	return self;
}

- free
{
	if (sock != INVALID_SOCKET)
		close(sock);

	return [super free];
}

- setSocket: (int)socket
{
	sock = socket;

	return self;
}

- setSocketAddress: (struct sockaddr*)sockaddr
	withLength: (socklen_t)len
{
	saddr = sockaddr;
	saddr_len = len;

	return self;
}

- connectTo: (const char*)host
     onPort: (uint16_t)port
{
	struct addrinfo hints, *res, *res0;
	char portstr[6];

	if (!port)
		@throw [OFInvalidPortException newWithClass: [self class]];

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: [self class]];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	snprintf(portstr, 6, "%d", port);

	if (getaddrinfo(host, portstr, &hints, &res0))
		@throw [OFAddressTranslationFailedException
		    newWithClass: [self class]
			 andNode: host
		      andService: portstr];

	for (res = res0; res != NULL; res = res->ai_next) {
		if ((sock = socket(res->ai_family, res->ai_socktype,
		    res->ai_protocol)) == INVALID_SOCKET)
			continue;

		if (connect(sock, res->ai_addr, res->ai_addrlen) == -1) {
			close(sock);
			sock = INVALID_SOCKET;
			continue;
		}

		break;
	}

	freeaddrinfo(res0);

	if (sock == INVALID_SOCKET)
		@throw [OFConnectionFailedException newWithClass: [self class]
							 andHost: host
							 andPort: port];

	return self;
}

-    bindOn: (const char*)host
   withPort: (uint16_t)port
  andFamily: (int)family
{
	struct addrinfo hints, *res;
	char portstr[6];

	if (!port)
		@throw [OFInvalidPortException newWithClass: [self class]];

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: [self class]];

	if ((sock = socket(family, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException newWithClass: [self class]
						   andHost: host
						   andPort: port
						 andFamily: family];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = family;
	hints.ai_socktype = SOCK_STREAM;

	snprintf(portstr, 6, "%d", port);

	if (getaddrinfo(host, portstr, &hints, &res))
		@throw [OFAddressTranslationFailedException
		    newWithClass: [self class]
			 andNode: host
		      andService: portstr];

	if (bind(sock, res->ai_addr, res->ai_addrlen) == -1) {
		freeaddrinfo(res);
		@throw [OFBindFailedException newWithClass: [self class]
						   andHost: host
						   andPort: port
						 andFamily: family];
	}

	freeaddrinfo(res);

	return self;
}

- listenWithBackLog: (int)backlog
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: [self class]];

	if (listen(sock, backlog) == -1)
		@throw [OFListenFailedException newWithClass: [self class]
						  andBackLog: backlog];

	return self;
}

- listen
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: [self class]];

	if (listen(sock, 5) == -1)
		@throw [OFListenFailedException newWithClass: [self class]
						  andBackLog: 5];

	return self;
}

- (OFTCPSocket*)accept
{
	OFTCPSocket *newsock;
	struct sockaddr *addr;
	socklen_t addrlen;
	int s;

	newsock = [OFTCPSocket new];
	addrlen = sizeof(struct sockaddr);

	@try {
		addr = [newsock getMemWithSize: sizeof(struct sockaddr)];
	} @catch(id e) {
		[newsock free];
		@throw e;
	}

	if ((s = accept(sock, addr, &addrlen)) == INVALID_SOCKET) {
		[newsock free];
		@throw [OFAcceptFailedException newWithClass: [self class]];
	}

	[newsock setSocket: s];
	[newsock setSocketAddress: addr
		       withLength: addrlen];

	return newsock;
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (uint8_t*)buf
{
	ssize_t ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: [self class]];

	if ((ret = recv(sock, (char*)buf, size, 0)) < 1)
		@throw [OFReadFailedException newWithClass: [self class]
						   andSize: size];

	/* This is safe, as we already checked < 1 */
	return ret;
}

- (uint8_t*)readNBytes: (size_t)size
{
	uint8_t *ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: [self class]];

	ret = [self getMemWithSize: size];

	@try {
		[self readNBytes: size
		      intoBuffer: ret];
	} @catch (id exception) {
		[self freeMem: ret];
		@throw exception;
	}

	return ret;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const uint8_t*)buf
{
	ssize_t ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: [self class]];

	if ((ret = send(sock, (char*)buf, size, 0)) == -1)
		@throw [OFWriteFailedException newWithClass: [self class]
						    andSize: size];

	/* This is safe, as we already checked for -1 */
	return ret;
}

- (size_t)writeCString: (const char*)str
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: [self class]];

	return [self writeNBytes: strlen(str)
		      fromBuffer: (const uint8_t*)str];
}

- setBlocking: (BOOL)enable
{
#ifndef _WIN32
	int flags;

	if ((flags = fcntl(sock, F_GETFL)) == -1)
		@throw [OFSetOptionFailedException newWithClass: [self class]];

	if (enable)
		flags &= ~O_NONBLOCK;
	else
		flags |= O_NONBLOCK;

	if (fcntl(sock, F_SETFL, flags) == -1)
		@throw [OFSetOptionFailedException newWithClass: [self class]];
#else
	u_long v = enable;

	if (ioctlsocket(sock, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException newWithClass: [self class]];
#endif

	return self;
}

- enableKeepAlives: (BOOL)enable
{
	int v = enable;

	if (setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, (char*)&v, sizeof(v)))
		@throw [OFSetOptionFailedException newWithClass: [self class]];

	return self;
}

- close
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: [self class]];

	sock = INVALID_SOCKET;

	if (saddr != NULL)
		[self freeMem: saddr];
	saddr_len = 0;

	return self;
}
@end
