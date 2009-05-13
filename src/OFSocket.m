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

#include <string.h>
#include <fcntl.h>

#import "OFSocket.h"
#import "OFExceptions.h"

#ifndef INVALID_SOCKET
#define INVALID_SOCKET -1
#endif

@implementation OFSocket
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
	self = [super init];

	sock = INVALID_SOCKET;
	saddr = NULL;
	saddr_len = 0;

	return self;
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
@end
