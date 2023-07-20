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

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFUNIXStreamSocket.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"

#import "OFAlreadyOpenException.h"
#import "OFBindUNIXSocketFailedException.h"
#import "OFConnectUNIXSocketFailedException.h"

@implementation OFUNIXStreamSocket
@dynamic delegate;

- (void)connectToPath: (OFString *)path
{
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	address = OFSocketAddressMakeUNIX(path);

	if ((_socket = socket(address.sockaddr.un.sun_family,
	    SOCK_STREAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle)
		@throw [OFConnectUNIXSocketFailedException
		    exceptionWithPath: path
			       socket: self
				errNo: OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (connect(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFConnectUNIXSocketFailedException
		    exceptionWithPath: path
			       socket: self
				errNo: errNo];
	}
}

- (void)bindToPath: (OFString *)path
{
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	address = OFSocketAddressMakeUNIX(path);

	if ((_socket = socket(address.sockaddr.un.sun_family,
	    SOCK_STREAM | SOCK_CLOEXEC, 0)) == OFInvalidSocketHandle)
		@throw [OFBindUNIXSocketFailedException
		    exceptionWithPath: path
			       socket: self
				errNo: OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (bind(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindUNIXSocketFailedException
		    exceptionWithPath: path
			       socket: self
				errNo: errNo];
	}
}
@end
