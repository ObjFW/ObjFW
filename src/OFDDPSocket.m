/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFPair.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAlreadyOpenException.h"
#import "OFBindDDPSocketFailedException.h"
#import "OFGetOptionFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

#ifdef HAVE_NET_IF_H
# include <net/if.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif

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

#ifdef OF_HAVE_APPLETALK_IFCONFIG
const OFAppleTalkInterfaceConfigurationKey
    OFAppleTalkInterfaceConfigurationNode =
    @"OFAppleTalkInterfaceConfigurationNode";
const OFAppleTalkInterfaceConfigurationKey
    OFAppleTalkInterfaceConfigurationNetwork =
    @"OFAppleTalkInterfaceConfigurationNetwork";
const OFAppleTalkInterfaceConfigurationKey
    OFAppleTalkInterfaceConfigurationPhase =
    @"OFAppleTalkInterfaceConfigurationPhase";
const OFAppleTalkInterfaceConfigurationKey
    OFAppleTalkInterfaceConfigurationNetworkRange =
    @"OFAppleTalkInterfaceConfigurationNetworkRange";
#endif

@implementation OFDDPSocket
@dynamic delegate;

#ifdef OF_HAVE_APPLETALK_IFCONFIG
+ (void)setConfiguration: (OFAppleTalkInterfaceConfiguration)config
	    forInterface: (OFString *)interfaceName
{
	OFNumber *network, *node, *phase;
	OFPair OF_GENERIC(OFNumber *, OFNumber *) *range;
	int sock;
	struct ifreq request;
	struct sockaddr_at *sat;
	uint16_t rangeStart, rangeEnd;

	if (interfaceName.UTF8StringLength > IFNAMSIZ - 1)
		@throw [OFOutOfRangeException exception];

	network = [config
	    objectForKey: OFAppleTalkInterfaceConfigurationNetwork];
	node = [config objectForKey: OFAppleTalkInterfaceConfigurationNode];
	phase = [config objectForKey: OFAppleTalkInterfaceConfigurationPhase];
	range = [config
	    objectForKey: OFAppleTalkInterfaceConfigurationNetworkRange];

	if (network == nil || node == nil)
		@throw [OFInvalidArgumentException exception];

	if (phase != nil && phase.unsignedCharValue != 1 &&
	    phase.unsignedCharValue != 2)
		@throw [OFInvalidArgumentException exception];

# ifdef OF_MACOS
	if ((sock = socket(AF_APPLETALK, SOCK_RAW, 0)) < 0)
# else
	if ((sock = socket(AF_APPLETALK, SOCK_DGRAM, 0)) < 0)
# endif
		@throw [OFSetOptionFailedException
		    exceptionWithObject: nil
				  errNo: OFSocketErrNo()];

	memset(&request, 0, sizeof(request));
	strncpy(request.ifr_name, interfaceName.UTF8String, IFNAMSIZ - 1);
	sat = (struct sockaddr_at *)&request.ifr_addr;
	sat->sat_family = AF_APPLETALK;
	sat->sat_net = OFToBigEndian16(network.unsignedShortValue);
	sat->sat_node = node.unsignedCharValue;
	/*
	 * The netrange is hidden in sat_zero and different OSes use different
	 * struct names for it, so the portable way is setting sat_zero
	 * directly.
	 */
	sat->sat_zero[0] = (phase != nil ? phase.unsignedCharValue : 2);
	if (range != nil) {
		rangeStart = [range.firstObject unsignedShortValue];
		rangeEnd = [range.secondObject unsignedShortValue];
	} else {
		rangeStart = rangeEnd = network.unsignedShortValue;
	}
	sat->sat_zero[2] = rangeStart >> 8;
	sat->sat_zero[3] = rangeStart & 0xFF;
	sat->sat_zero[4] = rangeEnd >> 8;
	sat->sat_zero[5] = rangeEnd & 0xFF;

	if (ioctl(sock, SIOCSIFADDR, &request) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: nil
				  errNo: OFSocketErrNo()];

	close(sock);
}

+ (OFAppleTalkInterfaceConfiguration)
    configurationForInterface: (OFString *)interfaceName
{
	int sock;
	struct ifreq request;
	struct sockaddr_at *sat;
# ifndef OF_LINUX
	uint16_t rangeStart, rangeEnd;
	OFPair *range;
# endif

	if (interfaceName.UTF8StringLength > IFNAMSIZ - 1)
		@throw [OFOutOfRangeException exception];

# ifdef OF_MACOS
	if ((sock = socket(AF_APPLETALK, SOCK_RAW, 0)) < 0)
# else
	if ((sock = socket(AF_APPLETALK, SOCK_DGRAM, 0)) < 0)
# endif
		@throw [OFGetOptionFailedException
		    exceptionWithObject: nil
				  errNo: OFSocketErrNo()];

	memset(&request, 0, sizeof(request));
	strncpy(request.ifr_name, interfaceName.UTF8String, IFNAMSIZ - 1);

	if (ioctl(sock, SIOCGIFADDR, &request) < 0) {
		int errNo = OFSocketErrNo();

		/* No AppleTalk configured on this interface. */
		if (errNo == EADDRNOTAVAIL) {
			close(sock);
			return nil;
		}

		@throw [OFGetOptionFailedException exceptionWithObject: nil
								 errNo: errNo];
	}

	sat = (struct sockaddr_at *)&request.ifr_addr;

	close(sock);

# ifndef OF_LINUX
	/*
	 * Linux currently doesn't fill out the phase or netrange.
	 *
	 * The netrange is hidden in sat_zero and different OSes use different
	 * struct names for it, so the portable way is setting sat_zero
	 * directly.
	 */
	rangeStart = sat->sat_zero[2] << 8 | sat->sat_zero[3];
	rangeEnd = sat->sat_zero[4] << 8 | sat->sat_zero[5];
	range = [OFPair
	    pairWithFirstObject: [OFNumber numberWithUnsignedShort: rangeStart]
		   secondObject: [OFNumber numberWithUnsignedShort: rangeEnd]];
# endif

	return [OFDictionary dictionaryWithKeysAndObjects:
	    OFAppleTalkInterfaceConfigurationNode,
	    [OFNumber numberWithUnsignedChar: sat->sat_node],
	    OFAppleTalkInterfaceConfigurationNetwork,
	    [OFNumber numberWithUnsignedShort: OFFromBigEndian16(sat->sat_net)],
# ifndef OF_LINUX
	    OFAppleTalkInterfaceConfigurationPhase,
	    [OFNumber numberWithUnsignedChar: sat->sat_zero[0]],
	    OFAppleTalkInterfaceConfigurationNetworkRange, range,
# endif
	    nil];
}

+ (void)removeConfigurationForInterface: (OFString *)interfaceName
{
	int sock;
	struct ifreq request;

	if (interfaceName.UTF8StringLength > IFNAMSIZ - 1)
		@throw [OFOutOfRangeException exception];

# ifdef OF_MACOS
	if ((sock = socket(AF_APPLETALK, SOCK_RAW, 0)) < 0)
# else
	if ((sock = socket(AF_APPLETALK, SOCK_DGRAM, 0)) < 0)
# endif
		@throw [OFSetOptionFailedException
		    exceptionWithObject: nil
				  errNo: OFSocketErrNo()];

	/*
	 * NetBSD requires the address to be removed, while Linux ignores the
	 * address entirely.
	 */

	memset(&request, 0, sizeof(request));
	strncpy(request.ifr_name, interfaceName.UTF8String, IFNAMSIZ - 1);

	if (ioctl(sock, SIOCGIFADDR, &request) != 0)
		if (errno != EADDRNOTAVAIL)
			@throw [OFSetOptionFailedException
			    exceptionWithObject: nil
					  errNo: OFSocketErrNo()];

	if (ioctl(sock, SIOCDIFADDR, &request) != 0)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: nil
				  errNo: OFSocketErrNo()];
}
#endif

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
		@throw [OFAlreadyOpenException exceptionWithObject: self];

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
