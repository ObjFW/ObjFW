/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#ifndef _XOPEN_SOURCE_EXTENDED
# define _XOPEN_SOURCE_EXTENDED
#endif
#define _HPUX_ALT_XOPEN_SOCKET_API

#include <errno.h>
#include <string.h>

#import "OFStreamSocket.h"
#import "OFStreamSocket+Private.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAcceptSocketFailedException.h"
#import "OFAlreadyOpenException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFListenOnSocketFailedException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

#if defined(OF_AMIGAOS) && !defined(UNIQUE_ID)
# define UNIQUE_ID -1
#endif

@implementation OFStreamSocket
@dynamic delegate;
@synthesize listening = _listening;

+ (void)initialize
{
	if (self != [OFStreamSocket class])
		return;

	if (!_OFSocketInit())
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

		_socket = OFInvalidSocketHandle;
#ifdef OF_AMIGAOS
		_socketID = -1;
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_socket != OFInvalidSocketHandle)
		[self close];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	ssize_t ret;

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	if ((ret = recv(_socket, buffer, length, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: _OFSocketErrNo()];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = recv(_socket, buffer, (int)length, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: _OFSocketErrNo()];
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	if (_socket == OFInvalidSocketHandle)
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
				  errNo: _OFSocketErrNo()];
#else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = send(_socket, buffer, (int)length, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: _OFSocketErrNo()];
#endif

	return (size_t)bytesWritten;
}

#if defined(OF_WINDOWS) || defined(OF_AMIGAOS)
- (void)setCanBlock: (bool)canBlock
{
# ifdef OF_WINDOWS
	u_long v = !canBlock;
# else
	char v = !canBlock;
# endif

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	_canBlock = canBlock;
}
#endif

- (int)fileDescriptorForReading
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == OFInvalidSocketHandle)
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
	if (_socket == OFInvalidSocketHandle)
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
		return _OFSocketErrNo();

	return errNo;
}
#endif

- (void)listen
{
	[self listenWithBacklog: SOMAXCONN];
}

- (void)listenWithBacklog: (int)backlog
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (listen(_socket, backlog) == -1)
		@throw [OFListenOnSocketFailedException
		    exceptionWithSocket: self
				backlog: backlog
				  errNo: _OFSocketErrNo()];

	_listening = true;
}

- (instancetype)accept
{
	OFStreamSocket *client;
#if (!defined(HAVE_PACCEPT) && !defined(HAVE_ACCEPT4)) || !defined(SOCK_CLOEXEC)
# if defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
# endif
#endif

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	client = [[[[self class] alloc] init] autorelease];
	client->_remoteAddress.length =
	    (socklen_t)sizeof(client->_remoteAddress.sockaddr);

#if defined(HAVE_PACCEPT) && defined(SOCK_CLOEXEC)
	if ((client->_socket = paccept(_socket,
	    (struct sockaddr *)&client->_remoteAddress.sockaddr,
	    &client->_remoteAddress.length, NULL, SOCK_CLOEXEC)) ==
	    OFInvalidSocketHandle)
		@throw [OFAcceptSocketFailedException
		    exceptionWithSocket: self
				  errNo: _OFSocketErrNo()];
#elif defined(HAVE_ACCEPT4) && defined(SOCK_CLOEXEC)
	if ((client->_socket = accept4(_socket,
	    (struct sockaddr * )&client->_remoteAddress.sockaddr,
	    &client->_remoteAddress.length, SOCK_CLOEXEC)) ==
	    OFInvalidSocketHandle)
		@throw [OFAcceptSocketFailedException
		    exceptionWithSocket: self
				  errNo: _OFSocketErrNo()];
#else
	if ((client->_socket = accept(_socket,
	    (struct sockaddr *)&client->_remoteAddress.sockaddr,
	    &client->_remoteAddress.length)) == OFInvalidSocketHandle)
		@throw [OFAcceptSocketFailedException
		    exceptionWithSocket: self
				  errNo: _OFSocketErrNo()];

# if defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(client->_socket, F_GETFD, 0)) != -1)
		fcntl(client->_socket, F_SETFD, flags | FD_CLOEXEC);
# endif
#endif

	OFAssert(client->_remoteAddress.length <=
	    (socklen_t)sizeof(client->_remoteAddress.sockaddr));

	switch (((struct sockaddr *)&client->_remoteAddress.sockaddr)
	    ->sa_family) {
	case AF_INET:
		client->_remoteAddress.family = OFSocketAddressFamilyIPv4;
		break;
#ifdef OF_HAVE_IPV6
	case AF_INET6:
		client->_remoteAddress.family = OFSocketAddressFamilyIPv6;
		break;
#endif
#ifdef OF_HAVE_UNIX_SOCKETS
	case AF_UNIX:
		client->_remoteAddress.family = OFSocketAddressFamilyUNIX;
		break;
#endif
#ifdef OF_HAVE_IPX
	case AF_IPX:
		client->_remoteAddress.family = OFSocketAddressFamilyIPX;
		break;
#endif
	default:
		client->_remoteAddress.family = OFSocketAddressFamilyUnknown;
		break;
	}

	return client;
}

- (void)asyncAccept
{
	[self asyncAcceptWithRunLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncAcceptForSocket: self
					 mode: runLoopMode
					block: NULL
				     delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncAcceptWithBlock: (OFStreamSocketAsyncAcceptBlock)block
{
	[self asyncAcceptWithRunLoopMode: OFDefaultRunLoopMode block: block];
}

- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
			     block: (OFStreamSocketAsyncAcceptBlock)block
{
	[OFRunLoop of_addAsyncAcceptForSocket: self
					 mode: runLoopMode
					block: block
				     delegate: nil];
}
#endif

- (const OFSocketAddress *)remoteAddress
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_remoteAddress.length == 0)
		@throw [OFInvalidArgumentException exception];

	if (_remoteAddress.length > (socklen_t)sizeof(_remoteAddress.sockaddr))
		@throw [OFOutOfRangeException exception];

	return &_remoteAddress;
}

- (void)releaseSocketFromCurrentThread
{
#ifdef OF_AMIGAOS
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((_socketID = ReleaseSocket(_socket, UNIQUE_ID)) == -1) {
		switch (Errno()) {
		case ENOMEM:
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: 0];
		case EBADF:
			@throw [OFNotOpenException exceptionWithObject: self];
		default:
			OFEnsure(0);
		}
	}

	_socket = OFInvalidSocketHandle;
#endif
}

- (void)obtainSocketForCurrentThread
{
#ifdef OF_AMIGAOS
	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if (_socketID == -1)
		@throw [OFNotOpenException exceptionWithObject: self];

	/*
	 * FIXME: We should store these, but that requires changing all
	 *	  subclasses. This only becomes a problem if IPv6 support ever
	 *	  gets added.
	 */
	_socket = ObtainSocket(_socketID, AF_INET, SOCK_STREAM, 0);
	if (_socket == OFInvalidSocketHandle)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self.class];

	_socketID = -1;
#endif
}

- (void)close
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	_listening = false;
	memset(&_remoteAddress, 0, sizeof(_remoteAddress));

	closesocket(_socket);
	_socket = OFInvalidSocketHandle;

	_atEndOfStream = false;

	[super close];
}
@end
