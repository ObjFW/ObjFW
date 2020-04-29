/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *module = @"OFSPXSocket";

@implementation TestsAppDelegate (OFSPXSocketTests)
- (void)SPXSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSPXSocket *sockClient, *sockServer, *sockAccepted;;
	of_socket_address_t address1;
	const of_socket_address_t *address2;
	unsigned char node[IPX_NODE_LEN], node2[IPX_NODE_LEN];
	uint32_t network;
	uint16_t port;
	char buffer[5];

	TEST(@"+[socket]", (sockClient = [OFSPXSocket socket]) &&
	    (sockServer = [OFSPXSocket socket]))

	@try {
		TEST(@"-[bindToPort:]",
		    R(address1 = [sockServer bindToPort: 0]))
	} @catch (OFBindFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			[self outputString: @"[OFSPXSocket] -[bindToPort:]: "
					    @"IPX unsupported, skipping tests\n"
				   inColor: GREEN];
			break;
		case EADDRNOTAVAIL:
			[self outputString: @"[OFSPXSocket] -[bindToPort:]: "
					    @"IPX not configured, skipping "
					    @"tests\n"
				   inColor: GREEN];
			break;
		default:
			@throw e;
		}

		objc_autoreleasePoolPop(pool);
		return;
	}

	of_socket_address_get_ipx_node(&address1, node);
	network = of_socket_address_get_ipx_network(&address1);
	port = of_socket_address_get_port(&address1);

	TEST(@"-[listen]", R([sockServer listen]))

	TEST(@"-[connectToNode:network:port:]",
	    R([sockClient connectToNode: node
				network: network
				   port: port]))

	TEST(@"-[accept]", (sockAccepted = [sockServer accept]))

	TEST(@"-[sendBuffer:length:]",
	    R([sockAccepted sendBuffer: "Hello"
				length: 5]))

	TEST(@"-[receiveIntoBuffer:length:]",
	    [sockClient receiveIntoBuffer: buffer
				   length: 5] == 5 &&
	    memcmp(buffer, "Hello", 5) == 0)

	TEST(@"-[remoteAddress]",
	    (address2 = sockAccepted.remoteAddress) &&
	    R(of_socket_address_get_ipx_node(address2, node2)) &&
	    memcmp(node, node2, IPX_NODE_LEN) == 0 &&
	    of_socket_address_get_ipx_network(address2) == network)

	objc_autoreleasePoolPop(pool);
}
@end
