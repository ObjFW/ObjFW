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

static OFString *module = @"OFSPXStreamSocket";

@interface SPXStreamSocketDelegate: OFObject <OFSPXStreamSocketDelegate>
{
@public
	OFStreamSocket *_expectedServerSocket;
	OFSPXStreamSocket *_expectedClientSocket;
	unsigned char _expectedNode[IPX_NODE_LEN];
	uint32_t _expectedNetwork;
	uint16_t _expectedPort;
	bool _accepted;
	bool _connected;
}
@end

@implementation SPXStreamSocketDelegate
-    (bool)socket: (OFStreamSocket *)sock
  didAcceptSocket: (OFStreamSocket *)accepted
	exception: (id)exception
{
	OF_ENSURE(!_accepted);

	_accepted = (sock == _expectedServerSocket && accepted != nil &&
	    exception == nil);

	if (_accepted && _connected)
		[[OFRunLoop mainRunLoop] stop];

	return false;
}

-     (void)socket: (OFSPXStreamSocket *)sock
  didConnectToNode: (unsigned char [IPX_NODE_LEN])node
	   network: (uint32_t)network
	      port: (uint16_t)port
	 exception: (id)exception
{
	OF_ENSURE(!_connected);

	_connected = (sock == _expectedClientSocket &&
	    memcmp(node, _expectedNode, IPX_NODE_LEN) == 0 &&
	    network == _expectedNetwork && port == _expectedPort &&
	    exception == nil);

	if (_accepted && _connected)
		[[OFRunLoop mainRunLoop] stop];
}
@end

@implementation TestsAppDelegate (OFSPXStreamSocketTests)
- (void)SPXStreamSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSPXStreamSocket *sockClient, *sockServer, *sockAccepted;;
	of_socket_address_t address1;
	const of_socket_address_t *address2;
	unsigned char node[IPX_NODE_LEN], node2[IPX_NODE_LEN];
	uint32_t network;
	uint16_t port;
	char buffer[5];
	SPXStreamSocketDelegate *delegate;

	TEST(@"+[socket]", (sockClient = [OFSPXStreamSocket socket]) &&
	    (sockServer = [OFSPXStreamSocket socket]))

	@try {
		TEST(@"-[bindToPort:]",
		    R(address1 = [sockServer bindToPort: 0]))
	} @catch (OFBindFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			of_stdout.foregroundColor = [OFColor lime];
			[of_stdout writeLine:
			    @"[OFSPXStreamSocket] -[bindToPort:]: "
			    @"IPX unsupported, skipping tests"];
			break;
		case ESOCKTNOSUPPORT:
			of_stdout.foregroundColor = [OFColor lime];
			[of_stdout writeLine:
			    @"[OFSPXStreamSocket] -[bindToPort:]: "
			    @"SPX unsupported, skipping tests"];
			break;
		case EADDRNOTAVAIL:
			of_stdout.foregroundColor = [OFColor lime];
			[of_stdout writeLine:
			    @"[OFSPXStreamSocket] -[bindToPort:]: "
			    @"IPX not configured, skipping tests"];
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

	/* Test reassembly (this would not work with OFSPXSocket) */
	TEST(@"-[writeBuffer:length:]",
	    R([sockAccepted writeBuffer: "Hello"
				 length: 5]))

	TEST(@"-[readIntoBuffer:length:]",
	    [sockClient readIntoBuffer: buffer
				length: 2] == 2 &&
	    memcmp(buffer, "He", 2) == 0 &&
	    [sockClient readIntoBuffer: buffer
				length: 3] == 3 &&
	    memcmp(buffer, "llo", 3) == 0)

	TEST(@"-[remoteAddress]",
	    (address2 = sockAccepted.remoteAddress) &&
	    R(of_socket_address_get_ipx_node(address2, node2)) &&
	    memcmp(node, node2, IPX_NODE_LEN) == 0 &&
	    of_socket_address_get_ipx_network(address2) == network)

	delegate = [[[SPXStreamSocketDelegate alloc] init] autorelease];

	sockServer = [OFSPXStreamSocket socket];
	delegate->_expectedServerSocket = sockServer;
	sockServer.delegate = delegate;

	sockClient = [OFSPXStreamSocket socket];
	delegate->_expectedClientSocket = sockClient;
	sockClient.delegate = delegate;

	address1 = [sockServer bindToPort: 0];
	[sockServer listen];
	[sockServer asyncAccept];

	of_socket_address_get_ipx_node(&address1, node);
	memcpy(delegate->_expectedNode, node, IPX_NODE_LEN);
	delegate->_expectedNetwork = network =
	    of_socket_address_get_ipx_network(&address1);
	delegate->_expectedPort = port = of_socket_address_get_port(&address1);

	@try {
		[sockClient asyncConnectToNode: node
				       network: network
					  port: port];

		[[OFRunLoop mainRunLoop] runUntilDate:
		    [OFDate dateWithTimeIntervalSinceNow: 2]];

		TEST(@"-[asyncAccept] & -[asyncConnectToNode:network:port:]",
		    delegate->_accepted && delegate->_connected)
	} @catch (OFObserveFailedException *e) {
		switch (e.errNo) {
		case ENOTSOCK:
			of_stdout.foregroundColor = [OFColor lime];
			[of_stdout writeLine:
			    @"[OFSPXStreamSocket] -[asyncAccept] & "
			    @"-[asyncConnectToNode:network:port:]: select() "
			    @"not supported for SPX, skipping test"];
			break;
		default:
			@throw e;
		}
	}

	objc_autoreleasePoolPop(pool);
}
@end
