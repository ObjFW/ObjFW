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

@interface OFUNIXDatagramSocketTests: OTTestCase
@end

@implementation OFUNIXDatagramSocketTests
- (void)testUNIXDatagramSockets
{
	OFUNIXDatagramSocket *sock = [OFUNIXDatagramSocket socket];
	OFString *path;
	OFSocketAddress address1, address2;
	char buffer[5];

#if defined(OF_HAVE_FILES) && !defined(OF_IOS)
	path = [[OFSystemInfo temporaryDirectoryIRI]
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
	path = [OFString stringWithFormat: @"/tmp/%@",
					   [[OFUUID UUID] UUIDString]];
#endif

	@try {
		address1 = [sock bindToPath: path];
	} @catch (OFBindSocketFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
		case EPERM:
			OTSkip(@"UNIX datagram sockets unsupported");
			return;
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
		[[OFFileManager defaultManager] removeItemAtPath: path];
#endif
	}
}
@end
