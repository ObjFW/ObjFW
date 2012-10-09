/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define __NO_EXT_QNX

#include <string.h>

#include <unistd.h>

#include <errno.h>

#ifndef _WIN32
# include <sys/types.h>
# include <sys/socket.h>
#endif

#import "OFStreamSocket.h"

#import "OFInitializationFailedException.h"
#import "OFNotConnectedException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

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
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (BOOL)lowlevelIsAtEndOfStream
{
	return atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithClass: [self class]
							    socket: self];

	if (atEndOfStream) {
		OFReadFailedException *e;

		e = [OFReadFailedException exceptionWithClass: [self class]
						       stream: self
					      requestedLength: length];
#ifndef _WIN32
		e->errNo = ENOTCONN;
#else
		e->errNo = WSAENOTCONN;
#endif

		@throw e;
	}

	if ((ret = recv(sock, buffer, length, 0)) < 0)
		@throw [OFReadFailedException exceptionWithClass: [self class]
							  stream: self
						 requestedLength: length];

	if (ret == 0)
		atEndOfStream = YES;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithClass: [self class]
							    socket: self];

	if (atEndOfStream) {
		OFWriteFailedException *e;

		e = [OFWriteFailedException exceptionWithClass: [self class]
							stream: self
					       requestedLength: length];
#ifndef _WIN32
		e->errNo = ENOTCONN;
#else
		e->errNo = WSAENOTCONN;
#endif

		@throw e;
	}

	if (send(sock, buffer, length, 0) < length)
		@throw [OFWriteFailedException exceptionWithClass: [self class]
							   stream: self
						  requestedLength: length];
}

#ifdef _WIN32
- (void)setBlocking: (BOOL)enable
{
	u_long v = enable;
	blocking = enable;

	if (ioctlsocket(sock, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithClass: [self class]
				stream: self];
}
#endif

- (int)fileDescriptorForReading
{
	return sock;
}

- (int)fileDescriptorForWriting
{
	return sock;
}

- (void)close
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithClass: [self class]
							    socket: self];

	close(sock);

	sock = INVALID_SOCKET;
	atEndOfStream = NO;
}

- (void)dealloc
{
	if (sock != INVALID_SOCKET)
		[self close];

	[super dealloc];
}
@end
