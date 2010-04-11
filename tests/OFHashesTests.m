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

#import "OFHashes.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"
#import "OFString.h"
#import "OFExceptions.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFHashes";

const uint8_t testfile_md5[OF_MD5_DIGEST_SIZE] =
	"\x00\x8B\x9D\x1B\x58\xDF\xF8\xFE\xEE\xF3\xAE\x8D\xBB\x68\x2D\x38";
const uint8_t testfile_sha1[OF_SHA1_DIGEST_SIZE] =
	"\xC9\x9A\xB8\x7E\x1E\xC8\xEC\x65\xD5\xEB\xE4\x2E\x0D\xA6\x80\x96\xF5"
	"\x94\xE7\x17";

@implementation TestsAppDelegate (OFHashesTests)
- (void)hashesTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMD5Hash *md5;
	OFSHA1Hash *sha1;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"rb"];

	TEST(@"+[md5Hash]", (md5 = [OFMD5Hash md5Hash]))

	TEST(@"+[sha1Hash]", (sha1 = [OFSHA1Hash sha1Hash]))

	while (![f atEndOfStream]) {
		char buf[64];
		size_t len = [f readNBytes: 64
				intoBuffer: buf];
		[md5 updateWithBuffer: buf
			       ofSize: len];
		[sha1 updateWithBuffer: buf
				ofSize: len];
	}
	[f close];

	TEST(@"-[digest]",
	    !memcmp([md5 digest], testfile_md5, OF_MD5_DIGEST_SIZE) &&
	    !memcmp([sha1 digest], testfile_sha1, OF_MD5_DIGEST_SIZE))

	EXPECT_EXCEPTION(@"Detect invalid call of -[updateWithBuffer] #1",
	    OFHashAlreadyCalculatedException, [md5 updateWithBuffer: ""
							     ofSize: 1])
	EXPECT_EXCEPTION(@"Detect invalid call of -[updateWithBuffer] #2",
	    OFHashAlreadyCalculatedException, [sha1 updateWithBuffer: ""
							      ofSize: 1])

	[pool drain];
}
@end
