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

#include <string.h>

#import "TestsAppDelegate.h"

static OFString *const module = @"OFUDPSocket";

@implementation TestsAppDelegate (OFUDPSocketTests)
- (void)UDPSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFUDPSocket *sock;
	OFSocketAddress addr1, addr2, addr3;
	char buf[6];

	TEST(@"+[socket]", (sock = [OFUDPSocket socket]))

	TEST(@"-[bindToHost:port:]",
	    R(addr1 = [sock bindToHost: @"127.0.0.1" port: 0]))

	TEST(@"-[sendBuffer:length:receiver:]",
	    R([sock sendBuffer: "Hello" length: 6 receiver: &addr1]))

	TEST(@"-[receiveIntoBuffer:length:sender:]",
	    [sock receiveIntoBuffer: buf length: 6 sender: &addr2] == 6 &&
	    !memcmp(buf, "Hello", 6) &&
	    [OFSocketAddressString(&addr2) isEqual: @"127.0.0.1"] &&
	    OFSocketAddressIPPort(&addr2) == OFSocketAddressIPPort(&addr1))

	addr3 = OFSocketAddressParseIP(@"127.0.0.1",
	    OFSocketAddressIPPort(&addr1) + 1);

	TEST(@"OFSocketAddressEqual()",
	    OFSocketAddressEqual(&addr1, &addr2) &&
	    !OFSocketAddressEqual(&addr1, &addr3))

	TEST(@"OFSocketAddressHash()",
	    OFSocketAddressHash(&addr1) == OFSocketAddressHash(&addr2) &&
	    OFSocketAddressHash(&addr1) != OFSocketAddressHash(&addr3))

	objc_autoreleasePoolPop(pool);
}
@end
