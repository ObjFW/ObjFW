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

#import "OFHMAC.h"
#import "OFSHA1Hash.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "pbkdf2.h"

#import "TestsAppDelegate.h"

static OFString *module = @"PBKDF2";

@implementation TestsAppDelegate (PBKDF2Tests)
- (void)PBKDF2Tests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFHMAC *HMAC = [OFHMAC HMACWithHashClass: [OFSHA1Hash class]];
	unsigned char key[25];

	/* Test vectors from RFC 6070 */

	TEST(@"PBKDF2-SHA1, 1 iteration",
	    R(of_pbkdf2(HMAC, 1, (unsigned char *)"salt", 4, "password", 8, key,
	     20)) &&
	    memcmp(key, "\x0C\x60\xC8\x0F\x96\x1F\x0E\x71\xF3\xA9\xB5\x24\xAF"
		"\x60\x12\x06\x2F\xE0\x37\xA6", 20) == 0)

	TEST(@"PBKDF2-SHA1, 2 iterations",
	    R(of_pbkdf2(HMAC, 2, (unsigned char *)"salt", 4, "password", 8, key,
	    20)) &&
	    memcmp(key, "\xEA\x6C\x01\x4D\xC7\x2D\x6F\x8C\xCD\x1E\xD9\x2A\xCE"
		"\x1D\x41\xF0\xD8\xDE\x89\x57", 20) == 0)

	TEST(@"PBKDF2-SHA1, 4096 iterations",
	    R(of_pbkdf2(HMAC, 4096, (unsigned char *)"salt", 4, "password", 8,
	    key, 20)) &&
	    memcmp(key, "\x4B\x00\x79\x01\xB7\x65\x48\x9A\xBE\xAD\x49\xD9\x26"
		"\xF7\x21\xD0\x65\xA4\x29\xC1", 20) == 0)

	/* This test takes too long, even on a fast machine. */
#if 0
	TEST(@"PBKDF2-SHA1, 16777216 iterations",
	    R(of_pbkdf2(HMAC, 16777216, (unsigned char *)"salt", 4, "password",
	    8, key, 20)) &&
	    memcmp(key, "\xEE\xFE\x3D\x61\xCD\x4D\xA4\xE4\xE9\x94\x5B\x3D\x6B"
		"\xA2\x15\x8C\x26\x34\xE9\x84", 20) == 0)
#endif

	TEST(@"PBKDF2-SHA1, 4096 iterations, key > 1 block",
	    R(of_pbkdf2(HMAC, 4096,
	    (unsigned char *)"saltSALTsaltSALTsaltSALTsaltSALTsalt", 36,
	    "passwordPASSWORDpassword", 24, key, 25)) &&
	    memcmp(key, "\x3D\x2E\xEC\x4F\xE4\x1C\x84\x9B\x80\xC8\xD8\x36\x62"
		"\xC0\xE4\x4A\x8B\x29\x1A\x96\x4C\xF2\xF0\x70\x38", 25) == 0)

	TEST(@"PBKDF2-SHA1, 4096 iterations, key < 1 block",
	    R(of_pbkdf2(HMAC, 4096, (unsigned char *)"sa\0lt", 5, "pass\0word",
	    9, key, 16)) &&
	    memcmp(key, "\x56\xFA\x6A\xA7\x55\x48\x09\x9D\xCC\x37\xD7\xF0\x34"
		"\x25\xE0\xC3", 16) == 0)

	[pool drain];
}
@end
