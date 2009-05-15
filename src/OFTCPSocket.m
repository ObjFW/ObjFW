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
#include <string.h>
#include <unistd.h>

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

- init
{
	self = [super init];

	sock = INVALID_SOCKET;
	saddr = NULL;

	return self;
}

- (void)dealloc
{
	if (sock != INVALID_SOCKET)
		close(sock);

	[super dealloc];
}

- connectToService: (OFString*)service
	    onNode: (OFString*)node
{
	struct addrinfo hints, *res, *res0;

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: isa];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	if (getaddrinfo([node cString], [service cString], &hints, &res0))
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			 andNode: node
		      andService: service];

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
							 andNode: node
						      andService: service];

	return self;
}

- bindService: (OFString*)service
       onNode: (OFString*)node
   withFamily: (int)family
{
	struct addrinfo hints, *res;

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: isa];

	if ((sock = socket(family, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException newWithClass: isa
						   andNode: node
						andService: service
						 andFamily: family];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = family;
	hints.ai_socktype = SOCK_STREAM;

	if (getaddrinfo([node cString], [service cString], &hints, &res))
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			 andNode: node
		      andService: service];

	if (bind(sock, res->ai_addr, res->ai_addrlen) == -1) {
		freeaddrinfo(res);
		@throw [OFBindFailedException newWithClass: isa
						   andNode: node
						andService: service
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

	newsock = [OFTCPSocket tcpSocket];
	addrlen = sizeof(struct sockaddr);

	@try {
		addr = [newsock allocWithSize: sizeof(struct sockaddr)];
	} @catch (OFException *e) {
		[newsock dealloc];
		@throw e;
	}

	if ((s = accept(sock, addr, &addrlen)) == INVALID_SOCKET) {
		[newsock dealloc];
		@throw [OFAcceptFailedException newWithClass: isa];
	}

	newsock->sock = s;
	newsock->saddr = addr;
	newsock->saddr_len = addrlen;

	return newsock;
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
