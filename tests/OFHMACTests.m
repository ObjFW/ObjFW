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

static OFString *module = @"OFHMAC";
static const uint8_t key[] =
    "yM9h8K6IWnJRvxC/0F8XRWG7RnACDBz8wqK2tbXrYVLoKC3vPLeJikyJSM47tVHc"
    "DlXHww9zULAC2sJUlm2Kg1z4oz2aXY3Y1PQSB4VkC/m0DQ7hCI6cAg4TWnKdzWTy"
    "cvYGX+Y6HWeDY79/PGSd8fNItme6I8w4HDBqU7BP2sum3jbePJqoiSnhcyJZQTeZ"
    "jw0ZXoyrfHgOYD2M+NsTDaGpLblFtQ7n5CczjKtafG40PkEwx1dcrd46U9i3GyTK";
static const size_t key_length = sizeof(key);
static const uint8_t digest_md5[] =
    "\xCC\x1F\xEF\x09\x29\xA3\x25\x1A\x06\xA9\x83\x99\xF9\xBC\x8F\x42";
static const uint8_t digest_sha1[] =
    "\x94\xB9\x0A\x6F\xFB\xA7\x13\x6A\x75\x55"
    "\xD5\x7F\x5D\xB7\xF4\xCA\xEB\x4A\xDE\xBF";
static const uint8_t digest_rmd160[] =
    "\x2C\xE1\xED\x41\xC6\xF3\x51\xA8\x04\xD2"
    "\xC3\x9B\x08\x33\x3B\xD5\xC9\x00\x39\x50";
static const uint8_t digest_sha256[] =
    "\xFB\x8C\xDA\x88\xB3\x81\x32\x16\xD7\xD8\x62\xD4\xA6\x26\x9D\x77"
    "\x01\x99\x62\x65\x29\x02\x41\xE6\xEF\xA1\x02\x31\xA8\x9D\x77\x5D";
static const uint8_t digest_sha384[] =
    "\x2F\x4A\x47\xAE\x13\x8E\x96\x52\xF1\x8F\x05\xFD\x65\xCD\x9A\x97"
    "\x93\x2F\xC9\x02\xD6\xC6\xAB\x2E\x15\x76\xC0\xA7\xA0\x05\xF4\xEF"
    "\x14\x52\x33\x4B\x9C\x5F\xD8\x07\x4E\x98\xAE\x97\x46\x29\x24\xB4";
static const uint8_t digest_sha512[] =
    "\xF5\x8C\x3F\x9C\xA2\x2F\x0A\xF3\x26\xD8\xC0\x7E\x20\x63\x88\x61"
    "\xC9\xE1\x1F\xD7\xC7\xE5\x59\x33\xD5\x2F\xAF\x56\x1C\x94\xC8\xA4"
    "\x61\xB3\xF9\x1A\xE3\x09\x43\xA6\x5B\x85\xB1\x50\x5B\xCB\x1A\x2E"
    "\xB7\xE8\x87\xC1\x73\x19\x63\xF6\xA2\x91\x8D\x7E\x2E\xCC\xEC\x99";

@implementation TestsAppDelegate (OFHMACTests)
- (void)HMACTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFFile *f = [OFFile fileWithPath: @"testfile.bin"
				    mode: @"r"];
	OFHMAC *HMAC_MD5, *HMAC_SHA1, *HMAC_RMD160;
	OFHMAC *HMAC_SHA256, *HMAC_SHA384, *HMAC_SHA512;

	TEST(@"+[HMACWithHashClass:] with MD5",
	    (HMAC_MD5 = [OFHMAC HMACWithHashClass: [OFMD5Hash class]]))
	TEST(@"+[HMACWithHashClass:] with SHA-1",
	    (HMAC_SHA1 = [OFHMAC HMACWithHashClass: [OFSHA1Hash class]]))
	TEST(@"+[HMACWithHashClass:] with RIPEMD-160",
	    (HMAC_RMD160 = [OFHMAC HMACWithHashClass: [OFRIPEMD160Hash class]]))
	TEST(@"+[HMACWithHashClass:] with SHA-256",
	    (HMAC_SHA256 = [OFHMAC HMACWithHashClass: [OFSHA256Hash class]]))
	TEST(@"+[HMACWithHashClass:] with SHA-384",
	    (HMAC_SHA384 = [OFHMAC HMACWithHashClass: [OFSHA384Hash class]]))
	TEST(@"+[HMACWithHashClass:] with SHA-512",
	    (HMAC_SHA512 = [OFHMAC HMACWithHashClass: [OFSHA512Hash class]]))

	EXPECT_EXCEPTION(@"Detection of missing key",
	    OFInvalidArgumentException, [HMAC_MD5 updateWithBuffer: ""
							    length: 0])

	TEST(@"-[setKey:length:] with MD5",
	    R([HMAC_MD5 setKey: key
			length: key_length]))
	TEST(@"-[setKey:length:] with SHA-1",
	    R([HMAC_SHA1 setKey: key
			 length: key_length]))
	TEST(@"-[setKey:length:] with RIPEMD-160",
	    R([HMAC_RMD160 setKey: key
			   length: key_length]))
	TEST(@"-[setKey:length:] with SHA-256",
	    R([HMAC_SHA256 setKey: key
			   length: key_length]))
	TEST(@"-[setKey:length:] with SHA-384",
	    R([HMAC_SHA384 setKey: key
			   length: key_length]))
	TEST(@"-[setKey:length:] with SHA-512",
	    R([HMAC_SHA512 setKey: key
			   length: key_length]))

	while (![f isAtEndOfStream]) {
		char buf[64];
		size_t len = [f readIntoBuffer: buf
					length: 64];
		[HMAC_MD5 updateWithBuffer: buf
				    length: len];
		[HMAC_SHA1 updateWithBuffer: buf
				     length: len];
		[HMAC_RMD160 updateWithBuffer: buf
				       length: len];
		[HMAC_SHA256 updateWithBuffer: buf
				       length: len];
		[HMAC_SHA384 updateWithBuffer: buf
				       length: len];
		[HMAC_SHA512 updateWithBuffer: buf
				       length: len];
	}
	[f close];

	TEST(@"-[digest] with MD5",
	    memcmp([HMAC_MD5 digest], digest_md5, [HMAC_MD5 digestSize]) == 0)
	TEST(@"-[digest] with SHA-1",
	    memcmp([HMAC_SHA1 digest], digest_sha1,
	    [HMAC_SHA1 digestSize]) == 0)
	TEST(@"-[digest] with RIPEMD-160",
	    memcmp([HMAC_RMD160 digest], digest_rmd160,
	    [HMAC_RMD160 digestSize]) == 0)
	TEST(@"-[digest] with SHA-256",
	    memcmp([HMAC_SHA256 digest], digest_sha256,
	    [HMAC_SHA256 digestSize]) == 0)
	TEST(@"-[digest] with SHA-384",
	    memcmp([HMAC_SHA384 digest], digest_sha384,
	    [HMAC_SHA384 digestSize]) == 0)
	TEST(@"-[digest] with SHA-512",
	    memcmp([HMAC_SHA512 digest], digest_sha512,
	    [HMAC_SHA512 digestSize]) == 0)

	[pool drain];
}
@end
