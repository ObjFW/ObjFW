/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#define _XPG4_2

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

#ifdef OF_SOLARIS
# define SCTP_UNORDERED MSG_UNORDERED
#endif

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
	objc_release(_exception);

	[super dealloc];
}

-     (void)socket: (OFSCTPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	_done = true;
	_exception = objc_retain(exception);
}
@end

@implementation OFSCTPSocket
@dynamic delegate;

- (bool)of_createSocketForAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo
{
	const struct sctp_event_subscribe events = {
		.sctp_data_io_event = 1
	};
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
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

	if (setsockopt(_socket, IPPROTO_SCTP, SCTP_EVENTS, &events,
	    sizeof(events)) != 0) {
		*errNo = _OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		return false;
	}

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
	    objc_autorelease([[OFSCTPSocketConnectDelegate alloc] init]);
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

	[objc_autorelease([[OFAsyncIPSocketConnector alloc]
	    initWithSocket: self
		      host: host
		      port: port
		  delegate: _delegate
		   handler: NULL]) startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		   handler: (OFSCTPSocketConnectedHandler)handler
{
	[self asyncConnectToHost: host
			    port: port
		     runLoopMode: OFDefaultRunLoopMode
			 handler: handler];
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		   handler: (OFSCTPSocketConnectedHandler)handler
{
	void *pool = objc_autoreleasePoolPush();

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	[objc_autorelease([[OFAsyncIPSocketConnector alloc]
	    initWithSocket: self
		      host: host
		      port: port
		  delegate: nil
		   handler: handler]) startWithRunLoopMode: runLoopMode];

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

- (instancetype)accept
{
	const struct sctp_event_subscribe events = {
		.sctp_data_io_event = 1
	};
	OFSCTPSocket *accepted = [super accept];

	if (setsockopt(accepted->_socket, IPPROTO_SCTP, SCTP_EVENTS, &events,
	    sizeof(events)) != 0)
		@throw [OFAcceptSocketFailedException
		    exceptionWithSocket: self
				  errNo: _OFSocketErrNo()];

	return accepted;
}

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
	char cmsgBuffer[CMSG_SPACE(sizeof(struct sctp_sndrcvinfo))];
	struct msghdr msg = {
		.msg_iov = &iov,
		.msg_iovlen = 1,
		.msg_control = cmsgBuffer,
		.msg_controllen = sizeof(cmsgBuffer)
	};
	struct cmsghdr *cmsg;

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = recvmsg(_socket, &msg, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: _OFSocketErrNo()];

	if (info == NULL)
		return ret;

	*info = nil;

	for (cmsg = CMSG_FIRSTHDR(&msg); cmsg != NULL;
	    cmsg = CMSG_NXTHDR(&msg, cmsg)) {
		if (cmsg->cmsg_level != IPPROTO_SCTP)
			continue;

		if (cmsg->cmsg_type == SCTP_SNDRCV) {
			struct sctp_sndrcvinfo sndrcv;
			memcpy(&sndrcv, CMSG_DATA(cmsg), sizeof(sndrcv));
			OFNumber *streamID = [OFNumber numberWithUnsignedShort:
			    sndrcv.sinfo_stream];
			OFNumber *PPID = [OFNumber numberWithUnsignedLong:
			    OFFromBigEndian32(sndrcv.sinfo_ppid)];
			OFNumber *unordered = [OFNumber numberWithBool:
			    (sndrcv.sinfo_flags & SCTP_UNORDERED)];

			*info = [OFDictionary dictionaryWithKeysAndObjects:
			    OFSCTPStreamID, streamID,
			    OFSCTPPPID, PPID,
			    OFSCTPUnordered, unordered, nil];

			break;
		}
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
					   handler: NULL
# endif
					  delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)
    asyncReceiveWithInfoIntoBuffer: (void *)buffer
			    length: (size_t)length
			   handler: (OFSCTPSocketMessageReceivedHandler)handler
{
	[self asyncReceiveWithInfoIntoBuffer: buffer
				      length: length
				 runLoopMode: OFDefaultRunLoopMode
				     handler: handler];
}

- (void)
    asyncReceiveWithInfoIntoBuffer: (void *)buffer
			    length: (size_t)length
		       runLoopMode: (OFRunLoopMode)runLoopMode
			   handler: (OFSCTPSocketMessageReceivedHandler)handler
{
	[OFRunLoop of_addAsyncReceiveForSCTPSocket: self
					    buffer: buffer
					    length: length
					      mode: runLoopMode
					   handler: handler
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
	struct sctp_sndrcvinfo sndrcv = {
		.sinfo_stream = (uint16_t)
		    [[info objectForKey: OFSCTPStreamID] unsignedShortValue],
		.sinfo_ppid = OFToBigEndian32((uint32_t)
		    [[info objectForKey: OFSCTPPPID] unsignedLongValue]),
		.sinfo_flags = ([[info objectForKey: OFSCTPUnordered] boolValue]
		    ? SCTP_UNORDERED : 0)
	};
	char cmsgBuffer[CMSG_SPACE(sizeof(sndrcv))];
	struct cmsghdr *cmsg = (struct cmsghdr *)(void *)&cmsgBuffer;
	struct msghdr msg = {
		.msg_iov = &iov,
		.msg_iovlen = 1,
		.msg_control = &cmsgBuffer,
		.msg_controllen = sizeof(cmsgBuffer)
	};

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	cmsg->cmsg_level = IPPROTO_SCTP;
	cmsg->cmsg_type = SCTP_SNDRCV;
	cmsg->cmsg_len = CMSG_LEN(sizeof(sndrcv));
	memcpy(CMSG_DATA(cmsg), &sndrcv, sizeof(sndrcv));

	if ((bytesWritten = sendmsg(_socket, &msg, 0)) < 0)
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
					handler: NULL
# endif
				       delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncSendData: (OFData *)data
		 info: (OFSCTPMessageInfo)info
	      handler: (OFSCTPSocketDataSentHandler)handler
{
	[self asyncSendData: data
		       info: info
		runLoopMode: OFDefaultRunLoopMode
		    handler: handler];
}

- (void)asyncSendData: (OFData *)data
		 info: (OFSCTPMessageInfo)info
	  runLoopMode: (OFRunLoopMode)runLoopMode
	      handler: (OFSCTPSocketDataSentHandler)handler
{
	[OFRunLoop of_addAsyncSendForSCTPSocket: self
					   data: data
					   info: info
					   mode: runLoopMode
					handler: handler
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
