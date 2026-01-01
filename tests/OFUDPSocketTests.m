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

#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFUDPSocketTests: OTTestCase
@end

@implementation OFUDPSocketTests
- (void)testUDPSocket
{
	OFUDPSocket *sock = [OFUDPSocket socket];
	OFSocketAddress addr1, addr2;
	char buffer[6];

	sock = [OFUDPSocket socket];

	addr1 = [sock bindToHost: @"127.0.0.1" port: 0];
	OTAssertEqualObjects(OFSocketAddressString(&addr1), @"127.0.0.1");

	[sock sendBuffer: "Hello" length: 6 receiver: &addr1];

	[sock receiveIntoBuffer: buffer length: 6 sender: &addr2];
	OTAssertEqual(memcmp(buffer, "Hello", 6), 0);
	OTAssertEqualObjects(OFSocketAddressString(&addr2), @"127.0.0.1");
	OTAssertEqual(OFSocketAddressIPPort(&addr2),
	    OFSocketAddressIPPort(&addr1));
}
@end
