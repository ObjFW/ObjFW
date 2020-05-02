/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"

#import "socket.h"
#import "socket_helpers.h"

@implementation OFIPXSocket
@dynamic delegate;

- (of_socket_address_t)bindToPort: (uint16_t)port
		       packetType: (uint8_t)packetType
{
	const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
	of_socket_address_t address;
	int protocol = 0;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	address = of_socket_address_ipx(zeroNode, 0, port);

#ifdef OF_WINDOWS
	protocol = NSPROTO_IPX + packetType;
#else
	_packetType = address.sockaddr.ipx.sipx_type = packetType;
#endif

	if ((_socket = socket(address.sockaddr.sockaddr.sa_family,
	    SOCK_DGRAM | SOCK_CLOEXEC, protocol)) == INVALID_SOCKET)
		@throw [OFBindFailedException
		    exceptionWithPort: port
			   packetType: packetType
			       socket: self
				errNo: of_socket_errno()];

	_blocking = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (bind(_socket, &address.sockaddr.sockaddr, address.length) != 0) {
		int errNo = of_socket_errno();

		closesocket(_socket);
		_socket = INVALID_SOCKET;

		@throw [OFBindFailedException exceptionWithPort: port
						     packetType: packetType
							 socket: self
							  errNo: errNo];
	}

	memset(&address, 0, sizeof(address));
	address.family = OF_SOCKET_ADDRESS_FAMILY_IPX;
	address.length = (socklen_t)sizeof(address.sockaddr);

	if (of_getsockname(_socket, &address.sockaddr.sockaddr,
	    &address.length) != 0) {
		int errNo = of_socket_errno();

		closesocket(_socket);
		_socket = INVALID_SOCKET;

		@throw [OFBindFailedException exceptionWithPort: port
						     packetType: packetType
							 socket: self
							  errNo: errNo];
	}

	if (address.sockaddr.sockaddr.sa_family != AF_IPX) {
		closesocket(_socket);
		_socket = INVALID_SOCKET;

		@throw [OFBindFailedException exceptionWithPort: port
						     packetType: packetType
							 socket: self
							  errNo: EAFNOSUPPORT];
	}

	return address;
}

#ifndef OF_WINDOWS
- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const of_socket_address_t *)receiver
{
	of_socket_address_t fixedReceiver;

	memcpy(&fixedReceiver, receiver, sizeof(fixedReceiver));

	/* If it's not IPX, no fix-up needed - it will fail anyway. */
	if (fixedReceiver.family == OF_SOCKET_ADDRESS_FAMILY_IPX)
		fixedReceiver.sockaddr.ipx.sipx_type = _packetType;

	[super sendBuffer: buffer
		   length: length
		 receiver: &fixedReceiver];
}
#endif
@end
