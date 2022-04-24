/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFUNIXDatagramSocket";

@implementation TestsAppDelegate (OFUNIXDatagramSocketTests)
- (void)UNIXDatagramSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;
	OFUNIXDatagramSocket *sock;
	OFSocketAddress address1, address2;
	char buffer[5];

#if defined(OF_HAVE_FILES) && !defined(OF_IOS)
	path = [[OFSystemInfo temporaryDirectoryPath]
	    stringByAppendingPathComponent: [[OFUUID UUID] UUIDString]];
#else
	/*
	 * We can have sockets, including UNIX sockets, while file support is
	 * disabled.
	 *
	 * We also use this code path for iOS, as the temporaryDirectoryPath is
	 * too long on the iOS simulator.
	 */
	path = [OFString stringWithFormat: @"/tmp/%@",
					   [[OFUUID UUID] UUIDString]];
#endif

	TEST(@"+[socket]", (sock = [OFUNIXDatagramSocket socket]))

	@try {
		TEST(@"-[bindToPath:]", R(address1 = [sock bindToPath: path]))
	} @catch (OFBindFailedException *e) {
		if (e.errNo == EAFNOSUPPORT) {
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFUNIXDatagramSocket] -[bindToPath:]: "
			    @"UNIX datagram sockets unsupported, skipping "
			    @"tests"];

			objc_autoreleasePoolPop(pool);
			return;
		} else
			@throw e;
	}

	@try {
		TEST(@"-[sendBuffer:length:receiver:]",
		    R([sock sendBuffer: "Hello" length: 5 receiver: &address1]))

		TEST(@"-[receiveIntoBuffer:length:sender:]",
		    [sock receiveIntoBuffer: buffer
				     length: 5
				     sender: &address2] == 5 &&
		    memcmp(buffer, "Hello", 5) == 0 &&
		    OFSocketAddressEqual(&address1, &address2) &&
		    OFSocketAddressHash(&address1) ==
		    OFSocketAddressHash(&address2))
	} @finally {
#ifdef OF_HAVE_FILES
		[[OFFileManager defaultManager] removeItemAtPath: path];
#endif
	}

	objc_autoreleasePoolPop(pool);
}
@end
