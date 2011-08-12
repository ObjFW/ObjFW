/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFSOCKS5Socket.h"

#import "OFConnectionFailedException.h"
#import "OFNotImplementedException.h"

@implementation OFSOCKS5Socket
+ socketWithProxyHost: (OFString*)host
		 port: (uint16_t)port
{
	return [[[self alloc] initWithProxyHost: host
					   port: port] autorelease];
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithProxyHost: (OFString*)host
	       port: (uint16_t)port
{
	self = [super init];

	@try {
		proxyHost = [host copy];
		proxyPort = port;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[proxyHost release];

	[super dealloc];
}

- (void)connectToHost: (OFString*)host
		 port: (uint16_t)port
{
	const char request[] = { 5, 1, 0, 3 };
	char reply[256];
	BOOL oldBuffersWrites;

	[super connectToHost: proxyHost
			port: proxyPort];

	/* 5 1 0 -> no authentication */
	[self writeNBytes: 3
	       fromBuffer: request];

	[self readExactlyNBytes: 2
		     intoBuffer: reply];

	if (reply[0] != 5 || reply[1] != 0) {
		[self close];
		@throw [OFConnectionFailedException newWithClass: isa
							  socket: self
							    host: proxyHost
							    port: proxyPort];
	}

	oldBuffersWrites = [self buffersWrites];
	[self setBuffersWrites: YES];

	/* CONNECT request */
	[self writeNBytes: 4
	       fromBuffer: request];
	[self writeInt8: [host cStringLength]];
	[self writeString: host];
	[self writeBigEndianInt16: port];

	[self flushWriteBuffer];
	[self setBuffersWrites: oldBuffersWrites];

	[self readExactlyNBytes: 4
		     intoBuffer: reply];

	if (reply[0] != 5 || reply[1] != 0 || reply[2] != 0) {
		[self close];
		@throw [OFConnectionFailedException newWithClass: isa
							  socket: self
							    host: host
							    port: port];
	}

	/* Skip the rest of the reply */
	switch (reply[3]) {
	case 1: /* IPv4 */
		[self readExactlyNBytes: 4
			     intoBuffer: reply];
		break;
	case 3: /* Domainname */
		[self readExactlyNBytes: [self readInt8]
			     intoBuffer: reply];
		break;
	case 4: /* IPv6 */
		[self readExactlyNBytes: 16
			     intoBuffer: reply];
		break;
	default:
		[self close];
		@throw [OFConnectionFailedException newWithClass: isa
							  socket: self
							    host: host
							    port: port];
	}

	[self readBigEndianInt16];
}
@end
