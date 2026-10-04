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

#import "OFAlreadyOpenException.h"
#import "OFBindIPSocketFailedException.h"
#import "OFInvalidArgumentException.h"

enum {
	flagAllowsIPv4  = 0x01,
	flagAllowsIPv6  = 0x02
};

@implementation OFUDPSocket
@dynamic delegate;

- (instancetype)init
{
	self = [super init];

	_flags = flagAllowsIPv4;
#ifdef OF_HAVE_IPV6
	_flags |= flagAllowsIPv6;
#endif

	return self;
}

- (void)of_bindToAddress: (OFSocketAddress *)address extraType: (int)extraType
{
#ifdef IPV6_V6ONLY
	const int one = 1;
#endif
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif
#if !defined(OF_HPUX) && !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	OFString *host;
	uint16_t port;
#endif

	if ((_socket = socket(
	    ((struct sockaddr *)&address->sockaddr)->sa_family,
	    SOCK_DGRAM | SOCK_CLOEXEC | extraType, 0)) == OFInvalidSocketHandle)
		@throw [OFBindIPSocketFailedException
		    exceptionWithHost: OFSocketAddressString(address)
				 port: OFSocketAddressIPPort(address)
			       socket: self
				errNo: _OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	/* {} needed to avoid warning with Clang 10 if next 2 #if is false. */
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1) {
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
	}
#endif

#ifdef IPV6_V6ONLY
	if ((_flags & (flagAllowsIPv4 | flagAllowsIPv6)) == flagAllowsIPv6) {
		if (setsockopt(_socket, IPPROTO_IPV6, IPV6_V6ONLY,
		    (char *)&one, (socklen_t)sizeof(one)) != 0) {
			int errNo = _OFSocketErrNo();

			closesocket(_socket);
			_socket = OFInvalidSocketHandle;

			@throw [OFBindIPSocketFailedException
			    exceptionWithHost: OFSocketAddressString(address)
					 port: OFSocketAddressIPPort(address)
				       socket: self
					errNo: errNo];
		}
	}
#endif

#if defined(OF_HPUX) || defined(OF_WII) || defined(OF_NINTENDO_3DS)
	if (OFSocketAddressIPPort(address) != 0) {
#endif
		if (bind(_socket, (struct sockaddr *)&address->sockaddr,
		    address->length) != 0) {
			int errNo = _OFSocketErrNo();

			closesocket(_socket);
			_socket = OFInvalidSocketHandle;

			@throw [OFBindIPSocketFailedException
			    exceptionWithHost: OFSocketAddressString(address)
					 port: OFSocketAddressIPPort(address)
				       socket: self
					errNo: errNo];
		}
#if defined(OF_HPUX) || defined(OF_WII) || defined(OF_NINTENDO_3DS)
	} else {
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = OFRandom16();

			OFSocketAddressSetIPPort(address, rnd);

			if ((ret = bind(_socket,
			    (struct sockaddr *)&address->sockaddr,
			    address->length)) == 0)
				break;

			if (_OFSocketErrNo() != EADDRINUSE) {
				int errNo = _OFSocketErrNo();
				OFString *host = OFSocketAddressString(address);
				uint16_t port = OFSocketAddressIPPort(address);

				closesocket(_socket);
				_socket = OFInvalidSocketHandle;

				@throw [OFBindIPSocketFailedException
				    exceptionWithHost: host
						 port: port
					       socket: self
						errNo: errNo];
			}
		}
	}
#endif

#if !defined(OF_HPUX) && !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	host = OFSocketAddressString(address);
	port = OFSocketAddressIPPort(address);

	OFFillMemory(address, 0, sizeof(*address));

	address->length = (socklen_t)sizeof(address->sockaddr);
	if (_OFGetSockName(_socket, (struct sockaddr *)&address->sockaddr,
	    &address->length) != 0) {
		int errNo = _OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPSocketFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
	}

	switch (((struct sockaddr *)&address->sockaddr)->sa_family) {
	case AF_INET:
		address->family = OFSocketAddressFamilyIPv4;
		break;
# ifdef OF_HAVE_IPV6
	case AF_INET6:
		address->family = OFSocketAddressFamilyIPv6;
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
#endif
}

- (void)setAllowsIPv4: (bool)allowsIPv4
{
	if (allowsIPv4)
		_flags |= flagAllowsIPv4;
	else
		_flags &= ~flagAllowsIPv4;
}

- (bool)allowsIPv4
{
	return (_flags & flagAllowsIPv4);
}

- (void)setAllowsIPv6: (bool)allowsIPv6
{
	if (allowsIPv6)
		_flags |= flagAllowsIPv6;
	else
		_flags &= ~flagAllowsIPv6;
}

- (bool)allowsIPv6
{
	return (_flags & flagAllowsIPv6);
}

- (OFSocketAddress)bindToHost: (OFString *)host port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	OFData *socketAddresses;
	OFSocketAddress address;

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	OFSocketAddressFamily addressFamily;
	if ((_flags & flagAllowsIPv4) && (_flags & flagAllowsIPv6))
		addressFamily = OFSocketAddressFamilyAny;
	else if (_flags & flagAllowsIPv4)
		addressFamily = OFSocketAddressFamilyIPv4;
	else if (_flags & flagAllowsIPv6)
		addressFamily = OFSocketAddressFamilyIPv6;
	else
		@throw [OFInvalidArgumentException exception];

	socketAddresses = [[OFThread DNSResolver]
	    resolveAddressesForHost: host
		      addressFamily: addressFamily];

	address = *(OFSocketAddress *)[socketAddresses itemAtIndex: 0];
	OFSocketAddressSetIPPort(&address, port);

	[self of_bindToAddress: &address extraType: 0];

	objc_autoreleasePoolPop(pool);

	return address;
}
@end
