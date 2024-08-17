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

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFSequencedPacketSocket.h"
#import "OFSequencedPacketSocket+Private.h"
#import "OFData.h"
#import "OFRunLoop+Private.h"
#import "OFRunLoop.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAcceptSocketFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFListenOnSocketFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

@implementation OFSequencedPacketSocket
@synthesize listening = _listening, delegate = _delegate;

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		if (self.class == [OFSequencedPacketSocket class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

		if (!_OFSocketInit())
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_socket = OFInvalidSocketHandle;
		_canBlock = true;
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

- (id)copy
{
	return [self retain];
}

- (bool)canBlock
{
	return _canBlock;
}

- (void)setCanBlock: (bool)canBlock
{
#if defined(HAVE_FCNTL)
	int flags = fcntl(_socket, F_GETFL, 0);

	if (flags == -1)
		@throw [OFSetOptionFailedException exceptionWithObject: self
								 errNo: errno];

	if (canBlock)
		flags &= ~O_NONBLOCK;
	else
		flags |= O_NONBLOCK;

	if (fcntl(_socket, F_SETFL, flags) == -1)
		@throw [OFSetOptionFailedException exceptionWithObject: self
								 errNo: errno];

	_canBlock = canBlock;
#elif defined(OF_WINDOWS)
	u_long v = !canBlock;

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	_canBlock = canBlock;
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (size_t)receiveIntoBuffer: (void *)buffer length: (size_t)length
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

	return ret;
}

- (void)asyncReceiveIntoBuffer: (void *)buffer length: (size_t)length
{
	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncReceiveForSequencedPacketSocket: self
						       buffer: buffer
						       length: length
							 mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
							block: NULL
# endif
						     delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			 block: (OFSequencedPacketSocketAsyncReceiveBlock)block
{
	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: OFDefaultRunLoopMode
			       block: block];
}

- (void)
    asyncReceiveIntoBuffer: (void *)buffer
		    length: (size_t)length
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFSequencedPacketSocketAsyncReceiveBlock)block
{
	[OFRunLoop of_addAsyncReceiveForSequencedPacketSocket: self
						       buffer: buffer
						       length: length
							 mode: runLoopMode
							block: block
						     delegate: nil];
}
#endif

- (void)sendBuffer: (const void *)buffer length: (size_t)length
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

	if ((size_t)bytesWritten != length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: 0];
}

- (void)asyncSendData: (OFData *)data
{
	[self asyncSendData: data runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncSendData: (OFData *)data runLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncSendForSequencedPacketSocket: self
						      data: data
						      mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
						     block: NULL
# endif
						  delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncSendData: (OFData *)data
		block: (OFSequencedPacketSocketAsyncSendDataBlock)block
{
	[self asyncSendData: data
		runLoopMode: OFDefaultRunLoopMode
		      block: block];
}

- (void)asyncSendData: (OFData *)data
	  runLoopMode: (OFRunLoopMode)runLoopMode
		block: (OFSequencedPacketSocketAsyncSendDataBlock)block
{
	[OFRunLoop of_addAsyncSendForSequencedPacketSocket: self
						      data: data
						      mode: runLoopMode
						     block: block
						  delegate: nil];
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
	OFSequencedPacketSocket *client;
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
	    (struct sockaddr *)&client->_remoteAddress.sockaddr,
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
- (void)asyncAcceptWithBlock: (OFSequencedPacketSocketAsyncAcceptBlock)block
{
	[self asyncAcceptWithRunLoopMode: OFDefaultRunLoopMode block: block];
}

- (void)
    asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
			 block: (OFSequencedPacketSocketAsyncAcceptBlock)block
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

- (void)cancelAsyncRequests
{
	[OFRunLoop of_cancelAsyncRequestsForObject: self
					      mode: OFDefaultRunLoopMode];
}

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

- (void)releaseSocketFromCurrentThread
{
	/*
	 * Currently a nop, as all supported OSes that have SOCK_SEQPACKET do
	 * not need anything to move sockets between threads.
	 */
}

- (void)obtainSocketForCurrentThread
{
	/*
	 * Currently a nop, as all supported OSes that have SOCK_SEQPACKET do
	 * not need anything to move sockets between threads.
	 */
}

- (void)close
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	_listening = false;
	memset(&_remoteAddress, 0, sizeof(_remoteAddress));

	closesocket(_socket);
	_socket = OFInvalidSocketHandle;
}
@end
