/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFSHA256Hash.h"
#import "OFString.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"

#import "OFHashAlreadyCalculatedException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFSHA256Hash";

const uint8_t testfile_sha256[32] =
	"\x1A\x02\xD6\x46\xF5\xA6\xBA\xAA\xFF\x7F\xD5\x87\xBA\xC3\xF6\xC6\xB5"
	"\x67\x93\x8F\x0F\x44\x90\xB8\xF5\x35\x89\xF0\x5A\x23\x7F\x69";

@implementation TestsAppDelegate (SHA256HashTests)
- (void)SHA256HashTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFSHA256Hash *sha256;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"rb"];

	TEST(@"+[hash]", (sha256 = [OFSHA256Hash hash]))

	while (![f isAtEndOfStream]) {
		char buf[64];
		size_t len = [f readIntoBuffer: buf
					length: 64];
		[sha256 updateWithBuffer: buf
				  length: len];
	}
	[f close];

	TEST(@"-[digest]", !memcmp([sha256 digest], testfile_sha256, 32))

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [sha256 updateWithBuffer: ""
			      length: 1])

	[pool drain];
}
@end
