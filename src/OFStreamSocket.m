/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>
#include <unistd.h>
#include <errno.h>

#ifndef _WIN32
# include <sys/types.h>
# include <sys/socket.h>
#endif

#import "OFStreamSocket.h"
#import "OFExceptions.h"

#ifndef INVALID_SOCKET
# define INVALID_SOCKET -1
#endif

#ifdef _WIN32
# define close(sock) closesocket(sock)
#endif

@implementation OFStreamSocket
#ifdef _WIN32
+ (void)initialize
{
	WSADATA wsa;

	if (self != [OFStreamSocket class])
		return;

	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		@throw [OFInitializationFailedException newWithClass: self];
}
#endif

+ socket
{
	return [[[self alloc] init] autorelease];
}

- (BOOL)_isAtEndOfStream
{
	return eos;
}

- (size_t)_readNBytes: (size_t)size
	   intoBuffer: (char*)buf
{
	ssize_t ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

#ifndef _WIN32
	/* FIXME: We want a sane error message on Win32 as well */
	if (eos)
		errno = ENOTCONN;
#endif

	if (eos || (ret = recv(sock, buf, size, 0)) < 0)
		@throw [OFReadFailedException newWithClass: isa
					     requestedSize: size];

	if (ret == 0)
		eos = YES;

	return ret;
}

- (size_t)_writeNBytes: (size_t)size
	    fromBuffer: (const char*)buf
{
	ssize_t ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

#ifndef _WIN32
	/* FIXME: We want a sane error message on Win32 as well */
	if (eos)
		errno = ENOTCONN;
#endif

	if (eos || (ret = send(sock, buf, size, 0)) == -1)
		@throw [OFWriteFailedException newWithClass: isa
					      requestedSize: size];

	/* This is safe, as we already checked for -1 */
	return ret;
}

#ifdef _WIN32
- (void)setBlocking: (BOOL)enable
{
	u_long v = enable;
	isBlocking = enable;

	if (ioctlsocket(sock, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException newWithClass: isa];
}
#endif

- (int)fileDescriptor
{
	return sock;
}

- (void)close
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException newWithClass: isa];

	close(sock);

	sock = INVALID_SOCKET;
	eos = NO;
	listening = NO;
}
@end
