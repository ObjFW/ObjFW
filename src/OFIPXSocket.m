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

#import "OFIPXSocket.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAlreadyOpenException.h"
#import "OFBindIPXSocketFailedException.h"

#ifndef NSPROTO_IPX
# define NSPROTO_IPX 0
#endif

@implementation OFIPXSocket
@dynamic delegate;

- (OFSocketAddress)bindToNetwork: (uint32_t)network
			    node: (const unsigned char [IPX_NODE_LEN])node
			    port: (uint16_t)port
		      packetType: (uint8_t)packetType
{
	OFSocketAddress address;
	int protocol = 0;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	address = OFSocketAddressMakeIPX(network, node, port);

#if defined(OF_WINDOWS) || defined(OF_FREEBSD)
	protocol = NSPROTO_IPX + packetType;
#else
	_packetType = address.sockaddr.ipx.sipx_type = packetType;
#endif

	if ((_socket = socket(address.sockaddr.ipx.sipx_family,
	    SOCK_DGRAM | SOCK_CLOEXEC, protocol)) == OFInvalidSocketHandle)
		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: packetType
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

		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: packetType
				  socket: self
				   errNo: errNo];
	}

	memset(&address, 0, sizeof(address));
	address.family = OFSocketAddressFamilyIPX;
	address.length = (socklen_t)sizeof(address.sockaddr);

	if (OFGetSockName(_socket, (struct sockaddr *)&address.sockaddr,
	    &address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: packetType
				  socket: self
				   errNo: errNo];
	}

	if (address.sockaddr.ipx.sipx_family != AF_IPX) {
		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: packetType
				  socket: self
				   errNo: EAFNOSUPPORT];
	}

	return address;
}

#if !defined(OF_WINDOWS) && !defined(OF_FREEBSD)
- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const OFSocketAddress *)receiver
{
	OFSocketAddress fixedReceiver;

	memcpy(&fixedReceiver, receiver, sizeof(fixedReceiver));

	/* If it's not IPX, no fix-up needed - it will fail anyway. */
	if (fixedReceiver.family == OFSocketAddressFamilyIPX)
		fixedReceiver.sockaddr.ipx.sipx_type = _packetType;

	[super sendBuffer: buffer length: length receiver: &fixedReceiver];
}
#endif
@end
