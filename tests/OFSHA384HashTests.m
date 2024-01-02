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

#include <string.h>

#import "TestsAppDelegate.h"

static OFString *const module = @"OFSHA384Hash";

const uint8_t testFileSHA384[48] =
	"\x7E\xDE\x62\xE2\x10\xA5\x1E\x18\x8A\x11\x7F\x78\xD7\xC7\x55\xB6\x43"
	"\x94\x1B\xD2\x78\x5C\xCF\xF3\x8A\xB8\x98\x22\xC7\x0E\xFE\xF1\xEC\x53"
	"\xE9\x1A\xB3\x51\x70\x8C\x1F\x3F\x56\x12\x44\x01\x91\x54";

@implementation TestsAppDelegate (SHA384HashTests)
- (void)SHA384HashTests
{
	void *pool = objc_autoreleasePoolPush();
	OFSHA384Hash *SHA384, *SHA384Copy;
	OFIRI *IRI = [OFIRI IRIWithString: @"embedded:testfile.bin"];
	OFStream *file = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];

	TEST(@"+[hashWithAllowsSwappableMemory:]",
	    (SHA384 = [OFSHA384Hash hashWithAllowsSwappableMemory: true]))

	while (!file.atEndOfStream) {
		char buffer[128];
		size_t length = [file readIntoBuffer: buffer length: 128];
		[SHA384 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[copy]", (SHA384Copy = [[SHA384 copy] autorelease]))

	TEST(@"-[calculate]",
	    R([SHA384 calculate]) && R([SHA384Copy calculate]))

	TEST(@"-[digest]",
	    memcmp(SHA384.digest, testFileSHA384, 48) == 0 &&
	    memcmp(SHA384Copy.digest, testFileSHA384, 48) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [SHA384 updateWithBuffer: "" length: 1])

	objc_autoreleasePoolPop(pool);
}
@end
