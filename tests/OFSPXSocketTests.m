/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFSPXSocket";

@interface SPXSocketDelegate: OFObject <OFSPXSocketDelegate>
{
@public
	OFSequencedPacketSocket *_expectedServerSocket;
	OFSPXSocket *_expectedClientSocket;
	unsigned char _expectedNode[IPX_NODE_LEN];
	uint32_t _expectedNetwork;
	uint16_t _expectedPort;
	bool _accepted;
	bool _connected;
}
@end

@implementation SPXSocketDelegate
-    (bool)socket: (OFSequencedPacketSocket *)sock
  didAcceptSocket: (OFSequencedPacketSocket *)accepted
	exception: (id)exception
{
	OFEnsure(!_accepted);

	_accepted = (sock == _expectedServerSocket && accepted != nil &&
	    exception == nil);

	if (_accepted && _connected)
		[[OFRunLoop mainRunLoop] stop];

	return false;
}

-	 (void)socket: (OFSPXSocket *)sock
  didConnectToNetwork: (uint32_t)network
		 node: (const unsigned char [IPX_NODE_LEN])node
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

@implementation TestsAppDelegate (OFSPXSocketTests)
- (void)SPXSocketTests
{
	const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
	void *pool = objc_autoreleasePoolPush();
	OFSPXSocket *sockClient, *sockServer = nil, *sockAccepted;
	OFSocketAddress address1;
	const OFSocketAddress *address2;
	uint32_t network;
	unsigned char node[IPX_NODE_LEN], node2[IPX_NODE_LEN];
	uint16_t port;
	OFDictionary *networkInterfaces;
	char buffer[5];
	SPXSocketDelegate *delegate;

	TEST(@"+[socket]", (sockClient = [OFSPXSocket socket]) &&
	    (sockServer = [OFSPXSocket socket]))

	@try {
		TEST(@"-[bindToNetwork:node:port:]",
		    R(address1 = [sockServer bindToNetwork: 0
						      node: zeroNode
						      port: 0]))
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXSocket] -[bindToNetwork:node:port:]: "
			    @"IPX unsupported, skipping tests"];
			break;
		case ESOCKTNOSUPPORT:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXSocket] -[bindToNetwork:node:port:]: "
			    @"SPX unsupported, skipping tests"];
			break;
		case EADDRNOTAVAIL:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXSocket] -[bindToNetwork:node:port:]: "
			    @"IPX not configured, skipping tests"];
			break;
		default:
			@throw e;
		}

		objc_autoreleasePoolPop(pool);
		return;
	}

	network = OFSocketAddressIPXNetwork(&address1);
	OFSocketAddressGetIPXNode(&address1, node);
	port = OFSocketAddressIPXPort(&address1);

	TEST(@"-[listen]", R([sockServer listen]))

	/*
	 * Find any network interface with IPX and send to it. Any should be
	 * fine since we bound to 0.0.
	 */
	networkInterfaces = [OFSystemInfo networkInterfaces];
	for (OFString *name in networkInterfaces) {
		OFNetworkInterface interface = [networkInterfaces
		    objectForKey: name];
		OFData *addresses = [interface
		    objectForKey: OFNetworkInterfaceIPXAddresses];

		if (addresses.count == 0)
			continue;

		network = OFSocketAddressIPXNetwork([addresses itemAtIndex: 0]);
		OFSocketAddressGetIPXNode([addresses itemAtIndex: 0], node);
	}

	TEST(@"-[connectToNetwork:node:port:]",
	    R([sockClient connectToNetwork: network node: node port: port]))

	TEST(@"-[accept]", (sockAccepted = [sockServer accept]))

	TEST(@"-[sendBuffer:length:]",
	    R([sockAccepted sendBuffer: "Hello" length: 5]))

	TEST(@"-[receiveIntoBuffer:length:]",
	    [sockClient receiveIntoBuffer: buffer length: 5] == 5 &&
	    memcmp(buffer, "Hello", 5) == 0)

	TEST(@"-[remoteAddress]",
	    (address2 = sockAccepted.remoteAddress) &&
	    R(OFSocketAddressGetIPXNode(address2, node2)) &&
	    memcmp(node, node2, IPX_NODE_LEN) == 0)

	delegate = [[[SPXSocketDelegate alloc] init] autorelease];

	sockServer = [OFSPXSocket socket];
	delegate->_expectedServerSocket = sockServer;
	sockServer.delegate = delegate;

	sockClient = [OFSPXSocket socket];
	delegate->_expectedClientSocket = sockClient;
	sockClient.delegate = delegate;

	address1 = [sockServer bindToNetwork: 0 node: zeroNode port: 0];
	[sockServer listen];
	[sockServer asyncAccept];

	delegate->_expectedNetwork = network =
	    OFSocketAddressIPXNetwork(&address1);
	OFSocketAddressGetIPXNode(&address1, node);
	memcpy(delegate->_expectedNode, node, IPX_NODE_LEN);
	delegate->_expectedPort = port = OFSocketAddressIPXPort(&address1);

	@try {
		[sockClient asyncConnectToNetwork: network
					     node: node
					     port: port];

		[[OFRunLoop mainRunLoop] runUntilDate:
		    [OFDate dateWithTimeIntervalSinceNow: 2]];

		TEST(@"-[asyncAccept] & -[asyncConnectToNetwork:node:port:]",
		    delegate->_accepted && delegate->_connected)
	} @catch (OFObserveKernelEventsFailedException *e) {
		/*
		 * Make sure it doesn't stay in the run loop and throws again
		 * next time we run the run loop.
		 */
		[sockClient cancelAsyncRequests];
		[sockServer cancelAsyncRequests];

		switch (e.errNo) {
		case ENOTSOCK:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFSPXSocket] -[asyncAccept] & "
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
