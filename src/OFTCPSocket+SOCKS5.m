/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFTCPSocket+SOCKS5.h"

#import "OFConnectionFailedException.h"

/* Reference for static linking */
int _OFTCPSocket_SOCKS5_reference;

@implementation OFTCPSocket (SOCKS5)
- (void)_SOCKS5ConnectToHost: (OFString*)host
			port: (uint16_t)port
{
	const char request[] = { 5, 1, 0, 3 };
	char reply[256];
	BOOL oldWriteBufferEnabled;

	/* 5 1 0 -> no authentication */
	[self writeBuffer: request
		   length: 3];

	[self readIntoBuffer: reply
		 exactLength: 2];

	if (reply[0] != 5 || reply[1] != 0) {
		[self close];
		@throw [OFConnectionFailedException
		    exceptionWithClass: isa
				socket: self
				  host: host
				  port: port];
	}

	oldWriteBufferEnabled = [self writeBufferEnabled];
	[self setWriteBufferEnabled: YES];

	/* CONNECT request */
	[self writeBuffer: request
		   length: 4];
	[self writeInt8:
	    [host cStringLengthWithEncoding: OF_STRING_ENCODING_NATIVE]];
	[self writeBuffer: [host cStringWithEncoding:
			       OF_STRING_ENCODING_NATIVE]
		   length: [host cStringLengthWithEncoding:
			       OF_STRING_ENCODING_NATIVE]];
	[self writeBigEndianInt16: port];

	[self flushWriteBuffer];
	[self setWriteBufferEnabled: oldWriteBufferEnabled];

	[self readIntoBuffer: reply
		 exactLength: 4];

	if (reply[0] != 5 || reply[1] != 0 || reply[2] != 0) {
		[self close];
		@throw [OFConnectionFailedException exceptionWithClass: isa
								socket: self
								  host: host
								  port: port];
	}

	/* Skip the rest of the reply */
	switch (reply[3]) {
	case 1: /* IPv4 */
		[self readIntoBuffer: reply
			 exactLength: 4];
		break;
	case 3: /* Domainname */
		[self readIntoBuffer: reply
			 exactLength: [self readInt8]];
		break;
	case 4: /* IPv6 */
		[self readIntoBuffer: reply
			 exactLength: 16];
		break;
	default:
		[self close];
		@throw [OFConnectionFailedException exceptionWithClass: isa
								socket: self
								  host: host
								  port: port];
	}

	[self readBigEndianInt16];
}
@end
