/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && !defined(_WIN32)
#include <netinet/in.h>
#endif

#import "OFTCPSocket.h"
#import "OFString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#ifndef INVALID_SOCKET
#define INVALID_SOCKET -1
#endif

#if defined(OF_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
#import "OFThread.h"

static OFMutex *mutex = nil;
#endif

@implementation OFTCPSocket
#if defined(OF_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
+ (void)initialize
{
	if (self == [OFTCPSocket class])
		mutex = [[OFMutex alloc] init];
}
#endif

- (void)dealloc
{
	if (sock != INVALID_SOCKET)
		close(sock);

	[super dealloc];
}

- connectToService: (OFString*)service
	    onNode: (OFString*)node
{
	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: isa];

#ifdef HAVE_THREADSAFE_GETADDRINFO
	struct addrinfo hints, *res, *res0;

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	if (getaddrinfo([node cString], [service cString], &hints, &res0))
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];

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
#else
	BOOL connected = NO;
	struct hostent *he;
	struct servent *se;
	struct sockaddr_in addr;
	uint16_t port;
	char **ip;
#ifdef OF_THREADS
	OFDataArray *addrlist;

	addrlist = [[OFDataArray alloc] initWithItemSize: sizeof(char**)];
	[mutex lock];
#endif

	if ((he = gethostbyname([node cString])) == NULL) {
#ifdef OF_THREADS
		[addrlist release];
		[mutex unlock];
#endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

	if ((se = getservbyname([service cString], "TCP")) != NULL)
		port = se->s_port;
	else if ((port = OF_BSWAP16_IF_LE(strtol([service cString], NULL,
	    10))) == 0) {
#ifdef OF_THREADS
		[addrlist release];
		[mutex unlock];
#endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = port;

	if (he->h_addrtype != AF_INET ||
	    (sock = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) {
#ifdef OF_THREADS
		[addrlist release];
		[mutex unlock];
#endif
		@throw [OFConnectionFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

#ifdef OF_THREADS
	@try {
		for (ip = he->h_addr_list; *ip != NULL; ip++)
			[addrlist addItem: ip];

		/* Add the terminating NULL */
		[addrlist addItem: ip];
	} @catch (OFException *e) {
		[addrlist release];
		@throw e;
	} @finally {
		[mutex unlock];
	}

	for (ip = [addrlist cArray]; *ip != NULL; ip++) {
#else
	for (ip = he->h_addr_list; *ip != NULL; ip++) {
#endif
		memcpy(&addr.sin_addr.s_addr, *ip, he->h_length);

		if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) == -1)
			continue;

		connected = YES;
		break;
	}

#ifdef OF_THREADS
	[addrlist release];
#endif

	if (!connected) {
		close(sock);
		sock = INVALID_SOCKET;
	}
#endif

	if (sock == INVALID_SOCKET)
		@throw [OFConnectionFailedException newWithClass: isa
							    node: node
							 service: service];

	return self;
}

- bindService: (OFString*)service
       onNode: (OFString*)node
   withFamily: (int)family
{
	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: isa];

	if ((sock = socket(family, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service
						    family: family];

#ifdef HAVE_THREADSAFE_GETADDRINFO
	struct addrinfo hints, *res;

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = family;
	hints.ai_socktype = SOCK_STREAM;

	if (getaddrinfo([node cString], [service cString], &hints, &res))
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];

	if (bind(sock, res->ai_addr, res->ai_addrlen) == -1) {
		freeaddrinfo(res);
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service
						    family: family];
	}

	freeaddrinfo(res);
#else
	struct hostent *he;
	struct servent *se;
	struct sockaddr_in addr;
	uint16_t port;

	if (family != AF_INET)
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service
						    family: family];

#ifdef OF_THREADS
	[mutex lock];
#endif

	if ((he = gethostbyname([node cString])) == NULL) {
#ifdef OF_THREADS
		[mutex unlock];
#endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

	if ((se = getservbyname([service cString], "TCP")) != NULL)
		port = se->s_port;
	else if ((port = OF_BSWAP16_IF_LE(strtol([service cString], NULL,
	    10))) == 0) {
#ifdef OF_THREADS
		[mutex unlock];
#endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = port;

	if (he->h_addrtype != AF_INET || he->h_addr_list[0] == NULL) {
#ifdef OF_THREADS
		[mutex unlock];
#endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

	memcpy(&addr.sin_addr.s_addr, he->h_addr_list[0], he->h_length);

#ifdef OF_THREADS
	[mutex unlock];
#endif

	if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) == -1)
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service
						    family: family];
#endif

	return self;
}

- listenWithBackLog: (int)backlog
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	if (listen(sock, backlog) == -1)
		@throw [OFListenFailedException newWithClass: isa
						     backLog: backlog];

	return self;
}

- listen
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	if (listen(sock, 5) == -1)
		@throw [OFListenFailedException newWithClass: isa
						     backLog: 5];

	return self;
}

- (OFTCPSocket*)accept
{
	OFTCPSocket *newsock;
	struct sockaddr *addr;
	socklen_t addrlen;
	int s;

	newsock = [OFTCPSocket socket];
	addrlen = sizeof(struct sockaddr);

	@try {
		addr = [newsock allocMemoryWithSize: sizeof(struct sockaddr)];
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

	[self freeMemory: saddr];
	sock = INVALID_SOCKET;
	saddr = NULL;
	saddr_len = 0;

	return self;
}
@end
