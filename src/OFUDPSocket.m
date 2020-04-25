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

#import "OFUDPSocket.h"
#import "OFUDPSocket+Private.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFThread.h"

#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"

#import "socket.h"
#import "socket_helpers.h"

@implementation OFUDPSocket
@dynamic delegate;

- (uint16_t)of_bindToAddress: (of_socket_address_t *)address
		   extraType: (int)extraType
{
	void *pool = objc_autoreleasePoolPush();
	OFString *host;
	uint16_t port;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if ((_socket = socket(address->sockaddr.sockaddr.sa_family,
	    SOCK_DGRAM | SOCK_CLOEXEC | extraType, 0)) == INVALID_SOCKET) {
		host = of_socket_address_ip_string(address, &port);
		@throw [OFBindFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: of_socket_errno()];
	}

	_blocking = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	if (of_socket_address_get_port(address) != 0) {
#endif
		if (bind(_socket, &address->sockaddr.sockaddr,
		    address->length) != 0) {
			int errNo = of_socket_errno();

			closesocket(_socket);
			_socket = INVALID_SOCKET;

			host = of_socket_address_ip_string(address, &port);
			@throw [OFBindFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
		}
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	} else {
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = (uint16_t)rand();

			of_socket_address_set_port(address, rnd);

			if ((ret = bind(_socket, &address->sockaddr.sockaddr,
			    address->length)) == 0) {
				port = rnd;
				break;
			}

			if (of_socket_errno() != EADDRINUSE) {
				int errNo = of_socket_errno();

				closesocket(_socket);
				_socket = INVALID_SOCKET;

				host = of_socket_address_ip_string(
				    address, &port);
				@throw [OFBindFailedException
				    exceptionWithHost: host
						 port: port
					       socket: self
						errNo: errNo];
			}
		}
	}
#endif

	objc_autoreleasePoolPop(pool);

	if ((port = of_socket_address_get_port(address)) > 0)
		return port;

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	memset(address, 0, sizeof(*address));

	address->length = (socklen_t)sizeof(address->sockaddr);
	if (of_getsockname(_socket, &address->sockaddr.sockaddr,
	    &address->length) != 0) {
		int errNo = of_socket_errno();

		closesocket(_socket);
		_socket = INVALID_SOCKET;

		host = of_socket_address_ip_string(address, &port);
		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: errNo];
	}

	if (address->sockaddr.sockaddr.sa_family == AF_INET)
		return OF_BSWAP16_IF_LE(address->sockaddr.in.sin_port);
# ifdef OF_HAVE_IPV6
	else if (address->sockaddr.sockaddr.sa_family == AF_INET6)
		return OF_BSWAP16_IF_LE(address->sockaddr.in6.sin6_port);
# endif
	else {
		closesocket(_socket);
		_socket = INVALID_SOCKET;

		host = of_socket_address_ip_string(address, &port);
		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: EAFNOSUPPORT];
	}
#else
	closesocket(_socket);
	_socket = INVALID_SOCKET;

	host = of_socket_address_ip_string(address, &port);
	@throw [OFBindFailedException exceptionWithHost: host
						   port: port
						 socket: self
						  errNo: EADDRNOTAVAIL];
#endif
}

- (uint16_t)bindToHost: (OFString *)host
		  port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	OFData *socketAddresses;
	of_socket_address_t address;

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	socketAddresses = [[OFThread DNSResolver]
	    resolveAddressesForHost: host
		      addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY];

	address = *(of_socket_address_t *)[socketAddresses itemAtIndex: 0];
	of_socket_address_set_port(&address, port);

	port = [self of_bindToAddress: &address
			    extraType: 0];

	objc_autoreleasePoolPop(pool);

	return port;
}
@end
