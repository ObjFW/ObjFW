/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <assert.h>

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && !defined(_WIN32)
# include <netinet/in.h>
# include <arpa/inet.h>
# include <netdb.h>
#endif

#import "OFTCPSocket.h"
#import "OFString.h"
#import "OFExceptions.h"
#import "macros.h"

#ifndef INVALID_SOCKET
# define INVALID_SOCKET -1
#endif

#if defined(OF_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
# import "OFThread.h"
# import "OFDataArray.h"

static OFMutex *mutex = nil;
#endif

#ifdef _WIN32
# define close(sock) closesocket(sock)
#endif

@implementation OFTCPSocket
#if defined(OF_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
+ (void)initialize
{
	if (self == [OFTCPSocket class])
		mutex = [[OFMutex alloc] init];
}
#endif

- init
{
	self = [super init];

	sock = INVALID_SOCKET;
	sockAddr = NULL;

	return self;
}

- (void)connectToService: (OFString*)service
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
# ifndef _PSP
	struct servent *se;
# endif
	struct sockaddr_in addr;
	uint16_t port;
	char **ip;
# ifdef OF_THREADS
	OFDataArray *addrlist;

	addrlist = [[OFDataArray alloc] initWithItemSize: sizeof(char**)];
	[mutex lock];
# endif

	if ((he = gethostbyname([node cString])) == NULL) {
# ifdef OF_THREADS
		[addrlist release];
		[mutex unlock];
# endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

# ifndef _PSP
	if ((se = getservbyname([service cString], "tcp")) != NULL)
		port = se->s_port;
	else {
# endif
		@try {
			intmax_t p = [service decimalValue];

			if (p < 1 || p > 65535)
				@throw [OFOutOfRangeException
				    newWithClass: isa];

			port = of_bswap16_if_le(p);
		} @catch (OFInvalidFormatException *e) {
			[e release];
# ifdef OF_THREADS
			[addrlist release];
			[mutex unlock];
# endif
			@throw [OFAddressTranslationFailedException
			    newWithClass: isa
				    node: node
				 service: service];
		} @catch (id e) {
# ifdef OF_THREADS
			[addrlist release];
			[mutex unlock];
# endif
			@throw e;
		}
# ifndef _PSP
	}
# endif

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = port;

	if (he->h_addrtype != AF_INET ||
	    (sock = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) {
# ifdef OF_THREADS
		[addrlist release];
		[mutex unlock];
# endif
		@throw [OFConnectionFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

# ifdef OF_THREADS
	@try {
		for (ip = he->h_addr_list; *ip != NULL; ip++)
			[addrlist addItem: ip];

		/* Add the terminating NULL */
		[addrlist addItem: ip];
	} @catch (id e) {
		[addrlist release];
		@throw e;
	} @finally {
		[mutex unlock];
	}

	for (ip = [addrlist cArray]; *ip != NULL; ip++) {
# else
	for (ip = he->h_addr_list; *ip != NULL; ip++) {
# endif
		memcpy(&addr.sin_addr.s_addr, *ip, he->h_length);

		if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) == -1)
			continue;

		connected = YES;
		break;
	}

# ifdef OF_THREADS
	[addrlist release];
# endif

	if (!connected) {
		close(sock);
		sock = INVALID_SOCKET;
	}
#endif

	if (sock == INVALID_SOCKET)
		@throw [OFConnectionFailedException newWithClass: isa
							    node: node
							 service: service];
}

- (void)bindService: (OFString*)service
	     onNode: (OFString*)node
{
	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException newWithClass: isa];

#ifdef HAVE_THREADSAFE_GETADDRINFO
	struct addrinfo hints, *res;

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	if (getaddrinfo([node cString], [service cString], &hints, &res))
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];

	if ((sock = socket(res->ai_family, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service];

	if (bind(sock, res->ai_addr, res->ai_addrlen) == -1) {
		freeaddrinfo(res);
		close(sock);
		sock = INVALID_SOCKET;
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service];
	}

	freeaddrinfo(res);
#else
	struct hostent *he;
# ifndef _PSP
	struct servent *se;
# endif
	struct sockaddr_in addr;
	uint16_t port;

# ifdef OF_THREADS
	[mutex lock];
# endif

	if ((he = gethostbyname([node cString])) == NULL) {
# ifdef OF_THREADS
		[mutex unlock];
# endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

# ifndef _PSP
	if ((se = getservbyname([service cString], "tcp")) != NULL)
		port = se->s_port;
	else {
# endif
		@try {
			intmax_t p = [service decimalValue];

			if (p < 1 || p > 65535)
				@throw [OFOutOfRangeException
				    newWithClass: isa];

			port = of_bswap16_if_le(p);
		} @catch (OFInvalidFormatException *e) {
			[e release];
# ifdef OF_THREADS
			[mutex unlock];
# endif
			@throw [OFAddressTranslationFailedException
			    newWithClass: isa
				    node: node
				 service: service];
		} @catch (id e) {
# ifdef OF_THREADS
			[mutex unlock];
# endif
			@throw e;
		}
# ifndef _PSP
	}
# endif

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = port;

	if (he->h_addrtype != AF_INET || he->h_addr_list[0] == NULL) {
# ifdef OF_THREADS
		[mutex unlock];
# endif
		@throw [OFAddressTranslationFailedException
		    newWithClass: isa
			    node: node
			 service: service];
	}

	memcpy(&addr.sin_addr.s_addr, he->h_addr_list[0], he->h_length);

# ifdef OF_THREADS
	[mutex unlock];
# endif
	if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service];

	if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
		close(sock);
		sock = INVALID_SOCKET;
		@throw [OFBindFailedException newWithClass: isa
						      node: node
						   service: service];
	}
#endif
}

- (void)listenWithBackLog: (int)backlog
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	if (listen(sock, backlog) == -1)
		@throw [OFListenFailedException newWithClass: isa
						     backLog: backlog];

	listening = YES;
}

- (void)listen
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	if (listen(sock, 5) == -1)
		@throw [OFListenFailedException newWithClass: isa
						     backLog: 5];

	listening = YES;
}

- (OFTCPSocket*)accept
{
	OFTCPSocket *newsock;
	struct sockaddr *addr;
	socklen_t addrlen;
	int s;

	newsock = [[[isa alloc] init] autorelease];
	addrlen = sizeof(struct sockaddr);

	@try {
		addr = [newsock allocMemoryWithSize: sizeof(struct sockaddr)];
	} @catch (id e) {
		[newsock release];
		@throw e;
	}

	if ((s = accept(sock, addr, &addrlen)) == INVALID_SOCKET) {
		[newsock release];
		@throw [OFAcceptFailedException newWithClass: isa];
	}

	newsock->sock = s;
	newsock->sockAddr = addr;
	newsock->sockAddrLen = addrlen;

	return newsock;
}

- (void)setKeepAlivesEnabled: (BOOL)enable
{
	int v = enable;

	if (setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, (char*)&v, sizeof(v)))
		@throw [OFSetOptionFailedException newWithClass: isa];
}

- (OFString*)remoteAddress
{
	if (sockAddr == NULL || sockAddrLen == 0)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

#ifdef HAVE_THREADSAFE_GETADDRINFO
	char *node = [self allocMemoryWithSize: NI_MAXHOST];

	@try {
		if (getnameinfo(sockAddr, sockAddrLen, node, NI_MAXHOST, NULL,
		    0, NI_NUMERICHOST))
			@throw [OFAddressTranslationFailedException
			    newWithClass: isa];

		return [OFString stringWithCString: node];
	} @finally {
		[self freeMemory: node];
	}
#else
	char *node;

# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		node = inet_ntoa(((struct sockaddr_in*)sockAddr)->sin_addr);

		if (node == NULL)
			@throw [OFAddressTranslationFailedException
			    newWithClass: isa];

		return [OFString stringWithCString: node];
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	/* Get rid of a warning, never reached anyway */
	assert(0);
}

- (void)close
{
	[super close];

	[self freeMemory: sockAddr];
	sockAddr = NULL;
	sockAddrLen = 0;
}

- (void)dealloc
{
	if (sock != INVALID_SOCKET)
		[self close];

	[super dealloc];
}
@end
