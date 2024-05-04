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

@interface OFSCTPSocketTests: OTTestCase
@end

@implementation OFSCTPSocketTests
- (void)testSCTPSocket
{
	OFSCTPSocket *server, *client, *accepted;
	OFSocketAddress address;
	char buffer[6];
	OFNumber *streamID, *PPID, *unordered;
	OFSCTPMessageInfo sendInfo, receiveInfo;

	server = [OFSCTPSocket socket];
	client = [OFSCTPSocket socket];

	@try {
		address = [server bindToHost: @"127.0.0.1" port: 0];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EPROTONOSUPPORT:
			OTSkip(@"SCTP unsupported");
		default:
			@throw e;
		}
	}

	[server listen];

	[client connectToHost: @"127.0.0.1"
			 port: OFSocketAddressIPPort(&address)];

	accepted = [server accept];
	OTAssertEqualObjects(OFSocketAddressString(accepted.remoteAddress),
	    @"127.0.0.1");

	streamID = [OFNumber numberWithUnsignedShort: 1];
	PPID = [OFNumber numberWithUnsignedLong: 1234];
	unordered = [OFNumber numberWithBool: true];
	sendInfo = [OFDictionary dictionaryWithKeysAndObjects:
	    OFSCTPStreamID, streamID,
	    OFSCTPPPID, PPID,
	    OFSCTPUnordered, unordered, nil];
	[client sendBuffer: "Hello!"
		    length: 6
		      info: sendInfo];

	[accepted receiveIntoBuffer: buffer
			     length: 6
			       info: &receiveInfo];
	OTAssertEqual(memcmp(buffer, "Hello!", 6), 0);
	OTAssertEqualObjects(receiveInfo, sendInfo);
}
@end
