/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFSPXStreamSocket";

@interface SPXStreamSocketDelegate: OFObject <OFSPXStreamSocketDelegate>
{
@public
	OFStreamSocket *_expectedServerSocket;
	OFSPXStreamSocket *_expectedClientSocket;
	uint32_t _expectedNetwork;
	unsigned char _expectedNode[IPX_NODE_LEN];
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
	OFEnsure(!_accepted);

	_accepted = (sock == _expectedServerSocket && accepted != nil &&
	    exception == nil);

	if (_accepted && _connected)
		[[OFRunLoop mainRunLoop] stop];

	return false;
}

-	 (void)socket: (OFSPXStreamSocket *)sock
  didConnectToNetwork: (uint32_t)network
		 node: (unsigned char [IPX_NODE_LEN])node
		 port: (uint16_t)port
	    exception: (id)exception
{
	OFEnsure(!_connected);

	_connected = (sock == _expectedClientSocket &&
	    network == _expectedNetwork &&
	    memcmp(node, _expectedNode, IPX_NODE_LEN) == 0 &&
	    port == _expectedPort && exception == nil);

	if (_accepted && _connected)
		[[OFRunLoop mainRunLoop] stop];
}
@end

@implementation TestsAppDelegate (OFSPXStreamSocketTests)
- (void)SPXStreamSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSPXStreamSocket *sockClient, *sockServer = nil, *sockAccepted;
	OFSocketAddress address1;
	const OFSocketAddress *address2;
	uint32_t network;
	unsigned char node[IPX_NODE_LEN], node2[IPX_NODE_LEN];
	uint16_t port;
	char buffer[5];
	SPXStreamSocketDelegate *delegate;

	TEST(@"+[socket]", (sockClient = [OFSPXStreamSocket socket]) &&
	    (sockServer = [OFSPXStreamSocket socket]))

	@try {
		TEST(@"-[bindToPort:]",
		    R(address1 = [sockServer bindToPort: 0]))
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXStreamSocket] -[bindToPort:]: "
			    @"IPX unsupported, skipping tests"];
			break;
		case ESOCKTNOSUPPORT:
		case EPROTONOSUPPORT:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXStreamSocket] -[bindToPort:]: "
			    @"SPX unsupported, skipping tests"];
			break;
		case EADDRNOTAVAIL:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXStreamSocket] -[bindToPort:]: "
			    @"IPX not configured, skipping tests"];
			break;
		default:
			@throw e;
		}

		objc_autoreleasePoolPop(pool);
		return;
	}

	network = OFSocketAddressIPXNetwork(&address1);
	OFSocketAddressIPXNode(&address1, node);
	port = OFSocketAddressPort(&address1);

	TEST(@"-[listen]", R([sockServer listen]))

	TEST(@"-[connectToNetwork:node:port:]",
	    R([sockClient connectToNetwork: network node: node port: port]))

	TEST(@"-[accept]", (sockAccepted = [sockServer accept]))

	/* Test reassembly (this would not work with OFSPXSocket) */
	TEST(@"-[writeBuffer:length:]",
	    R([sockAccepted writeBuffer: "Hello" length: 5]))

	TEST(@"-[readIntoBuffer:length:]",
	    [sockClient readIntoBuffer: buffer length: 2] == 2 &&
	    memcmp(buffer, "He", 2) == 0 &&
	    [sockClient readIntoBuffer: buffer length: 3] == 3 &&
	    memcmp(buffer, "llo", 3) == 0)

	TEST(@"-[remoteAddress]",
	    (address2 = sockAccepted.remoteAddress) &&
	    OFSocketAddressIPXNetwork(address2) == network &&
	    R(OFSocketAddressIPXNode(address2, node2)) &&
	    memcmp(node, node2, IPX_NODE_LEN) == 0)

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

	delegate->_expectedNetwork = network =
	    OFSocketAddressIPXNetwork(&address1);
	OFSocketAddressIPXNode(&address1, node);
	memcpy(delegate->_expectedNode, node, IPX_NODE_LEN);
	delegate->_expectedPort = port = OFSocketAddressPort(&address1);

	@try {
		[sockClient asyncConnectToNetwork: network
					     node: node
					     port: port];

		[[OFRunLoop mainRunLoop] runUntilDate:
		    [OFDate dateWithTimeIntervalSinceNow: 2]];

		TEST(@"-[asyncAccept] & -[asyncConnectToNetwork:node:port:]",
		    delegate->_accepted && delegate->_connected)
	} @catch (OFObserveKernelEventsFailedException *e) {
		switch (e.errNo) {
		case ENOTSOCK:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXStreamSocket] -[asyncAccept] & "
			    @"-[asyncConnectToNetwork:node:port:]: select() "
			    @"not supported for SPX, skipping test"];
			break;
		default:
			@throw e;
		}
	}

	objc_autoreleasePoolPop(pool);
}
@end
