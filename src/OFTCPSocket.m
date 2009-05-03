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
+ initialize
{
	WSADATA wsa;

	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		@throw [OFInitializationFailedException newWithClass: self];

	return self;
}
#endif

- init
{
	self = [super init];

	sock = INVALID_SOCKET;
	saddr = NULL;
	saddr_len = 0;

	return self;
}

- free
{
	if (sock != INVALID_SOCKET)
		close(sock);

	return [super free];
}

- connectTo: (const char*)host
     onPort: (uint16_t)port
{
	struct addrinfo hints, *res, *res0;
	char portstr[6];

	if (!port)
		@throw [OFInvalidPortException newWithClass: isa];

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: isa];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	snprintf(portstr, 6, "%d", port);

	if (getaddrinfo(host, portstr, &hints, &res0))
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
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
		@throw [OFConnectionFailedException newWithClass: isa
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
		@throw [OFInvalidPortException newWithClass: isa];

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: isa];

	if ((sock = socket(family, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException newWithClass: isa
						   andHost: host
						   andPort: port
						 andFamily: family];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = family;
	hints.ai_socktype = SOCK_STREAM;

	snprintf(portstr, 6, "%d", port);

	if (getaddrinfo(host, portstr, &hints, &res))
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			 andNode: host
		      andService: portstr];

	if (bind(sock, res->ai_addr, res->ai_addrlen) == -1) {
		freeaddrinfo(res);
		@throw [OFBindFailedException newWithClass: isa
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
		@throw [OFNotConnectedException newWithClass: isa];

	if (listen(sock, backlog) == -1)
		@throw [OFListenFailedException newWithClass: isa
						  andBackLog: backlog];

	return self;
}

- listen
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	if (listen(sock, 5) == -1)
		@throw [OFListenFailedException newWithClass: isa
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
		addr = [newsock allocWithSize: sizeof(struct sockaddr)];
	} @catch (OFException *e) {
		[newsock free];
		@throw e;
	}

	if ((s = accept(sock, addr, &addrlen)) == INVALID_SOCKET) {
		[newsock free];
		@throw [OFAcceptFailedException newWithClass: isa];
	}

	newsock->sock = s;
	newsock->saddr = addr;
	newsock->saddr_len = addrlen;

	return newsock;
}

- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf
{
	ssize_t ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	switch ((ret = recv(sock, buf, size, 0))) {
	case 0:
		@throw [OFNotConnectedException newWithClass: isa];
	case -1:
		@throw [OFReadFailedException newWithClass: isa
						   andSize: size];
	}

	/* This is safe, as we already checked < 1 */
	return ret;
}

- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf
{
	ssize_t ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	if ((ret = send(sock, buf, size, 0)) == -1)
		@throw [OFWriteFailedException newWithClass: isa
						    andSize: size];

	/* This is safe, as we already checked for -1 */
	return ret;
}

- (size_t)writeCString: (const char*)str
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	return [self writeNBytes: strlen(str)
		      fromBuffer: str];
}

- setBlocking: (BOOL)enable
{
#ifndef _WIN32
	int flags;

	if ((flags = fcntl(sock, F_GETFL)) == -1)
		@throw [OFSetOptionFailedException newWithClass: isa];

	if (enable)
		flags &= ~O_NONBLOCK;
	else
		flags |= O_NONBLOCK;

	if (fcntl(sock, F_SETFL, flags) == -1)
		@throw [OFSetOptionFailedException newWithClass: isa];
#else
	u_long v = enable;

	if (ioctlsocket(sock, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException newWithClass: isa];
#endif

	return self;
}

- enableKeepAlives: (BOOL)enable
{
	int v = enable;

	if (setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, (char*)&v, sizeof(v)))
		@throw [OFSetOptionFailedException newWithClass: isa];

	return self;
}

- close
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	sock = INVALID_SOCKET;

	if (saddr != NULL)
		[self freeMem: saddr];
	saddr_len = 0;

	return self;
}
@end
