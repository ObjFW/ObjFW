/*
 * Copyright (c) 2008 - 2009
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
#import "OFMacros.h"

#import "main.h"

static OFString *module = @"OFTCPSocket";

void
tcpsocket_tests()
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFSocket *server, *client = nil, *accepted;
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
	TEST(msg, [server bindService: service
			       onNode: @"localhost"
			   withFamily: AF_INET])

	TEST(@"-[listen]", [server listen])

	TEST(@"-[connectToService:onNode:]",
	    [client connectToService: service
			      onNode: @"localhost"])

	TEST(@"-[accept]", (accepted = [server accept]))

	TEST(@"-[writeString:]", [client writeString: @"Hello!"])

	TEST(@"-[readNBytes:intoBuffer:]", [accepted readNBytes: 6
						     intoBuffer: buf] &&
	    !memcmp(buf, "Hello!", 6))

	[pool release];
}
