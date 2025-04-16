/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFPBKDF2Tests: OTTestCase
{
	OFHMAC *_HMAC;
}
@end

@implementation OFPBKDF2Tests
- (void)setUp
{
	[super setUp];

	_HMAC = [[OFHMAC alloc] initWithHashClass: [OFSHA1Hash class]
			    allowsSwappableMemory: true];
}

- (void)dealloc
{
	objc_release(_HMAC);

	[super dealloc];
}

/* Test vectors from RFC 6070 */

- (void)testRFC6070TestVector1
{
	unsigned char key[20];

	OFPBKDF2((OFPBKDF2Parameters){
		.HMAC                  = _HMAC,
		.iterations            = 1,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	});

	OTAssertEqual(memcmp(key, "\x0C\x60\xC8\x0F\x96\x1F\x0E\x71\xF3\xA9\xB5"
	    "\x24\xAF\x60\x12\x06\x2F\xE0\x37\xA6", 20), 0);
}

- (void)testRFC6070TestVector2
{
	unsigned char key[20];

	OFPBKDF2((OFPBKDF2Parameters){
		.HMAC                  = _HMAC,
		.iterations            = 2,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	});

	OTAssertEqual(memcmp(key, "\xEA\x6C\x01\x4D\xC7\x2D\x6F\x8C\xCD\x1E\xD9"
	    "\x2A\xCE\x1D\x41\xF0\xD8\xDE\x89\x57", 20), 0);
}

- (void)testRFC6070TestVector3
{
	unsigned char key[20];

	OFPBKDF2((OFPBKDF2Parameters){
		.HMAC                  = _HMAC,
		.iterations            = 4096,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	});

	OTAssertEqual(memcmp(key, "\x4B\x00\x79\x01\xB7\x65\x48\x9A\xBE\xAD\x49"
	    "\xD9\x26\xF7\x21\xD0\x65\xA4\x29\xC1", 20), 0);
}

#if 0
/* This test takes too long, even on a fast machine. */
- (void)testRFC6070TestVector4
{
	unsigned char key[20];

	OFPBKDF2((OFPBKDF2Parameters){
		.HMAC                  = _HMAC,
		.iterations            = 16777216,
		.salt                  = (unsigned char *)"salt",
		.saltLength            = 4,
		.password              = "password",
		.passwordLength        = 8,
		.key                   = key,
		.keyLength             = 20,
		.allowsSwappableMemory = true
	});

	OTAssertEqual(memcmp(key, "\xEE\xFE\x3D\x61\xCD\x4D\xA4\xE4\xE9\x94\x5B"
	    "\x3D\x6B\xA2\x15\x8C\x26\x34\xE9\x84", 20), 0);
}
#endif

- (void)testRFC6070TestVector5
{
	unsigned char key[25];

	OFPBKDF2((OFPBKDF2Parameters){
		.HMAC                  = _HMAC,
		.iterations            = 4096,
		.salt                  = (unsigned char *)"saltSALTsaltSALTsalt"
					 "SALTsaltSALTsalt",
		.saltLength            = 36,
		.password              = "passwordPASSWORDpassword",
		.passwordLength        = 24,
		.key                   = key,
		.keyLength             = 25,
		.allowsSwappableMemory = true
	});

	OTAssertEqual(memcmp(key, "\x3D\x2E\xEC\x4F\xE4\x1C\x84\x9B\x80\xC8\xD8"
	    "\x36\x62\xC0\xE4\x4A\x8B\x29\x1A\x96\x4C\xF2\xF0\x70\x38", 25), 0);
}

- (void)testRFC6070TestVector6
{
	unsigned char key[16];

	OFPBKDF2((OFPBKDF2Parameters){
		.HMAC                  = _HMAC,
		.iterations            = 4096,
		.salt                  = (unsigned char *)"sa\0lt",
		.saltLength            = 5,
		.password              = "pass\0word",
		.passwordLength        = 9,
		.key                   = key,
		.keyLength             = 16,
		.allowsSwappableMemory = true
	});

	OTAssertEqual(memcmp(key, "\x56\xFA\x6A\xA7\x55\x48\x09\x9D\xCC\x37\xD7"
	    "\xF0\x34\x25\xE0\xC3", 16), 0);
}
@end
