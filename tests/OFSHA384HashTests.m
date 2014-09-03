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

#import "OFSHA384Hash.h"
#import "OFString.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"

#import "OFHashAlreadyCalculatedException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFSHA384Hash";

const uint8_t testfile_sha384[48] =
	"\x7E\xDE\x62\xE2\x10\xA5\x1E\x18\x8A\x11\x7F\x78\xD7\xC7\x55\xB6\x43"
	"\x94\x1B\xD2\x78\x5C\xCF\xF3\x8A\xB8\x98\x22\xC7\x0E\xFE\xF1\xEC\x53"
	"\xE9\x1A\xB3\x51\x70\x8C\x1F\x3F\x56\x12\x44\x01\x91\x54";

@implementation TestsAppDelegate (SHA384HashTests)
- (void)SHA384HashTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFSHA384Hash *sha384;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"rb"];

	TEST(@"+[hash]", (sha384 = [OFSHA384Hash hash]))

	while (![f isAtEndOfStream]) {
		char buf[128];
		size_t len = [f readIntoBuffer: buf
					length: 128];
		[sha384 updateWithBuffer: buf
				  length: len];
	}
	[f close];

	TEST(@"-[digest]", !memcmp([sha384 digest], testfile_sha384, 48))

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [sha384 updateWithBuffer: ""
			      length: 1])

	[pool drain];
}
@end
