/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

static OFString *module = @"PBKDF2";

@implementation TestsAppDelegate (PBKDF2Tests)
- (void)PBKDF2Tests
{
	void *pool = objc_autoreleasePoolPush();
	OFHMAC *HMAC = [OFHMAC HMACWithHashClass: [OFSHA1Hash class]
			   allowsSwappableMemory: true];
	unsigned char key[25];

	/* Test vectors from RFC 6070 */

	TEST(@"PBKDF2-SHA1, 1 iteration",
	    R(of_pbkdf2((of_pbkdf2_parameters_t){
		.HMAC                  = HMAC,
		.iterations            = 1,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	    })) && memcmp(key, "\x0C\x60\xC8\x0F\x96\x1F\x0E\x71\xF3\xA9\xB5"
		"\x24\xAF\x60\x12\x06\x2F\xE0\x37\xA6", 20) == 0)

	TEST(@"PBKDF2-SHA1, 2 iterations",
	    R(of_pbkdf2((of_pbkdf2_parameters_t){
		.HMAC                  = HMAC,
		.iterations            = 2,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	    })) && memcmp(key, "\xEA\x6C\x01\x4D\xC7\x2D\x6F\x8C\xCD\x1E\xD9"
	        "\x2A\xCE\x1D\x41\xF0\xD8\xDE\x89\x57", 20) == 0)

	TEST(@"PBKDF2-SHA1, 4096 iterations",
	    R(of_pbkdf2((of_pbkdf2_parameters_t){
		.HMAC                  = HMAC,
		.iterations            = 4096,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	    })) && memcmp(key, "\x4B\x00\x79\x01\xB7\x65\x48\x9A\xBE\xAD\x49"
	        "\xD9\x26\xF7\x21\xD0\x65\xA4\x29\xC1", 20) == 0)

	/* This test takes too long, even on a fast machine. */
#if 0
	TEST(@"PBKDF2-SHA1, 16777216 iterations",
	    R(of_pbkdf2((of_pbkdf2_parameters_t){
		.HMAC                  = HMAC,
		.iterations            = 16777216,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	    })) && memcmp(key, "\xEE\xFE\x3D\x61\xCD\x4D\xA4\xE4\xE9\x94\x5B"
	        "\x3D\x6B\xA2\x15\x8C\x26\x34\xE9\x84", 20) == 0)
#endif

	TEST(@"PBKDF2-SHA1, 4096 iterations, key > 1 block",
	    R(of_pbkdf2((of_pbkdf2_parameters_t){
		.HMAC                  = HMAC,
		.iterations            = 4096,
		.salt                  = (unsigned char *)"saltSALTsaltSALTsalt"
		                         "SALTsaltSALTsalt",
		.saltLength            = 36,
		.password              = "passwordPASSWORDpassword",
		.passwordLength        = 24,
		.key                   = key,
		.keyLength             = 25,
		.allowsSwappableMemory = true
	    })) &&
	    memcmp(key, "\x3D\x2E\xEC\x4F\xE4\x1C\x84\x9B\x80\xC8\xD8\x36\x62"
	        "\xC0\xE4\x4A\x8B\x29\x1A\x96\x4C\xF2\xF0\x70\x38", 25) == 0)

	TEST(@"PBKDF2-SHA1, 4096 iterations, key < 1 block",
	    R(of_pbkdf2((of_pbkdf2_parameters_t){
		.HMAC                  = HMAC,
		.iterations            = 4096,
		.salt                  = (unsigned char *)"sa\0lt",
		.saltLength            = 5,
		.password              = "pass\0word",
		.passwordLength        = 9,
		.key                   = key,
		.keyLength             = 16,
		.allowsSwappableMemory = true
	    })) && memcmp(key, "\x56\xFA\x6A\xA7\x55\x48\x09\x9D\xCC\x37\xD7"
	        "\xF0\x34\x25\xE0\xC3", 16) == 0)

	objc_autoreleasePoolPop(pool);
}
@end
