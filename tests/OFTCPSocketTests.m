/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdlib.h>
#include <string.h>
#include <time.h>

#import "OFTCPSocket.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"
#import "macros.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFTCPSocket";

@implementation TestsAppDelegate (OFTCPSocketTests)
- (void)TCPSocketTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFTCPSocket *server, *client = nil, *accepted;
	OFString *service, *msg;
	uint16_t port;
	char buf[6];

	srand(time(NULL));
	port = (uint16_t)rand();
	if (port < 1024)
		port += 1024;
	service = [OFString stringWithFormat: @"%d", port];

	TEST(@"+[socket]", (server = [OFTCPSocket socket]) &&
	    (client = [OFTCPSocket socket]))

	msg = [OFString stringWithFormat:
	    @"-[bindService:onNode:withFamily:] (port %d)", port];
	TEST(msg, R([server bindService: service
				 onNode: @"127.0.0.1"
			     withFamily: AF_INET]))

	TEST(@"-[listen]", R([server listen]))

	TEST(@"-[connectToService:onNode:]",
	    R([client connectToService: service
				onNode: @"127.0.0.1"]))

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
