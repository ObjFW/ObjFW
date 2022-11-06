/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFDDPSocket.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAlreadyConnectedException.h"
#import "OFBindDDPSocketFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotOpenException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#ifdef OF_HAVE_NETAT_APPLETALK_H
# include <netat/ddp.h>
# include <sys/ioctl.h>

/* Unfortulately, there is no struct for the following in userland headers */
struct ATInterfaceConfig {
	char interfaceName[16];
	unsigned int flags;
	struct at_addr address, router;
	unsigned short netStart, netEnd;
	at_nvestr_t zoneName;
};
#endif

@implementation OFDDPSocket
@dynamic delegate;

- (OFSocketAddress)bindToNetwork: (uint16_t)network
			    node: (uint8_t)node
			    port: (uint8_t)port
		    protocolType: (uint8_t)protocolType
{
#ifdef OF_MACOS
	const int one = 1;
	struct ATInterfaceConfig config = { { 0 } };
#endif
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (protocolType == 0)
		@throw [OFInvalidArgumentException exception];

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	address = OFSocketAddressMakeAppleTalk(network, node, port);

#if defined(OF_MACOS)
	if ((_socket = socket(address.sockaddr.at.sat_family,
	    SOCK_RAW | SOCK_CLOEXEC, protocolType)) == OFInvalidSocketHandle)
#elif defined(OF_WINDOWS)
	if ((_socket = socket(address.sockaddr.at.sat_family,
	    SOCK_DGRAM | SOCK_CLOEXEC, ATPROTO_BASE + protocolType)) ==
	    OFInvalidSocketHandle)
#else
	if ((_socket = socket(address.sockaddr.at.sat_family,
	    SOCK_DGRAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle)
#endif
		@throw [OFBindDDPSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			    protocolType: protocolType
				  socket: self
				   errNo: OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (bind(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindDDPSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			    protocolType: protocolType
				  socket: self
				   errNo: errNo];
	}

	memset(&address, 0, sizeof(address));
	address.family = OFSocketAddressFamilyAppleTalk;
	address.length = (socklen_t)sizeof(address.sockaddr);

	if (OFGetSockName(_socket, (struct sockaddr *)&address.sockaddr,
	    &address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindDDPSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			    protocolType: protocolType
				  socket: self
				   errNo: errNo];
	}

	if (address.sockaddr.at.sat_family != AF_APPLETALK) {
		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindDDPSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			    protocolType: protocolType
				  socket: self
				   errNo: EAFNOSUPPORT];
	}

#ifdef OF_MACOS
	if (setsockopt(_socket, ATPROTO_NONE, DDP_STRIPHDR, &one,
	    sizeof(one)) != 0 || ioctl(_socket, _IOWR('a', 2,
	    struct ATInterfaceConfig), &config) != 0)
		@throw [OFBindDDPSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			    protocolType: protocolType
				  socket: self
				   errNo: OFSocketErrNo()];

	OFSocketAddressSetAppleTalkNetwork(&address, config.address.s_net);
	OFSocketAddressSetAppleTalkNode(&address, config.address.s_node);
#endif

#if !defined(OF_MACOS) && !defined(OF_WINDOWS)
	_protocolType = protocolType;
#endif

	return address;
}

/*
 * Everybody but macOS and Windows is probably using a netatalk-compatible
 * implementation, which includes the protocol type as the first byte of the
 * data instead of considering it part of the header.
 *
 * The following overrides prepend the protocol type when sending and compare
 * and strip it when receiving.
 *
 * Unfortunately, the downside of this is that the only way to handle receiving
 * a packet with the wrong protocol type is to throw an exception with errNo
 * ENOMSG, while macOS and Windows just filter those out in the kernel.
 * Returning 0 would mean this is indistinguishable from an empty packet, so it
 * has to be an exception.
 */
#if !defined(OF_MACOS) && !defined(OF_WINDOWS)
- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (OFSocketAddress *)sender
{
	ssize_t ret;
	uint8_t protocolType;
	struct iovec iov[2] = {
		{ &protocolType, 1 },
		{ buffer, length }
	};
	struct msghdr msg = {
		.msg_name = (sender != NULL
		    ? (struct sockaddr *)&sender->sockaddr : NULL),
		.msg_namelen = (sender != NULL
		    ? (socklen_t)sizeof(sender->sockaddr) : 0),
		.msg_iov = iov,
		.msg_iovlen = 2
	};

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = recvmsg(_socket, &msg, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: OFSocketErrNo()];

	if (ret < 1 || protocolType != _protocolType)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: ENOMSG];

	if (sender != NULL) {
		sender->length = msg.msg_namelen;
		sender->family = OFSocketAddressFamilyAppleTalk;
	}

	return ret - 1;
}

- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const OFSocketAddress *)receiver
{
	struct iovec iov[2] = {
		{ &_protocolType, 1 },
		{ (void *)buffer, length }
	};
	struct msghdr msg = {
		.msg_name = (struct sockaddr *)&receiver->sockaddr,
		.msg_namelen = receiver->length,
		.msg_iov = iov,
		.msg_iovlen = 2
	};
	ssize_t bytesWritten;

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((bytesWritten = sendmsg(_socket, &msg, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: OFSocketErrNo()];

	if ((size_t)bytesWritten != length + 1) {
		bytesWritten--;

		if (bytesWritten < 0)
			bytesWritten = 0;

		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: 0];
	}
}
#endif
@end
