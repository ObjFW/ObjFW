/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFStreamSocket.h"

#import "OFInitializationFailedException.h"
#import "OFNotImplementedException.h"
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
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	ssize_t ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

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

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = send(_socket, buffer, length, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: of_socket_errno()];
#else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = send(_socket, buffer, (int)length, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: of_socket_errno()];
#endif

	return (size_t)bytesWritten;
}

- (void)setBlocking: (bool)enable
{
#if defined(HAVE_FCNTL)
	bool readImplemented = false, writeImplemented = false;

	@try {
		int readFlags;

		readFlags = fcntl([self fileDescriptorForReading], F_GETFL);

		readImplemented = true;

		if (readFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self
					  errNo: errno];

		if (enable)
			readFlags &= ~O_NONBLOCK;
		else
			readFlags |= O_NONBLOCK;

		if (fcntl([self fileDescriptorForReading], F_SETFL,
		    readFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self
					  errNo: errno];
	} @catch (OFNotImplementedException *e) {
	}

	@try {
		int writeFlags;

		writeFlags = fcntl([self fileDescriptorForWriting], F_GETFL);

		writeImplemented = true;

		if (writeFlags == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self
					  errNo: errno];

		if (enable)
			writeFlags &= ~O_NONBLOCK;
		else
			writeFlags |= O_NONBLOCK;

		if (fcntl([self fileDescriptorForWriting], F_SETFL,
		    writeFlags) == -1)
			@throw [OFSetOptionFailedException
			    exceptionWithStream: self
					  errNo: errno];
	} @catch (OFNotImplementedException *e) {
	}

	if (!readImplemented && !writeImplemented)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	_blocking = enable;
#elif defined(OF_WINDOWS)
	u_long v = enable;

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithStream: self
				  errNo: of_socket_errno()];

	_blocking = enable;
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

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

	closesocket(_socket);
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
