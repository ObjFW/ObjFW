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

#include "config.h"

#include <errno.h>

#import "OFTCPSocket+SOCKS5.h"
#import "OFData.h"

#import "OFConnectionFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#import "socket_helpers.h"

/* Reference for static linking */
int _OFTCPSocket_SOCKS5_reference;

static void
sendOrThrow(OFTCPSocket *self, of_socket_t sock, char *buffer, int length)
{
#ifndef OF_WINDOWS
	ssize_t bytesWritten;
#else
	int bytesWritten;
#endif

	if ((bytesWritten = send(sock, (const void *)buffer, length, 0)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: of_socket_errno()];

	if ((int)bytesWritten != length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: 0];
}

static void
recvExact(OFTCPSocket *self, of_socket_t sock, char *buffer, int length)
{
	while (length > 0) {
		ssize_t ret = recv(sock, (void *)buffer, length, 0);

		if (ret < 0)
			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: length
					  errNo: of_socket_errno()];

		buffer += ret;
		length -= ret;
	}
}

@implementation OFTCPSocket (SOCKS5)
- (void)OF_SOCKS5ConnectToHost: (OFString *)host
			  port: (uint16_t)port
{
	char request[] = { 5, 1, 0, 3 };
	char reply[256];
	void *pool;
	OFMutableData *connectRequest;

	if ([host UTF8StringLength] > 255)
		@throw [OFOutOfRangeException exception];

	/* 5 1 0 -> no authentication */
	sendOrThrow(self, _socket, request, 3);

	recvExact(self, _socket, reply, 2);

	if (reply[0] != 5 || reply[1] != 0) {
		[self close];
		@throw [OFConnectionFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: EPROTONOSUPPORT];
	}

	/* CONNECT request */
	pool = objc_autoreleasePoolPush();
	connectRequest = [OFMutableData data];

	[connectRequest addItems: request
			   count: 4];

	request[0] = [host UTF8StringLength];
	[connectRequest addItem: request];
	[connectRequest addItems: [host UTF8String]
			   count: request[0]];

	request[0] = port >> 8;
	request[1] = port & 0xFF;
	[connectRequest addItems: request
			   count: 2];

	if ([connectRequest count] > INT_MAX)
		@throw [OFOutOfRangeException exception];

	sendOrThrow(self, _socket,
	    [connectRequest items], (int)[connectRequest count]);

	objc_autoreleasePoolPop(pool);

	recvExact(self, _socket, reply, 4);

	if (reply[0] != 5 || reply[2] != 0) {
		[self close];
		@throw [OFConnectionFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: EPROTONOSUPPORT];
	}

	if (reply[1] != 0) {
		int errNo;

		[self close];

		switch (reply[1]) {
		case 0x02:
			errNo = EACCES;
			break;
		case 0x03:
			errNo = ENETUNREACH;
			break;
		case 0x04:
			errNo = EHOSTUNREACH;
			break;
		case 0x05:
			errNo = ECONNREFUSED;
			break;
		case 0x06:
			errNo = ETIMEDOUT;
			break;
		case 0x07:
			errNo = EPROTONOSUPPORT;
			break;
		case 0x08:
			errNo = EAFNOSUPPORT;
			break;
		default:
			errNo = 0;
			break;
		}

		@throw [OFConnectionFailedException exceptionWithHost: host
								 port: port
							       socket: self
								errNo: errNo];
	}

	/* Skip the rest of the reply */
	switch (reply[3]) {
	case 1: /* IPv4 */
		recvExact(self, _socket, reply, 4);
		break;
	case 3: /* Domain name */
		recvExact(self, _socket, reply, 1);
		recvExact(self, _socket, reply, reply[0]);
		break;
	case 4: /* IPv6 */
		recvExact(self, _socket, reply, 16);
		break;
	default:
		[self close];
		@throw [OFConnectionFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: EPROTONOSUPPORT];
	}

	recvExact(self, _socket, reply, 2);
}
@end
