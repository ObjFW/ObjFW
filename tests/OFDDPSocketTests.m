/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

@interface OFDDPSocketTests: OTTestCase
@end

@implementation OFDDPSocketTests
- (void)testDDPSocket
{
	OFDDPSocket *sock;
	OFSocketAddress address1, address2;
	char buffer[5];

	sock = [OFDDPSocket socket];

	@try {
		address1 = [sock bindToNetwork: 0
					  node: 0
					  port: 0
				  protocolType: 11];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
		case EPROTONOSUPPORT:
			OTSkip(@"AppleTalk unsupported");
		case EADDRNOTAVAIL:
			OTSkip(@"AppleTalk not configured");
		default:
			@throw e;
		}
	}

	[sock sendBuffer: "Hello" length: 5 receiver: &address1];

	OTAssertEqual([sock receiveIntoBuffer: buffer
				       length: 5
				       sender: &address2], 5);
	OTAssertEqual(memcmp(buffer, "Hello", 5), 0);
	OTAssertTrue(OFSocketAddressEqual(&address1, &address2));
	OTAssertEqual(OFSocketAddressHash(&address1),
	    OFSocketAddressHash(&address2));
}
@end
