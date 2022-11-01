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
{
#ifdef OF_MACOS
	const int one = 1;
	struct ATInterfaceConfig config = { { 0 } };
#endif
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	address = OFSocketAddressMakeAppleTalk(network, node, port);

#ifdef OF_MACOS
	if ((_socket = socket(address.sockaddr.at.sat_family,
	    SOCK_RAW | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle)
#else
	if ((_socket = socket(address.sockaddr.at.sat_family,
	    SOCK_DGRAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle)
#endif
		@throw [OFBindDDPSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
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
				  socket: self
				   errNo: EAFNOSUPPORT];
	}

#ifdef OF_MACOS
	if (setsockopt(_socket, ATPROTO_NONE, DDP_HDRINCL, &one, sizeof(one)) !=
	    0 ||
	    ioctl(_socket, _IOWR('a', 2, struct ATInterfaceConfig), &config) !=
	    0)
		@throw [OFBindDDPSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
				  socket: self
				   errNo: OFSocketErrNo()];

	OFSocketAddressSetAppleTalkNetwork(&address, config.address.s_net);
	OFSocketAddressSetAppleTalkNode(&address, config.address.s_node);
#endif

	return address;
}

#ifdef OF_MACOS
- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (OFSocketAddress *)sender
{
	ssize_t ret;
	at_ddp_t header;
	struct iovec iov[2] = {
		{ &header, offsetof(at_ddp_t, type) },
		{ buffer, length }
	};

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = readv(_socket, iov, 2)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: OFSocketErrNo()];

	*sender = OFSocketAddressMakeAppleTalk(
	    header.src_net[0] << 8 | header.src_net[1], header.src_node,
	    header.src_socket);

	ret -= offsetof(at_ddp_t, type);
	if (ret < 0)
		return 0;

	return ret;
}

- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const OFSocketAddress *)receiver
{
	at_ddp_t header = { 0 };
	struct iovec iov[2] = {
		{ &header, offsetof(at_ddp_t, type) },
		{ (void *)buffer, length }
	};
	struct msghdr msg = {
		.msg_name = (struct sockaddr *)&receiver->sockaddr,
		.msg_namelen = receiver->length,
		.msg_iov = iov,
		.msg_iovlen = 2
	};
	size_t packetLength = length + offsetof(at_ddp_t, type);
	uint16_t net;
	ssize_t bytesWritten;

	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (packetLength > DDP_DATAGRAM_SIZE)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: EMSGSIZE];

	net = OFSocketAddressAppleTalkNetwork(receiver);

	header.length_H = (packetLength >> 8) & 3;
	header.length_L = packetLength & 0xFF;
	header.dst_net[0] = net >> 8;
	header.dst_net[1] = net & 0xFF;
	header.dst_node = OFSocketAddressAppleTalkNode(receiver);
	header.dst_socket = OFSocketAddressAppleTalkPort(receiver);

	if ((bytesWritten = sendmsg(_socket, &msg, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: OFSocketErrNo()];

	if ((size_t)bytesWritten != packetLength) {
		bytesWritten -= offsetof(at_ddp_t, type);

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
