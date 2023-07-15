/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

static OFString *const module = @"OFHMAC";
static const uint8_t key[] =
    "yM9h8K6IWnJRvxC/0F8XRWG7RnACDBz8wqK2tbXrYVLoKC3vPLeJikyJSM47tVHc"
    "DlXHww9zULAC2sJUlm2Kg1z4oz2aXY3Y1PQSB4VkC/m0DQ7hCI6cAg4TWnKdzWTy"
    "cvYGX+Y6HWeDY79/PGSd8fNItme6I8w4HDBqU7BP2sum3jbePJqoiSnhcyJZQTeZ"
    "jw0ZXoyrfHgOYD2M+NsTDaGpLblFtQ7n5CczjKtafG40PkEwx1dcrd46U9i3GyTK";
static const size_t keyLength = sizeof(key);
static const uint8_t MD5Digest[] =
    "\xCC\x1F\xEF\x09\x29\xA3\x25\x1A\x06\xA9\x83\x99\xF9\xBC\x8F\x42";
static const uint8_t SHA1Digest[] =
    "\x94\xB9\x0A\x6F\xFB\xA7\x13\x6A\x75\x55"
    "\xD5\x7F\x5D\xB7\xF4\xCA\xEB\x4A\xDE\xBF";
static const uint8_t RIPEMD160Digest[] =
    "\x2C\xE1\xED\x41\xC6\xF3\x51\xA8\x04\xD2"
    "\xC3\x9B\x08\x33\x3B\xD5\xC9\x00\x39\x50";
static const uint8_t SHA256Digest[] =
    "\xFB\x8C\xDA\x88\xB3\x81\x32\x16\xD7\xD8\x62\xD4\xA6\x26\x9D\x77"
    "\x01\x99\x62\x65\x29\x02\x41\xE6\xEF\xA1\x02\x31\xA8\x9D\x77\x5D";
static const uint8_t SHA384Digest[] =
    "\x2F\x4A\x47\xAE\x13\x8E\x96\x52\xF1\x8F\x05\xFD\x65\xCD\x9A\x97"
    "\x93\x2F\xC9\x02\xD6\xC6\xAB\x2E\x15\x76\xC0\xA7\xA0\x05\xF4\xEF"
    "\x14\x52\x33\x4B\x9C\x5F\xD8\x07\x4E\x98\xAE\x97\x46\x29\x24\xB4";
static const uint8_t SHA512Digest[] =
    "\xF5\x8C\x3F\x9C\xA2\x2F\x0A\xF3\x26\xD8\xC0\x7E\x20\x63\x88\x61"
    "\xC9\xE1\x1F\xD7\xC7\xE5\x59\x33\xD5\x2F\xAF\x56\x1C\x94\xC8\xA4"
    "\x61\xB3\xF9\x1A\xE3\x09\x43\xA6\x5B\x85\xB1\x50\x5B\xCB\x1A\x2E"
    "\xB7\xE8\x87\xC1\x73\x19\x63\xF6\xA2\x91\x8D\x7E\x2E\xCC\xEC\x99";

@implementation TestsAppDelegate (OFHMACTests)
- (void)HMACTests
{
	void *pool = objc_autoreleasePoolPush();
	OFIRI *IRI = [OFIRI IRIWithString: @"embedded:testfile.bin"];
	OFStream *file = [OFIRIHandler openItemAtIRI: IRI mode: @"r"];
	OFHMAC *HMACMD5, *HMACSHA1, *HMACRMD160;
	OFHMAC *HMACSHA256, *HMACSHA384, *HMACSHA512;

	TEST(@"+[HMACWithHashClass:] with MD5",
	    (HMACMD5 = [OFHMAC HMACWithHashClass: [OFMD5Hash class]
			   allowsSwappableMemory: true]))
	TEST(@"+[HMACWithHashClass:] with SHA-1",
	    (HMACSHA1 = [OFHMAC HMACWithHashClass: [OFSHA1Hash class]
			    allowsSwappableMemory: true]))
	TEST(@"+[HMACWithHashClass:] with RIPEMD-160",
	    (HMACRMD160 = [OFHMAC HMACWithHashClass: [OFRIPEMD160Hash class]
			      allowsSwappableMemory: true]))
	TEST(@"+[HMACWithHashClass:] with SHA-256",
	    (HMACSHA256 = [OFHMAC HMACWithHashClass: [OFSHA256Hash class]
			      allowsSwappableMemory: true]))
	TEST(@"+[HMACWithHashClass:] with SHA-384",
	    (HMACSHA384 = [OFHMAC HMACWithHashClass: [OFSHA384Hash class]
			      allowsSwappableMemory: true]))
	TEST(@"+[HMACWithHashClass:] with SHA-512",
	    (HMACSHA512 = [OFHMAC HMACWithHashClass: [OFSHA512Hash class]
			      allowsSwappableMemory: true]))

	EXPECT_EXCEPTION(@"Detection of missing key",
	    OFInvalidArgumentException,
	    [HMACMD5 updateWithBuffer: "" length: 0])

	TEST(@"-[setKey:length:] with MD5",
	    R([HMACMD5 setKey: key length: keyLength]))
	TEST(@"-[setKey:length:] with SHA-1",
	    R([HMACSHA1 setKey: key length: keyLength]))
	TEST(@"-[setKey:length:] with RIPEMD-160",
	    R([HMACRMD160 setKey: key length: keyLength]))
	TEST(@"-[setKey:length:] with SHA-256",
	    R([HMACSHA256 setKey: key length: keyLength]))
	TEST(@"-[setKey:length:] with SHA-384",
	    R([HMACSHA384 setKey: key length: keyLength]))
	TEST(@"-[setKey:length:] with SHA-512",
	    R([HMACSHA512 setKey: key length: keyLength]))

	while (!file.atEndOfStream) {
		char buffer[64];
		size_t length = [file readIntoBuffer: buffer length: 64];
		[HMACMD5 updateWithBuffer: buffer length: length];
		[HMACSHA1 updateWithBuffer: buffer length: length];
		[HMACRMD160 updateWithBuffer: buffer length: length];
		[HMACSHA256 updateWithBuffer: buffer length: length];
		[HMACSHA384 updateWithBuffer: buffer length: length];
		[HMACSHA512 updateWithBuffer: buffer length: length];
	}
	[file close];

	TEST(@"-[calculate] with MD5", R([HMACMD5 calculate]))
	TEST(@"-[calculate] with SHA-1", R([HMACSHA1 calculate]))
	TEST(@"-[calculate] with RIPEMD-160", R([HMACRMD160 calculate]))
	TEST(@"-[calculate] with SHA-256", R([HMACSHA256 calculate]))
	TEST(@"-[calculate] with SHA-384", R([HMACSHA384 calculate]))
	TEST(@"-[calculate] with SHA-512", R([HMACSHA512 calculate]))

	TEST(@"-[digest] with MD5",
	    memcmp(HMACMD5.digest, MD5Digest, HMACMD5.digestSize) == 0)
	TEST(@"-[digest] with SHA-1",
	    memcmp(HMACSHA1.digest, SHA1Digest, HMACSHA1.digestSize) == 0)
	TEST(@"-[digest] with RIPEMD-160",
	    memcmp(HMACRMD160.digest, RIPEMD160Digest,
	    HMACRMD160.digestSize) == 0)
	TEST(@"-[digest] with SHA-256",
	    memcmp(HMACSHA256.digest, SHA256Digest, HMACSHA256.digestSize) == 0)
	TEST(@"-[digest] with SHA-384",
	    memcmp(HMACSHA384.digest, SHA384Digest, HMACSHA384.digestSize) == 0)
	TEST(@"-[digest] with SHA-512",
	    memcmp(HMACSHA512.digest, SHA512Digest, HMACSHA512.digestSize) == 0)

	objc_autoreleasePoolPop(pool);
}
@end
