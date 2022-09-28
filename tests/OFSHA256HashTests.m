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

static OFString *const module = @"OFSHA256Hash";

const uint8_t testFileSHA256[32] =
	"\x1A\x02\xD6\x46\xF5\xA6\xBA\xAA\xFF\x7F\xD5\x87\xBA\xC3\xF6\xC6\xB5"
	"\x67\x93\x8F\x0F\x44\x90\xB8\xF5\x35\x89\xF0\x5A\x23\x7F\x69";

@implementation TestsAppDelegate (SHA256HashTests)
- (void)SHA256HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSHA256Hash *SHA256, *SHA256Copy;
	OFURI *URI = [OFURI URIWithString: @"objfw-embedded:///testfile.bin"];
	OFStream *file = [OFURIHandler openItemAtURI: URI mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (SHA256 = [OFSHA256Hash hashWithAllowsSwappableMemory: true]))

	while (!file.atEndOfStream) {
		char buffer[64];
		size_t length = [file readIntoBuffer: buffer length: 64];
		[SHA256 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[copy]", (SHA256Copy = [[SHA256 copy] autorelease]))

	TEST(@"-[calculate]",
	    R([SHA256 calculate]) && R([SHA256Copy calculate]))

	TEST(@"-[digest]",
	    memcmp(SHA256.digest, testFileSHA256, 32) == 0 &&
	    memcmp(SHA256Copy.digest, testFileSHA256, 32) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [SHA256 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
