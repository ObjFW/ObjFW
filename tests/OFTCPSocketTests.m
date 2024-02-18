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

@interface OFTCPSocketTests: OTTestCase
@end

@implementation OFTCPSocketTests
- (void)testTCPSocket
{
	OFTCPSocket *server, *client, *accepted;
	OFSocketAddress address;
	char buffer[6];

	server = [OFTCPSocket socket];
	client = [OFTCPSocket socket];

	address = [server bindToHost: @"127.0.0.1" port: 0];
	[server listen];

	[client connectToHost: @"127.0.0.1"
			 port: OFSocketAddressIPPort(&address)];

	accepted = [server accept];
	OTAssertEqualObjects(OFSocketAddressString(accepted.remoteAddress),
	    @"127.0.0.1");

	[client writeString: @"Hello!"];

	[accepted readIntoBuffer: buffer exactLength: 6];
	OTAssertEqual(memcmp(buffer, "Hello!", 6), 0);
}
@end
