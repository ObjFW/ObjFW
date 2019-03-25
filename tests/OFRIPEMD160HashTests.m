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

#import "TestsAppDelegate.h"

static OFString *module = @"OFRIPEMD160Hash";

const uint8_t testfile_rmd160[20] =
	"\x46\x02\x97\xF5\x85\xDF\xB9\x21\x00\xC8\xF9\x87\xC6\xEC\x84\x0D\xCE"
	"\xE6\x08\x8B";

@implementation TestsAppDelegate (OFRIPEMD160HashTests)
- (void)RIPEMD160HashTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFRIPEMD160Hash *rmd160, *copy;
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"r"];

	TEST(@"+[cryptoHash]", (rmd160 = [OFRIPEMD160Hash cryptoHash]))

	while (!f.atEndOfStream) {
		char buf[64];
		size_t len = [f readIntoBuffer: buf
					length: 64];
		[rmd160 updateWithBuffer: buf
				  length: len];
	}
	[f close];

	TEST(@"-[copy]", (copy = [[rmd160 copy] autorelease]))

	TEST(@"-[digest]",
	    memcmp(rmd160.digest, testfile_rmd160, 20) == 0 &&
	    memcmp(copy.digest, testfile_rmd160, 20) == 0)

	EXPECT_EXCEPTION(@"Detect invalid call of "
	    @"-[updateWithBuffer:length]", OFHashAlreadyCalculatedException,
	    [rmd160 updateWithBuffer: ""
			      length: 1])

	[pool drain];
}
@end
