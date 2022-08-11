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

static OFString *const module = @"OFRIPEMD160Hash";

const uint8_t testFileRIPEMD160[20] =
	"\x46\x02\x97\xF5\x85\xDF\xB9\x21\x00\xC8\xF9\x87\xC6\xEC\x84\x0D\xCE"
	"\xE6\x08\x8B";

@implementation TestsAppDelegate (OFRIPEMD160HashTests)
- (void)RIPEMD160HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFRIPEMD160Hash *RIPEMD160, *RIPEMD160Copy;
	OFURL *URL = [OFURL URLWithString: @"objfw-embedded:///testfile.bin"];
	OFStream *file = [OFURLHandler openItemAtURL: URL mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (RIPEMD160 = [OFRIPEMD160Hash hashWithAllowsSwappableMemory: true]))

	while (!file.atEndOfStream) {
		char buffer[64];
		size_t length = [file readIntoBuffer: buffer length: 64];
		[RIPEMD160 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[copy]", (RIPEMD160Copy = [[RIPEMD160 copy] autorelease]))

	TEST(@"-[calculate]",
	    R([RIPEMD160 calculate]) && R([RIPEMD160Copy calculate]))

	TEST(@"-[digest]",
	    memcmp(RIPEMD160.digest, testFileRIPEMD160, 20) == 0 &&
	    memcmp(RIPEMD160Copy.digest, testFileRIPEMD160, 20) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length]", OFHashAlreadyCalculatedException,
	    [RIPEMD160 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
