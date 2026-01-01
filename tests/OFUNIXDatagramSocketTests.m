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

@interface OFUNIXDatagramSocketTests: OTTestCase
@end

@implementation OFUNIXDatagramSocketTests
- (void)testUNIXDatagramSocketWithPath: (OFString *)path
{
	OFUNIXDatagramSocket *sock = [OFUNIXDatagramSocket socket];
	OFSocketAddress address1, address2;
	char buffer[5];

	@try {
		address1 = [sock bindToPath: path];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
		case EPERM:
			OTSkip(@"UNIX datagram sockets unsupported");
		default:
			@throw e;
		}
	}

	@try {
		[sock sendBuffer: "Hello" length: 5 receiver: &address1];

		OTAssertEqual([sock receiveIntoBuffer: buffer
					       length: 5
					       sender: &address2], 5);
		OTAssertEqual(memcmp(buffer, "Hello", 5), 0);
		OTAssertTrue(OFSocketAddressEqual(&address1, &address2));
		OTAssertEqual(OFSocketAddressHash(&address1),
		    OFSocketAddressHash(&address2));
	} @finally {
#ifdef OF_HAVE_FILES
		if (![path hasPrefix: @"@"])
			[[OFFileManager defaultManager] removeItemAtPath: path];
#endif
	}
}

- (void)testUNIXDatagramSocket
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

	[self testUNIXDatagramSocketWithPath: path];
}

#ifdef OF_LINUX
- (void)testAbstractUNIXDatagramSocket
{
	[self testUNIXDatagramSocketWithPath: [OFString stringWithFormat:
	    @"@/tmp/%@", [[OFUUID UUID] UUIDString]]];
}
#endif
@end
