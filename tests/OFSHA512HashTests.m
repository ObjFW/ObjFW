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

static OFString *const module = @"OFSHA512Hash";

const uint8_t testFileSHA512[64] =
	"\x8F\x36\x6E\x3C\x19\x4B\xBB\xC7\x82\xAA\xCD\x7D\x55\xA2\xD3\x29\x29"
	"\x97\x6A\x3F\xEB\x9B\xB2\xCB\x75\xC9\xEC\xC8\x10\x07\xD6\x07\x31\x4A"
	"\xB1\x30\x97\x82\x58\xA5\x1F\x71\x42\xE6\x56\x07\x99\x57\xB2\xB8\x3B"
	"\xA1\x8A\x41\x64\x33\x69\x21\x8C\x2A\x44\x6D\xF2\xA0";

@implementation TestsAppDelegate (SHA512HashTests)
- (void)SHA512HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSHA512Hash *SHA512, *SHA512Copy;
	OFURI *URI = [OFURI URIWithString: @"of-embedded:testfile.bin"];
	OFStream *file = [OFURIHandler openItemAtURI: URI mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (SHA512 = [OFSHA512Hash hashWithAllowsSwappableMemory: true]))

	while (!file.atEndOfStream) {
		char buffer[128];
		size_t length = [file readIntoBuffer: buffer length: 128];
		[SHA512 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[copy]", (SHA512Copy = [[SHA512 copy] autorelease]))

	TEST(@"-[calculate]",
	    R([SHA512 calculate]) && R([SHA512Copy calculate]))

	TEST(@"-[digest]",
	    memcmp(SHA512.digest, testFileSHA512, 64) == 0 &&
	    memcmp(SHA512Copy.digest, testFileSHA512, 64) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [SHA512 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
