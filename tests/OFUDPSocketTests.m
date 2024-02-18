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
