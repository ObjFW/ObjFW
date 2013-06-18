/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <sys/types.h>
#ifdef OF_HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif

#import "OFStreamSocket.h"

#import "OFInitializationFailedException.h"
#import "OFNotConnectedException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

#ifdef __wii__
# define BOOL OGC_BOOL
# include <network.h>
# undef BOOL
# define recv(sock, buf, len, flags) net_recv(sock, buf, len, flags)
# define send(sock, buf, len, flags) net_send(sock, buf, len, flags)
#endif

#ifndef INVALID_SOCKET
# define INVALID_SOCKET -1
#endif

#ifdef _WIN32
# define close(sock) closesocket(sock)
#endif

@implementation OFStreamSocket
+ (void)initialize
{
#ifdef _WIN32
	WSADATA wsa;
#endif

	if (self != [OFStreamSocket class])
		return;

#if defined(_WIN32)
	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#elif defined(__wii__)
	if (net_init() < 0)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif
}

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithSocket: self];

	if (_atEndOfStream) {
		OFReadFailedException *e;

		e = [OFReadFailedException exceptionWithStream: self
					       requestedLength: length];
#ifndef _WIN32
		e->_errNo = ENOTCONN;
#else
		e->_errNo = WSAENOTCONN;
#endif

		@throw e;
	}

	if ((ret = recv(_socket, buffer, length, 0)) < 0)
		@throw [OFReadFailedException exceptionWithStream: self
						  requestedLength: length];

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithSocket: self];

	if (_atEndOfStream) {
		OFWriteFailedException *e;

		e = [OFWriteFailedException exceptionWithStream: self
						requestedLength: length];
#ifndef _WIN32
		e->_errNo = ENOTCONN;
#else
		e->_errNo = WSAENOTCONN;
#endif

		@throw e;
	}

	if (send(_socket, buffer, length, 0) < length)
		@throw [OFWriteFailedException exceptionWithStream: self
						   requestedLength: length];
}

#ifdef _WIN32
- (void)setBlocking: (bool)enable
{
	u_long v = enable;
	_blocking = enable;

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException exceptionWithStream: self];
}
#endif

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

	_atEndOfStream = false;
}

- (void)dealloc
{
	if (_socket != INVALID_SOCKET)
		[self close];

	[super dealloc];
}
@end
