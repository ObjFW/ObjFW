/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFSHA1Hash.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFHash";

const uint8_t testfile_sha1[OF_SHA1_DIGEST_SIZE] =
	"\xC9\x9A\xB8\x7E\x1E\xC8\xEC\x65\xD5\xEB\xE4\x2E\x0D\xA6\x80\x96\xF5"
	"\x94\xE7\x17";

@implementation TestsAppDelegate (SHA1HashTests)
- (void)SHA1HashTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFSHA1Hash *sha1;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"rb"];

	TEST(@"+[sha1Hash]", (sha1 = [OFSHA1Hash sha1Hash]))

	while (![f atEndOfStream]) {
		char buf[64];
		size_t len = [f readNBytes: 64
				intoBuffer: buf];
		[sha1 updateWithBuffer: buf
				ofSize: len];
	}
	[f close];

	TEST(@"-[digest]",
	    !memcmp([sha1 digest], testfile_sha1, OF_SHA1_DIGEST_SIZE))

	EXPECT_EXCEPTION(@"Detect invalid call of -[updateWithBuffer]",
	    OFHashAlreadyCalculatedException, [sha1 updateWithBuffer: ""
							      ofSize: 1])

	[pool drain];
}
@end
