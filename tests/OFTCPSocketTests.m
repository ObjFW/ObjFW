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

#include <string.h>

#import "OFTCPSocket.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "macros.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFTCPSocket";

@implementation TestsAppDelegate (OFTCPSocketTests)
- (void)TCPSocketTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFTCPSocket *server, *client = nil, *accepted;
	uint16_t port;
	char buf[6];

	TEST(@"+[socket]", (server = [OFTCPSocket socket]) &&
	    (client = [OFTCPSocket socket]))

	TEST(@"-[bindToHost:port:]",
	    (port = [server bindToHost: @"127.0.0.1"
				  port: 0]))

	TEST(@"-[listen]", R([server listen]))

	TEST(@"-[connectToHost:port:]",
	    R([client connectToHost: @"127.0.0.1"
			       port: port]))

	TEST(@"-[accept]", (accepted = [server accept]))

	TEST(@"-[remoteAddress]",
	    [[accepted remoteAddress] isEqual: @"127.0.0.1"])

	TEST(@"-[writeString:]", [client writeString: @"Hello!"])

	TEST(@"-[readNBytes:intoBuffer:]", [accepted readNBytes: 6
						     intoBuffer: buf] &&
	    !memcmp(buf, "Hello!", 6))

	[pool drain];
}
@end
