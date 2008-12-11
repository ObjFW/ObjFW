/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <unistd.h>

#import "OFTCPSocket.h"
#import "OFExceptions.h"

@implementation OFTCPSocket
- init
{
	if ((self = [super init])) {
		sock = -1;
		saddr = NULL;
		saddr_len = 0;
	}

	return self;
}

- free
{
	if (sock >= 0)
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

	if (!port) {
		/* FIXME: Throw exception */
		return nil;
	}

	if (sock >= 0)
		@throw [OFAlreadyConnectedException newWithObject: self];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	snprintf(portstr, 6, "%d", port);

	if (getaddrinfo(host, portstr, &hints, &res0)) {
		/* FIXME: Throw exception */
		return nil;
	}

	for (res = res0; res != NULL; res = res->ai_next) {
		if ((sock = socket(res->ai_family, res->ai_socktype,
		    res->ai_protocol)) < 0)
			continue;

		if (connect(sock, res->ai_addr, res->ai_addrlen) < 0) {
			close(sock);
			sock = -1;
			continue;
		}

		break;
	}
	
	freeaddrinfo(res0);

	if (sock < 0) {
		/* FIXME: Throw exception */
		return nil;
	}

	return self;
}

-    bindOn: (const char*)host
   withPort: (uint16_t)port
  andFamily: (int)family
{
	struct addrinfo hints, *res;
	char portstr[6];

	if (!port) {
		/* FIXME: Throw exception */
		return nil;
	}

	if (sock >= 0)
		@throw [OFAlreadyConnectedException newWithObject: self];

	if ((sock = socket(family, SOCK_STREAM, 0)) < 0) {
		/* FIXME: Throw exception */
		return nil;
	}

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = family;
	hints.ai_socktype = SOCK_STREAM;

	snprintf(portstr, 6, "%d", port);

	if (getaddrinfo(host, portstr, &hints, &res)) {
		/* FIXME: Throw exception */
		return nil;
	}

	if (bind(sock, res->ai_addr, res->ai_addrlen) < 0) {
		/* FIXME: Throw exception */
		freeaddrinfo(res);
		return nil;
	}

	freeaddrinfo(res);

	return self;
}

- listenWithBackLog: (int)backlog
{
	if (sock < 0)
		@throw [OFNotConnectedException newWithObject: self];

	if (listen(sock, backlog) < 0 ) {
		/* FIXME: Throw exception */
		return nil;
	}

	return self;
}

- listen
{
	if (sock < 0)
		@throw [OFNotConnectedException newWithObject: self];

	if (listen(sock, 5) < 0 ) {
		/* FIXME: Throw exception */
		return nil;
	}

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

	if ((s = accept(sock, addr, &addrlen)) < 0) {
		/* FIXME: Throw exception */
		return nil;
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

	if (sock < 0) 
		@throw [OFNotConnectedException newWithObject: self];

	if ((ret = recv(sock, buf, size, 0)) < 0)
		@throw [OFReadFailedException newWithObject: self
						    andSize: size];

	/* This is safe, as we already checked < 0 */
	return ret;
}

- (uint8_t*)readNBytes: (size_t)size
{
	uint8_t *ret;

	if (sock < 0) 
		@throw [OFNotConnectedException newWithObject: self];

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

	if (sock < 0) 
		@throw [OFNotConnectedException newWithObject: self];

	if ((ret = send(sock, buf, size, 0)) < 0)
		@throw [OFWriteFailedException newWithObject: self
						     andSize: size];

	/* This is safe, as we already checked < 0 */
	return ret;
}

- (size_t)writeCString: (const char*)str
{
	if (sock < 0) 
		@throw [OFNotConnectedException newWithObject: self];

	return [self writeNBytes: strlen(str)
		      fromBuffer: (const uint8_t*)str];
}

- close
{
	if (sock < 0) 
		@throw [OFNotConnectedException newWithObject: self];

	sock = -1;

	if (saddr != NULL)
		[self freeMem: saddr];
	saddr_len = 0;

	return self;
}
@end
