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
