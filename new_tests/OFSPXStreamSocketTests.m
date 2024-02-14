/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFSPXStreamSocketTests: OTTestCase
{
	OFSPXStreamSocket *_sockServer;
	OFSocketAddress _addrServer;
}
@end

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

@implementation OFSPXStreamSocketTests
- (void)setUp
{
	const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };

	_sockServer = [[OFSPXStreamSocket alloc] init];

	@try {
		_addrServer = [_sockServer bindToNetwork: 0
						    node: zeroNode
						    port: 0];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			OTSkip(@"IPX unsupported");
		case ESOCKTNOSUPPORT:
		case EPROTONOSUPPORT:
			OTSkip(@"SPX unsupported");
		case EADDRNOTAVAIL:
			OTSkip(@"IPX not configured");
		default:
			@throw e;
		}
	}
}

- (void)dealloc
{
	[_sockServer release];

	[super dealloc];
}

- (void)testSPXStreamSocket
{
	OFSPXStreamSocket *sockClient, *sockAccepted;
	const OFSocketAddress *addrAccepted;
	uint32_t network;
	unsigned char node[IPX_NODE_LEN], node2[IPX_NODE_LEN];
	uint16_t port;
	OFDictionary *networkInterfaces;
	char buffer[5];

	sockClient = [OFSPXStreamSocket socket];

	network = OFSocketAddressIPXNetwork(&_addrServer);
	OFSocketAddressGetIPXNode(&_addrServer, node);
	port = OFSocketAddressIPXPort(&_addrServer);

	[_sockServer listen];

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

	[sockClient connectToNetwork: network node: node port: port];

	sockAccepted = [_sockServer accept];
	[sockAccepted writeBuffer: "Hello" length: 5];

	/* Test reassembly (this would not work with OFSPXSocket) */
	OTAssertEqual([sockClient readIntoBuffer: buffer length: 2], 2);
	OTAssertEqual([sockClient readIntoBuffer: buffer + 2 length: 3], 3);
	OTAssertEqual(memcmp(buffer, "Hello", 5), 0);

	addrAccepted = sockAccepted.remoteAddress;
	OFSocketAddressGetIPXNode(addrAccepted, node2);
	OTAssertEqual(memcmp(node, node2, IPX_NODE_LEN), 0);
}

- (void)testAsyncSPXStreamSocket
{
	SPXStreamSocketDelegate *delegate =
	    [[[SPXStreamSocketDelegate alloc] init] autorelease];
	uint32_t network;
	unsigned char node[IPX_NODE_LEN];
	uint16_t port;
	OFDictionary *networkInterfaces;
	OFSPXStreamSocket *sockClient;

	delegate->_expectedServerSocket = _sockServer;
	_sockServer.delegate = delegate;

	sockClient = [OFSPXStreamSocket socket];
	delegate->_expectedClientSocket = sockClient;
	sockClient.delegate = delegate;

	[_sockServer listen];
	[_sockServer asyncAccept];

	network = OFSocketAddressIPXNetwork(&_addrServer);
	OFSocketAddressGetIPXNode(&_addrServer, node);
	port = OFSocketAddressIPXPort(&_addrServer);

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

	delegate->_expectedNetwork = network =
	    OFSocketAddressIPXNetwork(&_addrServer);
	OFSocketAddressGetIPXNode(&_addrServer, node);
	memcpy(delegate->_expectedNode, node, IPX_NODE_LEN);
	delegate->_expectedPort = port = OFSocketAddressIPXPort(&_addrServer);

	@try {
		[sockClient asyncConnectToNetwork: network
					     node: node
					     port: port];

		[[OFRunLoop mainRunLoop] runUntilDate:
		    [OFDate dateWithTimeIntervalSinceNow: 2]];

		OTAssertTrue(delegate->_accepted);
		OTAssertTrue(delegate->_connected);
	} @catch (OFObserveKernelEventsFailedException *e) {
		/*
		 * Make sure it doesn't stay in the run loop and throws again
		 * next time we run the run loop.
		 */
		[sockClient cancelAsyncRequests];
		[_sockServer cancelAsyncRequests];

		switch (e.errNo) {
		case ENOTSOCK:
			OTSkip(@"select() not supported for SPX");
		default:
			@throw e;
		}
	}
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
