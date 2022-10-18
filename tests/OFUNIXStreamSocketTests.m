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

static OFString *const module = @"OFUNIXStreamSocket";

@implementation TestsAppDelegate (OFUNIXStreamSocketTests)
- (void)UNIXStreamSocketTests
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;
	OFUNIXStreamSocket *sockClient, *sockServer, *sockAccepted;
	char buffer[5];

#if defined(OF_HAVE_FILES) && !defined(OF_IOS)
	path = [[OFSystemInfo temporaryDirectoryURI]
	    URIByAppendingPathComponent: [[OFUUID UUID] UUIDString]]
	    .fileSystemRepresentation;
#else
	/*
	 * We can have sockets, including UNIX sockets, while file support is
	 * disabled.
	 *
	 * We also use this code path for iOS, as the temporaryDirectoryURI is
	 * too long on the iOS simulator.
	 */
	path = [OFString stringWithFormat: @"/tmp/%@",
					   [[OFUUID UUID] UUIDString]];
#endif

	TEST(@"+[socket]", (sockClient = [OFUNIXStreamSocket socket]) &&
	    (sockServer = [OFUNIXStreamSocket socket]))

	@try {
		TEST(@"-[bindToPath:]", R([sockServer bindToPath: path]))
	} @catch (OFBindFailedException *e) {
		switch (e.errNo) {
		case EAFNOSUPPORT:
		case EPERM:
			[OFStdOut setForegroundColor: [OFColor lime]];
			[OFStdOut writeLine:
			    @"\r[OFUNIXStreamSocket] -[bindToPath:]: "
			    @"UNIX stream sockets unsupported, skipping tests"];

			objc_autoreleasePoolPop(pool);
			return;
		default:
			@throw e;
		}
	}

	@try {
		TEST(@"-[listen]", R([sockServer listen]))

		TEST(@"-[connectToPath:]",
		    R([sockClient connectToPath: path]))

		TEST(@"-[accept]", (sockAccepted = [sockServer accept]))

		TEST(@"-[writeBuffer:length:]",
		    R([sockAccepted writeBuffer: "Hello" length: 5]))

		TEST(@"-[readIntoBuffer:length:]",
		    [sockClient readIntoBuffer: buffer length: 5] == 5 &&
		    memcmp(buffer, "Hello", 5) == 0)

		TEST(@"-[remoteAddress]",
		    OFSocketAddressUNIXPath(sockAccepted.remoteAddress) == nil)
	} @finally {
#ifdef OF_HAVE_FILES
		[[OFFileManager defaultManager] removeItemAtPath: path];
#endif
	}

	objc_autoreleasePoolPop(pool);
}
@end
