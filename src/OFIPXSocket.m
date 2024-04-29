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
				   errNo: _OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (bind(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = _OFSocketErrNo();

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

	if (_OFGetSockName(_socket, (struct sockaddr *)&address.sockaddr,
	    &address.length) != 0) {
		int errNo = _OFSocketErrNo();

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
