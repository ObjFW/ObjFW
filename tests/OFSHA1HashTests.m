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

static OFString *const module = @"OFSHA1Hash";

const uint8_t testFileSHA1[20] =
	"\xC9\x9A\xB8\x7E\x1E\xC8\xEC\x65\xD5\xEB\xE4\x2E\x0D\xA6\x80\x96\xF5"
	"\x94\xE7\x17";

@implementation TestsAppDelegate (SHA1HashTests)
- (void)SHA1HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSHA1Hash *SHA1, *SHA1Copy;
	OFURL *URL = [OFURL URLWithString: @"objfw-embedded:///testfile.bin"];
	OFStream *file = [OFURLHandler openItemAtURL: URL mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (SHA1 = [OFSHA1Hash hashWithAllowsSwappableMemory: true]))

	while (!file.atEndOfStream) {
		char buffer[64];
		size_t length = [file readIntoBuffer: buffer length: 64];
		[SHA1 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[copy]", (SHA1Copy = [[SHA1 copy] autorelease]))

	TEST(@"-[calculate]", R([SHA1 calculate]) && R([SHA1Copy calculate]))

	TEST(@"-[digest]",
	    memcmp(SHA1.digest, testFileSHA1, 20) == 0 &&
	    memcmp(SHA1Copy.digest, testFileSHA1, 20) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [SHA1 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
