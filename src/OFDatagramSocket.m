/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFDatagramSocket.h"
#import "OFData.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAlreadyOpenException.h"
#import "OFGetOptionFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

#if defined(OF_AMIGAOS) && !defined(UNIQUE_ID)
# define UNIQUE_ID -1
#endif

@implementation OFDatagramSocket
@synthesize delegate = _delegate;

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		if (self.class == [OFDatagramSocket class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

		if (!_OFSocketInit())
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_socket = OFInvalidSocketHandle;
#ifdef OF_HAVE_AMIGAOS
		_socketID = -1;
#endif
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

- (void)setCanSendToBroadcastAddresses: (bool)canSendToBroadcastAddresses
{
	int v = canSendToBroadcastAddresses;

	if (setsockopt(_socket, SOL_SOCKET, SO_BROADCAST,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

#ifdef OF_WII
	_canSendToBroadcastAddresses = canSendToBroadcastAddresses;
#endif
}

- (bool)canSendToBroadcastAddresses
{
#ifndef OF_WII
	int v;
	socklen_t len = (socklen_t)sizeof(v);

	if (getsockopt(_socket, SOL_SOCKET, SO_BROADCAST,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	return v;
#else
	return _canSendToBroadcastAddresses;
#endif
}

- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (OFSocketAddress *)sender
{
	ssize_t ret;

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (sender != NULL)
		sender->length = (socklen_t)sizeof(sender->sockaddr);

#ifndef OF_WINDOWS
	while ((ret = recvfrom(_socket, buffer, length, 0,
	    (sender != NULL ? (struct sockaddr *)&sender->sockaddr : NULL),
	    (sender != NULL ? &sender->length : NULL))) < 0) {
		int errNo = _OFSocketErrNo();

		if (errNo != EINTR)
			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: length
					  errNo: errNo];
	}
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = recvfrom(_socket, buffer, (int)length, 0,
	    (sender != NULL ? (struct sockaddr *)&sender->sockaddr : NULL),
	    (sender != NULL ? &sender->length : NULL))) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: _OFSocketErrNo()];
#endif

	if (sender != NULL) {
		struct sockaddr *sa = (struct sockaddr *)&sender->sockaddr;

		if (sender->length >= (socklen_t)sizeof(sa->sa_family)) {
			switch (sa->sa_family) {
			case AF_INET:
				sender->family = OFSocketAddressFamilyIPv4;
				break;
#ifdef OF_HAVE_IPV6
			case AF_INET6:
				sender->family = OFSocketAddressFamilyIPv6;
				break;
#endif
#ifdef OF_HAVE_UNIX_SOCKETS
			case AF_UNIX:
				sender->family = OFSocketAddressFamilyUNIX;
				break;
#endif
#ifdef OF_HAVE_IPX
			case AF_IPX:
				sender->family = OFSocketAddressFamilyIPX;
				break;
#endif
#ifdef OF_HAVE_APPLETALK
			case AF_APPLETALK:
				sender->family = OFSocketAddressFamilyAppleTalk;
				break;
#endif
			default:
				sender->family = OFSocketAddressFamilyUnknown;
				break;
			}
		} else
			sender->family = OFSocketAddressFamilyUnknown;
	}

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
	[OFRunLoop of_addAsyncReceiveForDatagramSocket: self
						buffer: buffer
						length: length
						  mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					       handler: NULL
# endif
					      delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			 block: (OFDatagramSocketAsyncReceiveBlock)block
{
	OFDatagramSocketPacketReceivedHandler handler = ^ bool (
	    OFDatagramSocket *socket, void *buffer_, size_t length_,
	    const OFSocketAddress *sender, id exception) {
		return block(length_, sender, exception);
	};

	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: OFDefaultRunLoopMode
			     handler: handler];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		       handler: (OFDatagramSocketPacketReceivedHandler)handler
{
	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: OFDefaultRunLoopMode
			     handler: handler];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
			 block: (OFDatagramSocketAsyncReceiveBlock)block
{
	OFDatagramSocketPacketReceivedHandler handler = ^ bool (
	    OFDatagramSocket *socket, void *buffer_, size_t length_,
	    const OFSocketAddress *sender, id exception) {
		return block(length_, sender, exception);
	};

	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: runLoopMode
			     handler: handler];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
		       handler: (OFDatagramSocketPacketReceivedHandler)handler
{
	[OFRunLoop of_addAsyncReceiveForDatagramSocket: self
						buffer: buffer
						length: length
						  mode: runLoopMode
					       handler: handler
					      delegate: nil];
}
#endif

- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const OFSocketAddress *)receiver
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	while ((bytesWritten = sendto(_socket, (void *)buffer, length, 0,
	    (struct sockaddr *)&receiver->sockaddr, receiver->length)) < 0) {
		int errNo = _OFSocketErrNo();

		if (errNo != EINTR)
			@throw [OFWriteFailedException
			    exceptionWithObject: self
				requestedLength: length
				   bytesWritten: 0
					  errNo: errNo];
	}
#else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = sendto(_socket, buffer, (int)length, 0,
	    (struct sockaddr *)&receiver->sockaddr, receiver->length)) < 0)
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
	     receiver: (const OFSocketAddress *)receiver
{
	[self asyncSendData: data
		   receiver: receiver
		runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncSendForDatagramSocket: self
					       data: data
					   receiver: receiver
					       mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					    handler: NULL
# endif
					   delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
		block: (OFDatagramSocketAsyncSendDataBlock)block
{
	OFDatagramSocketDataSentHandler handler = ^ OFData *(
	    OFDatagramSocket *socket, OFData *data_,
	    const OFSocketAddress *receiver_, id exception) {
		return block(exception);
	};

	[self asyncSendData: data
		   receiver: receiver
		runLoopMode: OFDefaultRunLoopMode
		    handler: handler];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	      handler: (OFDatagramSocketDataSentHandler)handler
{
	[self asyncSendData: data
		   receiver: receiver
		runLoopMode: OFDefaultRunLoopMode
		    handler: handler];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode
		block: (OFDatagramSocketAsyncSendDataBlock)block
{
	OFDatagramSocketDataSentHandler handler = ^ OFData *(
	    OFDatagramSocket *socket, OFData *data_,
	    const OFSocketAddress *receiver_, id exception) {
		return block(exception);
	};

	[OFRunLoop of_addAsyncSendForDatagramSocket: self
					       data: data
					   receiver: receiver
					       mode: runLoopMode
					    handler: handler
					   delegate: nil];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode
	      handler: (OFDatagramSocketDataSentHandler)handler
{
	[OFRunLoop of_addAsyncSendForDatagramSocket: self
					       data: data
					   receiver: receiver
					       mode: runLoopMode
					    handler: handler
					   delegate: nil];
}
#endif

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
	_socket = ObtainSocket(_socketID, AF_INET, SOCK_DGRAM, 0);
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

	closesocket(_socket);
	_socket = OFInvalidSocketHandle;
}
@end
