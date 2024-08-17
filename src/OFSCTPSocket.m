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

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFSCTPSocket.h"
#import "OFAsyncIPSocketConnector.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"
#import "OFThread.h"

#import "OFAcceptSocketFailedException.h"
#import "OFAlreadyOpenException.h"
#import "OFBindIPSocketFailedException.h"
#import "OFGetOptionFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

const OFSCTPMessageInfoKey OFSCTPStreamID = @"OFSCTPStreamID";
const OFSCTPMessageInfoKey OFSCTPPPID = @"OFSCTPPPID";
const OFSCTPMessageInfoKey OFSCTPUnordered = @"OFSCTPUnordered";

static const OFRunLoopMode connectRunLoopMode =
    @"OFSCTPSocketConnectRunLoopMode";

@interface OFSCTPSocket () <OFAsyncIPSocketConnecting>
@end

@interface OFSCTPSocketConnectDelegate: OFObject <OFSCTPSocketDelegate>
{
@public
	bool _done;
	id _exception;
}
@end

@implementation OFSCTPSocketConnectDelegate
- (void)dealloc
{
	[_exception release];

	[super dealloc];
}

-     (void)socket: (OFSCTPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	_done = true;
	_exception = [exception retain];
}
@end

@implementation OFSCTPSocket
@dynamic delegate;

- (bool)of_createSocketForAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo
{
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif
#ifdef SCTP_RECVRCVINFO
	int one = 1;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if ((_socket = socket(
	    ((struct sockaddr *)&address->sockaddr)->sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, IPPROTO_SCTP)) ==
	    OFInvalidSocketHandle) {
		*errNo = _OFSocketErrNo();
		return false;
	}

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

#ifdef SCTP_RECVRCVINFO
	if (setsockopt(_socket, IPPROTO_SCTP, SCTP_RECVRCVINFO, &one,
	    sizeof(one)) != 0) {
		*errNo = _OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		return false;
	}
#endif

	return true;
}

- (bool)of_connectSocketToAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (connect(_socket, (struct sockaddr *)&address->sockaddr,
	    address->length) != 0) {
		*errNo = _OFSocketErrNo();
		return false;
	}

	return true;
}

- (void)of_closeSocket
{
	closesocket(_socket);
	_socket = OFInvalidSocketHandle;
}

- (void)connectToHost: (OFString *)host port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	id <OFSCTPSocketDelegate> delegate = _delegate;
	OFSCTPSocketConnectDelegate *connectDelegate =
	    [[[OFSCTPSocketConnectDelegate alloc] init] autorelease];
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];

	_delegate = connectDelegate;
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: connectRunLoopMode];

	while (!connectDelegate->_done)
		[runLoop runMode: connectRunLoopMode beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: connectRunLoopMode beforeDate: [OFDate date]];

	_delegate = delegate;

	if (connectDelegate->_exception != nil)
		@throw connectDelegate->_exception;

	objc_autoreleasePoolPop(pool);
}

- (void)asyncConnectToHost: (OFString *)host port: (uint16_t)port
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	[[[[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: _delegate
			   block: NULL
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (OFSCTPSocketAsyncConnectBlock)block
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: OFDefaultRunLoopMode
			   block: block];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFSCTPSocketAsyncConnectBlock)block
{
	void *pool = objc_autoreleasePoolPush();

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	[[[[OFAsyncIPSocketConnector alloc]
		  initWithSocket: self
			    host: host
			    port: port
			delegate: nil
			   block: block] autorelease]
	    startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFSocketAddress)bindToHost: (OFString *)host port: (uint16_t)port
{
	const int one = 1;
	void *pool = objc_autoreleasePoolPush();
	OFData *socketAddresses;
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	socketAddresses = [[OFThread DNSResolver]
	    resolveAddressesForHost: host
		      addressFamily: OFSocketAddressFamilyAny];

	address = *(OFSocketAddress *)[socketAddresses itemAtIndex: 0];
	OFSocketAddressSetIPPort(&address, port);

	if ((_socket = socket(
	    ((struct sockaddr *)&address.sockaddr)->sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, IPPROTO_SCTP)) == OFInvalidSocketHandle)
		@throw [OFBindIPSocketFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: _OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	setsockopt(_socket, SOL_SOCKET, SO_REUSEADDR,
	    (char *)&one, (socklen_t)sizeof(one));

	if (bind(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = _OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPSocketFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
	}

	memset(&address, 0, sizeof(address));

	address.length = (socklen_t)sizeof(address.sockaddr);
	if (_OFGetSockName(_socket, (struct sockaddr *)&address.sockaddr,
	    &address.length) != 0) {
		int errNo = _OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPSocketFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
	}

	switch (((struct sockaddr *)&address.sockaddr)->sa_family) {
	case AF_INET:
		address.family = OFSocketAddressFamilyIPv4;
		break;
# ifdef OF_HAVE_IPV6
	case AF_INET6:
		address.family = OFSocketAddressFamilyIPv6;
		break;
# endif
	default:
		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPSocketFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: EAFNOSUPPORT];
	}

	objc_autoreleasePoolPop(pool);

	return address;
}

#ifdef SCTP_RECVRCVINFO
- (instancetype)accept
{
	OFSCTPSocket *accepted = [super accept];
	int one = 1;

	if (setsockopt(accepted->_socket, IPPROTO_SCTP, SCTP_RECVRCVINFO, &one,
	    sizeof(one)) != 0)
		@throw [OFAcceptSocketFailedException
		    exceptionWithSocket: self
				  errNo: _OFSocketErrNo()];

	return accepted;
}
#endif

- (size_t)receiveIntoBuffer: (void *)buffer length: (size_t)length
{
	return [self receiveIntoBuffer: buffer length: length info: NULL];
}

- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		       info: (OFSCTPMessageInfo *)info
{
	ssize_t ret;
	struct iovec iov = {
		.iov_base = buffer,
		.iov_len = length
	};
	struct sctp_rcvinfo rcvinfo;
	socklen_t rcvinfoSize = (socklen_t)sizeof(rcvinfo);
	unsigned int infotype = SCTP_RECVV_RCVINFO;
	int flags;

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = sctp_recvv(_socket, &iov, 1, NULL, NULL,
	    &rcvinfo, &rcvinfoSize, &infotype, &flags)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: _OFSocketErrNo()];

	if (info != NULL) {
		if (infotype == SCTP_RECVV_RCVINFO &&
		    rcvinfoSize >= (socklen_t)sizeof(rcvinfo)) {
			OFNumber *streamID = [OFNumber numberWithUnsignedShort:
			    rcvinfo.rcv_sid];
			OFNumber *PPID = [OFNumber numberWithUnsignedLong:
			    rcvinfo.rcv_ppid];
			OFNumber *unordered = [OFNumber numberWithBool:
			    (rcvinfo.rcv_flags & SCTP_UNORDERED)];

			*info = [OFDictionary dictionaryWithKeysAndObjects:
			    OFSCTPStreamID, streamID,
			    OFSCTPPPID, PPID,
			    OFSCTPUnordered, unordered, nil];
		} else
			*info = [OFDictionary dictionary];
	}

	return ret;
}

- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length
{
	[self asyncReceiveWithInfoIntoBuffer: buffer
				      length: length
				 runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length
			   runLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncReceiveForSCTPSocket: self
					    buffer: buffer
					    length: length
					      mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					     block: NULL
# endif
					  delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length
				 block: (OFSCTPSocketAsyncReceiveBlock)block
{
	[self asyncReceiveWithInfoIntoBuffer: buffer
				      length: length
				 runLoopMode: OFDefaultRunLoopMode
				       block: block];
}

- (void)
    asyncReceiveWithInfoIntoBuffer: (void *)buffer
			    length: (size_t)length
		       runLoopMode: (OFRunLoopMode)runLoopMode
			     block: (OFSCTPSocketAsyncReceiveBlock)block
{
	[OFRunLoop of_addAsyncReceiveForSCTPSocket: self
					    buffer: buffer
					    length: length
					      mode: runLoopMode
					     block: block
					  delegate: nil];
}
#endif

- (void)sendBuffer: (const void *)buffer length: (size_t)length
{
	[self sendBuffer: buffer length: length info: nil];
}

- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	      info: (OFSCTPMessageInfo)info
{
	ssize_t bytesWritten;
	struct iovec iov = {
		.iov_base = (void *)buffer,
		.iov_len = length
	};
	struct sctp_sndinfo sndinfo = {
		.snd_sid = (uint16_t)
		    [[info objectForKey: OFSCTPStreamID] unsignedShortValue],
		.snd_ppid = (uint32_t)
		    [[info objectForKey: OFSCTPPPID] unsignedLongValue],
		.snd_flags = ([[info objectForKey: OFSCTPUnordered] boolValue]
		    ? SCTP_UNORDERED : 0)
	};

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = sctp_sendv(_socket, &iov, 1, NULL, 0, &sndinfo,
	    (socklen_t)sizeof(sndinfo), SCTP_SENDV_SNDINFO, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: _OFSocketErrNo()];

#ifndef OF_SOLARIS
	/* Solaris seems to just return 0. */
	if ((size_t)bytesWritten != length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: 0];
#endif
}

- (void)asyncSendData: (OFData *)data info: (OFSCTPMessageInfo)info
{
	[self asyncSendData: data info: nil runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncSendData: (OFData *)data
		 info: (OFSCTPMessageInfo)info
	  runLoopMode: (OFRunLoopMode)runLoopMode
{
	[OFRunLoop of_addAsyncSendForSCTPSocket: self
					   data: data
					   info: info
					   mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					  block: NULL
# endif
				       delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncSendData: (OFData *)data
		 info: (OFSCTPMessageInfo)info
		block: (OFSCTPSocketAsyncSendDataBlock)block
{
	[self asyncSendData: data
		       info: info
		runLoopMode: OFDefaultRunLoopMode
		      block: block];
}

- (void)asyncSendData: (OFData *)data
		 info: (OFSCTPMessageInfo)info
	  runLoopMode: (OFRunLoopMode)runLoopMode
		block: (OFSCTPSocketAsyncSendDataBlock)block
{
	[OFRunLoop of_addAsyncSendForSCTPSocket: self
					   data: data
					   info: info
					   mode: runLoopMode
					  block: block
				       delegate: nil];
}
#endif

- (void)setCanDelaySendingMessages: (bool)canDelaySendingMessages
{
	int v = !canDelaySendingMessages;

	if (setsockopt(_socket, IPPROTO_SCTP, SCTP_NODELAY,
	    (char *)&v, (socklen_t)sizeof(v)) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];
}

- (bool)canDelaySendingMessages
{
	int v;
	socklen_t len = sizeof(v);

	if (getsockopt(_socket, IPPROTO_SCTP, SCTP_NODELAY,
	    (char *)&v, &len) != 0 || len != sizeof(v))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	return !v;
}
@end
