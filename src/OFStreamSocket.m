/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#define __NO_EXT_QNX

#include "config.h"

#include <errno.h>
#include <string.h>

#import "OFStreamSocket.h"

#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

#import "socket_helpers.h"

@implementation OFStreamSocket
+ (void)initialize
{
	if (self != [OFStreamSocket class])
		return;

	if (!of_socket_init())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: ENOTCONN];

#ifndef OF_WINDOWS
	if ((ret = recv(_socket, buffer, length, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#else
	if (length > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = recv(_socket, buffer, (unsigned int)length, 0)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#endif

	if (ret == 0)
		_atEndOfStream = true;

	return ret;
}

- (void)lowlevelWriteBuffer: (const void*)buffer
		     length: (size_t)length
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
							     errNo: ENOTCONN];

#ifndef OF_WINDOWS
	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (send(_socket, buffer, length, 0) != (ssize_t)length)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if (send(_socket, buffer, (int)length, 0) != (int)length)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#endif
}

#ifdef OF_WINDOWS
- (void)setBlocking: (bool)enable
{
	u_long v = enable;
	_blocking = enable;

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithStream: self
				  errNo: of_socket_errno()];
}
#endif

- (int)fileDescriptorForReading
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (void)close
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	close(_socket);
	_socket = INVALID_SOCKET;

	_atEndOfStream = false;

	[super close];
}

- (void)dealloc
{
	if (_socket != INVALID_SOCKET)
		[self close];

	[super dealloc];
}
@end
