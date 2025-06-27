/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

@interface OFIPXSocketTests: OTTestCase
@end

@implementation OFIPXSocketTests
- (void)testIPXSocket
{
	OFIPXSocket *sock = [OFIPXSocket socket];
	const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
	OFSocketAddress address1, address2;
	OFDictionary *networkInterfaces;
	char buffer[5];
	unsigned char node1[IPX_NODE_LEN], node2[IPX_NODE_LEN];
	unsigned char node[IPX_NODE_LEN];

	@try {
		address1 = [sock bindToNetwork: 0
					  node: zeroNode
					  port: 0
				    packetType: 0];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
			OTSkip(@"IPX unsupported");
		case EADDRNOTAVAIL:
			OTSkip(@"IPX not configured");
		default:
			@throw e;
		}
	}

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

		OFSocketAddressSetIPXNetwork(&address1,
		    OFSocketAddressIPXNetwork([addresses itemAtIndex: 0]));
		OFSocketAddressGetIPXNode([addresses itemAtIndex: 0], node);
		OFSocketAddressSetIPXNode(&address1, node);
	}

	OFSocketAddressGetIPXNode(&address1, node);
	if (OFSocketAddressIPXNetwork(&address1) == 0 &&
	    memcmp(node, zeroNode, 6) == 0)
		OTSkip(@"Could not determine own IPX address");

	[sock sendBuffer: "Hello" length: 5 receiver: &address1];

	OTAssertEqual([sock receiveIntoBuffer: buffer
				       length: 5
				       sender: &address2], 5);
	OTAssertEqual(memcmp(buffer, "Hello", 5), 0);
	OFSocketAddressGetIPXNode(&address1, node1);
	OFSocketAddressGetIPXNode(&address2, node2);
	OTAssertEqual(memcmp(node1, node2, IPX_NODE_LEN), 0);
	OTAssertEqual(OFSocketAddressIPXPort(&address1),
	    OFSocketAddressIPXPort(&address2));
}
@end
