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

@interface OFUNIXSequencedPacketSocketTests: OTTestCase
@end

@implementation OFUNIXSequencedPacketSocketTests
- (void)testUNIXSequencedSocketWithPath: (OFString *)path
{
	OFUNIXSequencedPacketSocket *sockClient, *sockServer, *sockAccepted;
	char buffer[5];

	sockClient = [OFUNIXSequencedPacketSocket socket];
	sockServer = [OFUNIXSequencedPacketSocket socket];

	@try {
		[sockServer bindToPath: path];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
		case EPERM:
		case EPROTONOSUPPORT:
#ifdef ESOCKTNOSUPPORT
		case ESOCKTNOSUPPORT:
#endif
			OTSkip(@"UNIX sequenced packet sockets unsupported");
		default:
			@throw e;
		}
	}

	@try {
		[sockServer listen];

		[sockClient connectToPath: path];

		sockAccepted = [sockServer accept];
		[sockAccepted sendBuffer: "Hello" length: 5];

		OTAssertEqual([sockClient receiveIntoBuffer: buffer
						     length: 5], 5);
		OTAssertEqual(memcmp(buffer, "Hello", 5), 0);

		OTAssertEqual(OFSocketAddressUNIXPath(
		    sockAccepted.remoteAddress).length, 0);
	} @finally {
#ifdef OF_HAVE_FILES
		if (![path hasPrefix: @"@"])
			[[OFFileManager defaultManager] removeItemAtPath: path];
#endif
	}
}

- (void)testUNIXSequencedSocket
{
#if defined(OF_HAVE_FILES) && !defined(OF_IOS)
	OFString *path = [[OFSystemInfo temporaryDirectoryIRI]
	    IRIByAppendingPathComponent: [[OFUUID UUID] UUIDString]]
	    .fileSystemRepresentation;
#else
	/*
	 * We can have sockets, including UNIX sockets, while file support is
	 * disabled.
	 *
	 * We also use this code path for iOS, as the temporaryDirectoryIRI is
	 * too long on the iOS simulator.
	 */
	OFString *path = [OFString stringWithFormat:
	    @"/tmp/%@", [[OFUUID UUID] UUIDString]];
#endif

	OTAssertNotNil(path);

	[self testUNIXSequencedSocketWithPath: path];
}

#ifdef OF_LINUX
- (void)testAbstractUNIXSequencedSocket
{
	[self testUNIXSequencedSocketWithPath: [OFString stringWithFormat:
	    @"@/tmp/%@", [[OFUUID UUID] UUIDString]]];
}
#endif
@end
