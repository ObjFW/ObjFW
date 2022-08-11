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

static OFString *const module = @"OFSHA224Hash";

const uint8_t testFileSHA224[28] =
	"\x27\x69\xD8\x04\x2D\x0F\xCA\x84\x6C\xF1\x62\x44\xBA\x0C\xBD\x46\x64"
	"\x5F\x4F\x20\x02\x4D\x15\xED\x1C\x61\x1F\xF7";

@implementation TestsAppDelegate (SHA224HashTests)
- (void)SHA224HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSHA224Hash *SHA224, *SHA224Copy;
	OFURL *URL = [OFURL URLWithString: @"objfw-embedded:///testfile.bin"];
	OFStream *file = [OFURLHandler openItemAtURL: URL mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (SHA224 = [OFSHA224Hash hashWithAllowsSwappableMemory: true]))

	while (!file.atEndOfStream) {
		char buffer[64];
		size_t length = [file readIntoBuffer: buffer length: 64];
		[SHA224 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[copy]", (SHA224Copy = [[SHA224 copy] autorelease]))

	TEST(@"-[calculate]",
	    R([SHA224 calculate]) && R([SHA224Copy calculate]))

	TEST(@"-[digest]",
	    memcmp(SHA224.digest, testFileSHA224, 28) == 0 &&
	    memcmp(SHA224Copy.digest, testFileSHA224, 28) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [SHA224 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
