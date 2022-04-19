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

#ifndef _XOPEN_SOURCE_EXTENDED
# define _XOPEN_SOURCE_EXTENDED
#endif
#define _HPUX_ALT_XOPEN_SOCKET_API

#include <errno.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFUDPSocket.h"
#import "OFUDPSocket+Private.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFThread.h"

#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"

@implementation OFUDPSocket
@dynamic delegate;

- (uint16_t)of_bindToAddress: (OFSocketAddress *)address
		   extraType: (int)extraType OF_DIRECT
{
	void *pool = objc_autoreleasePoolPush();
	uint16_t port;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if ((_socket = socket(address->sockaddr.sockaddr.sa_family,
	    SOCK_DGRAM | SOCK_CLOEXEC | extraType, 0)) == OFInvalidSocketHandle)
		@throw [OFBindFailedException
		    exceptionWithHost: OFSocketAddressString(address)
				 port: OFSocketAddressPort(address)
			       socket: self
				errNo: OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	/* {} needed to avoid warning with Clang 10 if next #if is false. */
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1) {
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
	}
#endif

#if defined(OF_HPUX) || defined(OF_WII) || defined(OF_NINTENDO_3DS)
	if (OFSocketAddressPort(address) != 0) {
#endif
		if (bind(_socket, &address->sockaddr.sockaddr,
		    address->length) != 0) {
			int errNo = OFSocketErrNo();

			closesocket(_socket);
			_socket = OFInvalidSocketHandle;

			@throw [OFBindFailedException
			    exceptionWithHost: OFSocketAddressString(address)
					 port: OFSocketAddressPort(address)
				       socket: self
					errNo: errNo];
		}
#if defined(OF_HPUX) || defined(OF_WII) || defined(OF_NINTENDO_3DS)
	} else {
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = (uint16_t)rand();

			OFSocketAddressSetPort(address, rnd);

			if ((ret = bind(_socket, &address->sockaddr.sockaddr,
			    address->length)) == 0)
				break;

			if (OFSocketErrNo() != EADDRINUSE) {
				int errNo = OFSocketErrNo();
				OFString *host = OFSocketAddressString(address);
				port = OFSocketAddressPort(address);

				closesocket(_socket);
				_socket = OFInvalidSocketHandle;

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

	if ((port = OFSocketAddressPort(address)) > 0)
		return port;

#if !defined(OF_HPUX) && !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	memset(address, 0, sizeof(*address));

	address->length = (socklen_t)sizeof(address->sockaddr);
	if (OFGetSockName(_socket, &address->sockaddr.sockaddr,
	    &address->length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindFailedException
		    exceptionWithHost: OFSocketAddressString(address)
				 port: OFSocketAddressPort(address)
			       socket: self
				errNo: errNo];
	}

	if (address->sockaddr.sockaddr.sa_family == AF_INET)
		return OFFromBigEndian16(address->sockaddr.in.sin_port);
# ifdef OF_HAVE_IPV6
	else if (address->sockaddr.sockaddr.sa_family == AF_INET6)
		return OFFromBigEndian16(address->sockaddr.in6.sin6_port);
# endif
	else {
		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindFailedException
		    exceptionWithHost: OFSocketAddressString(address)
				 port: OFSocketAddressPort(address)
			       socket: self
				errNo: EAFNOSUPPORT];
	}
#else
	closesocket(_socket);
	_socket = OFInvalidSocketHandle;

	@throw [OFBindFailedException
	    exceptionWithHost: OFSocketAddressString(address)
			 port: OFSocketAddressPort(address)
		       socket: self
			errNo: EADDRNOTAVAIL];
#endif
}

- (uint16_t)bindToHost: (OFString *)host port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	OFData *socketAddresses;
	OFSocketAddress address;

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	socketAddresses = [[OFThread DNSResolver]
	    resolveAddressesForHost: host
		      addressFamily: OFSocketAddressFamilyAny];

	address = *(OFSocketAddress *)[socketAddresses itemAtIndex: 0];
	OFSocketAddressSetPort(&address, port);

	port = [self of_bindToAddress: &address extraType: 0];

	objc_autoreleasePoolPop(pool);

	return port;
}
@end
