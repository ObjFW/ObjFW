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

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFUNIXStreamSocket.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"

#import "OFAlreadyOpenException.h"
#import "OFBindUNIXSocketFailedException.h"
#import "OFConnectUNIXSocketFailedException.h"
#import "OFGetOptionFailedException.h"

OFUNIXSocketCredentialsKey OFUNIXSocketCredentialsUserID =
    @"OFUNIXSocketCredentialsUserID";
OFUNIXSocketCredentialsKey OFUNIXSocketCredentialsGroupID =
    @"OFUNIXSocketCredentialsGroupID";
OFUNIXSocketCredentialsKey OFUNIXSocketCredentialsProcessID =
    @"OFUNIXSocketCredentialsProcessID";

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
				errNo: _OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (connect(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = _OFSocketErrNo();

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
				errNo: _OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

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

- (OFUNIXSocketCredentials)peerCredentials
{
#if defined(OF_LINUX)
	struct ucred ucred;
	socklen_t len = (socklen_t)sizeof(ucred);

	if (getsockopt(_socket, SOL_SOCKET, SO_PEERCRED, &ucred, &len) != 0 ||
	    len != sizeof(ucred))
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	return [OFDictionary dictionaryWithKeysAndObjects:
	    OFUNIXSocketCredentialsProcessID,
	    [OFNumber numberWithUnsignedLong: ucred.pid],
	    OFUNIXSocketCredentialsUserID,
	    [OFNumber numberWithUnsignedLong: ucred.uid],
	    OFUNIXSocketCredentialsGroupID,
	    [OFNumber numberWithUnsignedLong: ucred.gid],
	    nil];
#elif defined(HAVE_GETPEEREID)
	uid_t UID;
	gid_t GID;

	if (getpeereid(_socket, &UID, &GID) != 0)
		@throw [OFGetOptionFailedException
		    exceptionWithObject: self
				  errNo: _OFSocketErrNo()];

	return [OFDictionary dictionaryWithKeysAndObjects:
	    OFUNIXSocketCredentialsUserID,
	    [OFNumber numberWithUnsignedLong: UID],
	    OFUNIXSocketCredentialsGroupID,
	    [OFNumber numberWithUnsignedLong: GID],
	    nil];
#else
	return [OFDictionary dictionary];
#endif
}
@end
