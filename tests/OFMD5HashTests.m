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

#include <string.h>

#import "TestsAppDelegate.h"

static OFString *const module = @"OFMD5Hash";

const uint8_t testFileMD5[16] =
    "\x00\x8B\x9D\x1B\x58\xDF\xF8\xFE\xEE\xF3\xAE\x8D\xBB\x68\x2D\x38";

@implementation TestsAppDelegate (OFMD5HashTests)
- (void)MD5HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFMD5Hash *MD5, *MD5Copy;
	OFURI *URI = [OFURI URIWithString: @"objfw-embedded:///testfile.bin"];
	OFStream *file = [OFURIHandler openItemAtURI: URI mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (MD5 = [OFMD5Hash hashWithAllowsSwappableMemory: true]))

	while (!file.atEndOfStream) {
		char buffer[64];
		size_t length = [file readIntoBuffer: buffer length: 64];
		[MD5 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[copy]", (MD5Copy = [[MD5 copy] autorelease]))

	TEST(@"-[calculate]", R([MD5 calculate]) && R([MD5Copy calculate]))

	TEST(@"-[digest]",
	    memcmp(MD5.digest, testFileMD5, 16) == 0 &&
	    memcmp(MD5Copy.digest, testFileMD5, 16) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length]", OFHashAlreadyCalculatedException,
	    [MD5 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
