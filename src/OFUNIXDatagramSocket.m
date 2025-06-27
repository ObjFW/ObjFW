/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#include <errno.h>

#import "OFUNIXDatagramSocket.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"

#import "OFAlreadyOpenException.h"
#import "OFBindUNIXSocketFailedException.h"

@implementation OFUNIXDatagramSocket
@dynamic delegate;

- (OFSocketAddress)bindToPath: (OFString *)path
{
#ifndef OF_HURD
	OFSocketAddress address;
# if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
# endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if (path != nil)
		address = OFSocketAddressMakeUNIX(path);
	else {
		address.family = OFSocketAddressFamilyUnknown;
		address.length = 0;
	}

	if ((_socket = socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC, 0)) ==
	    OFInvalidSocketHandle)
		@throw [OFBindUNIXSocketFailedException
		    exceptionWithPath: path
			       socket: self
				errNo: _OFSocketErrNo()];

	_canBlock = true;

# if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
# endif

	if (path != nil) {
		if (bind(_socket, (struct sockaddr *)&address.sockaddr,
		    address.length) != 0) {
			int errNo = _OFSocketErrNo();

			closesocket(_socket);
			_socket = OFInvalidSocketHandle;

			@throw [OFBindUNIXSocketFailedException
			    exceptionWithPath: path
				       socket: self
					errNo: errNo];
		}
	}

	return address;
#else
	/*
	 * Datagram UNIX sockets on Hurd are broken and don't return the sender
	 * correctly when using recvfrom().
	 */
	@throw [OFBindUNIXSocketFailedException
	    exceptionWithPath: path
		       socket: self
			errNo: EAFNOSUPPORT];
#endif
}
@end
