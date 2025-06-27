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
