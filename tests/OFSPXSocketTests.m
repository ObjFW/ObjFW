/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <errno.h>
#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFSPXSocketTests: OTTestCase
{
	OFSPXSocket *_sockServer;
	OFSocketAddress _addrServer;
}
@end

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

@implementation OFSPXSocketTests
- (void)setUp
{
	const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };

	_sockServer = [[OFSPXSocket alloc] init];

	@try {
		_addrServer = [_sockServer bindToNetwork: 0
						    node: zeroNode
						    port: 0];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			OTSkip(@"IPX unsupported");
		case ESOCKTNOSUPPORT:
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

- (void)testSPXSocket
{
	OFSPXSocket *sockClient, *sockAccepted;
	const OFSocketAddress *addrAccepted;
	uint32_t network;
	unsigned char node[IPX_NODE_LEN], node2[IPX_NODE_LEN];
	uint16_t port;
	OFDictionary *networkInterfaces;
	char buffer[5];

	sockClient = [OFSPXSocket socket];

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
	[sockAccepted sendBuffer: "Hello" length: 5];

	OTAssertEqual([sockClient receiveIntoBuffer: buffer length: 5], 5);
	OTAssertEqual(memcmp(buffer, "Hello", 5), 0);

	addrAccepted = sockAccepted.remoteAddress;
	OFSocketAddressGetIPXNode(addrAccepted, node2);
	OTAssertEqual(memcmp(node, node2, IPX_NODE_LEN), 0);
}

- (void)testAsyncSPXSocket
{
	SPXSocketDelegate *delegate =
	    [[[SPXSocketDelegate alloc] init] autorelease];
	uint32_t network;
	unsigned char node[IPX_NODE_LEN];
	uint16_t port;
	OFDictionary *networkInterfaces;
	OFSPXSocket *sockClient;

	delegate->_expectedServerSocket = _sockServer;
	_sockServer.delegate = delegate;

	sockClient = [OFSPXSocket socket];
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
