/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include <string.h>

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
	    [of_socket_address_ip_string([accepted remoteAddress], NULL)
	    isEqual: @"127.0.0.1"])

	TEST(@"-[writeString:]", [client writeString: @"Hello!"])

	TEST(@"-[readIntoBuffer:length:]", [accepted readIntoBuffer: buf
							     length: 6] &&
	    !memcmp(buf, "Hello!", 6))

	[pool drain];
}
@end
