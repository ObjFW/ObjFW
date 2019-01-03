/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFSHA224Hash.h"
#import "OFString.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"

#import "OFHashAlreadyCalculatedException.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFSHA224Hash";

const uint8_t testfile_sha224[28] =
	"\x27\x69\xD8\x04\x2D\x0F\xCA\x84\x6C\xF1\x62\x44\xBA\x0C\xBD\x46\x64"
	"\x5F\x4F\x20\x02\x4D\x15\xED\x1C\x61\x1F\xF7";

@implementation TestsAppDelegate (SHA224HashTests)
- (void)SHA224HashTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFSHA224Hash *sha224, *copy;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"r"];

	TEST(@"+[cryptoHash]", (sha224 = [OFSHA224Hash cryptoHash]))

	while (![f isAtEndOfStream]) {
		char buf[64];
		size_t len = [f readIntoBuffer: buf
					length: 64];
		[sha224 updateWithBuffer: buf
				  length: len];
	}
	[f close];

	TEST(@"-[copy]", (copy = [[sha224 copy] autorelease]))

	TEST(@"-[digest]",
	    memcmp([sha224 digest], testfile_sha224, 28) == 0 &&
	    memcmp([copy digest], testfile_sha224, 28) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length:]", OFHashAlreadyCalculatedException,
	    [sha224 updateWithBuffer: ""
			      length: 1])

	[pool drain];
}
@end
