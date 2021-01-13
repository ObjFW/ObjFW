/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#define _XOPEN_SOURCE_EXTENDED
#define __NO_EXT_QNX

#include <assert.h>
#include <errno.h>
#include <string.h>

#import "OFStreamSocket.h"
#import "OFStreamSocket+Private.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"

#import "OFAcceptFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFListenFailedException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

#import "socket_helpers.h"

@implementation OFStreamSocket
@dynamic delegate;
@synthesize listening = _listening;

+ (void)initialize
{
	if (self != [OFStreamSocket class])
		return;

	if (!of_socket_init())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		if (self.class == [OFStreamSocket class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

		_socket = INVALID_SOCKET;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_socket != INVALID_SOCKET)
		[self close];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	if ((ret = recv(_socket, buffer, length, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = recv(_socket, buffer, (int)length, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = send(_socket, (void *)buffer, length, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: of_socket_errno()];
#else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = send(_socket, buffer, (int)length, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: of_socket_errno()];
#endif

	return (size_t)bytesWritten;
}

#if defined(OF_WINDOWS) || defined(OF_AMIGAOS)
- (void)setCanBlock: (bool)canBlock
{
# ifdef OF_WINDOWS
	u_long v = canBlock;
# else
	char v = canBlock;
# endif

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: of_socket_errno()];

	_canBlock = canBlock;
}
#endif

- (int)fileDescriptorForReading
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

#ifndef OF_WII
- (int)of_socketError
{
	int errNo;
	socklen_t len = sizeof(errNo);

	if (getsockopt(_socket, SOL_SOCKET, SO_ERROR, (char *)&errNo,
	    &len) != 0)
		return of_socket_errno();

	return errNo;
}
#endif

- (void)listen
{
	[self listenWithBacklog: SOMAXCONN];
}

- (void)listenWithBacklog: (int)backlog
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (listen(_socket, backlog) == -1)
		@throw [OFListenFailedException
		    exceptionWithSocket: self
				backlog: backlog
				  errNo: of_socket_errno()];

	_listening = true;
}

- (instancetype)accept
{
	OFStreamSocket *client = [[[[self class] alloc] init] autorelease];
#if (!defined(HAVE_PACCEPT) && !defined(HAVE_ACCEPT4)) || !defined(SOCK_CLOEXEC)
# if defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
# endif
#endif

	client->_remoteAddress.length =
	    (socklen_t)sizeof(client->_remoteAddress.sockaddr);

#if defined(HAVE_PACCEPT) && defined(SOCK_CLOEXEC)
	if ((client->_socket = paccept(_socket,
	    &client->_remoteAddress.sockaddr.sockaddr,
	    &client->_remoteAddress.length, NULL, SOCK_CLOEXEC)) ==
	    INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];
#elif defined(HAVE_ACCEPT4) && defined(SOCK_CLOEXEC)
	if ((client->_socket = accept4(_socket,
	    &client->_remoteAddress.sockaddr.sockaddr,
	    &client->_remoteAddress.length, SOCK_CLOEXEC)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];
#else
	if ((client->_socket = accept(_socket,
	    &client->_remoteAddress.sockaddr.sockaddr,
	    &client->_remoteAddress.length)) == INVALID_SOCKET)
		@throw [OFAcceptFailedException
		    exceptionWithSocket: self
				  errNo: of_socket_errno()];

# if defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(client->_socket, F_GETFD, 0)) != -1)
		fcntl(client->_socket, F_SETFD, flags | FD_CLOEXEC);
# endif
#endif

	assert(client->_remoteAddress.length <=
	    (socklen_t)sizeof(client->_remoteAddress.sockaddr));

	switch (client->_remoteAddress.sockaddr.sockaddr.sa_family) {
	case AF_INET:
		client->_remoteAddress.family = OF_SOCKET_ADDRESS_FAMILY_IPV4;
		break;
#ifdef OF_HAVE_IPV6
	case AF_INET6:
		client->_remoteAddress.family = OF_SOCKET_ADDRESS_FAMILY_IPV6;
		break;
#endif
#ifdef OF_HAVE_IPX
	case AF_IPX:
		client->_remoteAddress.family = OF_SOCKET_ADDRESS_FAMILY_IPX;
		break;
#endif
	default:
		client->_remoteAddress.family =
		    OF_SOCKET_ADDRESS_FAMILY_UNKNOWN;
		break;
	}

	return client;
}

- (void)asyncAccept
{
	[self asyncAcceptWithRunLoopMode: of_run_loop_mode_default];
}

- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
{
	[OFRunLoop of_addAsyncAcceptForSocket: self
					 mode: runLoopMode
					block: NULL
				     delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncAcceptWithBlock: (of_stream_socket_async_accept_block_t)block
{
	[self asyncAcceptWithRunLoopMode: of_run_loop_mode_default
				   block: block];
}

- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
			     block: (of_stream_socket_async_accept_block_t)block
{
	[OFRunLoop of_addAsyncAcceptForSocket: self
					 mode: runLoopMode
					block: block
				     delegate: nil];
}
#endif

- (const of_socket_address_t *)remoteAddress
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_remoteAddress.length == 0)
		@throw [OFInvalidArgumentException exception];

	if (_remoteAddress.length > (socklen_t)sizeof(_remoteAddress.sockaddr))
		@throw [OFOutOfRangeException exception];

	return &_remoteAddress;
}

- (void)close
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	_listening = false;
	memset(&_remoteAddress, 0, sizeof(_remoteAddress));

	closesocket(_socket);
	_socket = INVALID_SOCKET;

	_atEndOfStream = false;

	[super close];
}
@end
