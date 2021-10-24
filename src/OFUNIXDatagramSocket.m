/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFUNIXDatagramSocket.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"

@implementation OFUNIXDatagramSocket
@dynamic delegate;

- (OFSocketAddress)bindToPath: (OFString *)path
{
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	address = OFSocketAddressMakeUNIX(path);

	if ((_socket = socket(address.sockaddr.sockaddr.sa_family,
	    SOCK_DGRAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle)
		@throw [OFBindFailedException
		    exceptionWithPath: path
			       socket: self
				errNo: OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (bind(_socket, &address.sockaddr.sockaddr, address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindFailedException exceptionWithPath: path
							 socket: self
							  errNo: errNo];
	}

	return address;
}
@end
