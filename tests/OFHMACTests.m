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

@interface OFHMACTests: OTTestCase
{
	OFStream *_stream;
}
@end

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

@implementation OFHMACTests
- (void)setUp
{
	OFIRI *IRI;

	[super setUp];

	IRI = [OFIRI IRIWithString: @"embedded:testfile.bin"];
	_stream = objc_retain([OFIRIHandler openItemAtIRI: IRI mode: @"r"]);
}

- (void)tearDown
{
	[_stream close];

	[super tearDown];
}

- (void)dealloc
{
	objc_release(_stream);

	[super dealloc];
}

- (void)testWithHashClass: (Class)hashClass
	   expectedDigest: (const unsigned char *)expectedDigest
{
	OFHMAC *HMAC = [OFHMAC HMACWithHashClass: hashClass
			   allowsSwappableMemory: true];

	OTAssertNotNil(HMAC);

	OTAssertThrowsSpecific([HMAC updateWithBuffer: "" length: 0],
	    OFInvalidArgumentException);

	[HMAC setKey: key length: keyLength];

	while (!_stream.atEndOfStream) {
		char buffer[64];
		size_t length = [_stream readIntoBuffer: buffer length: 64];
		[HMAC updateWithBuffer: buffer length: length];
	}

	[HMAC calculate];

	OTAssertEqual(memcmp(HMAC.digest, expectedDigest, HMAC.digestSize), 0);
}

- (void)testHMACWithMD5
{
	[self testWithHashClass: [OFMD5Hash class] expectedDigest: MD5Digest];
}

- (void)testHMACWithRIPEMD160
{
	[self testWithHashClass: [OFRIPEMD160Hash class]
		 expectedDigest: RIPEMD160Digest];
}

- (void)testHMACWithSHA1
{
	[self testWithHashClass: [OFSHA1Hash class] expectedDigest: SHA1Digest];
}

- (void)testHMACWithSHA256
{
	[self testWithHashClass: [OFSHA256Hash class]
		 expectedDigest: SHA256Digest];
}

- (void)testHMACWithSHA384
{
	[self testWithHashClass: [OFSHA384Hash class]
		 expectedDigest: SHA384Digest];
}

- (void)testHMACWithSHA512
{
	[self testWithHashClass: [OFSHA512Hash class]
		 expectedDigest: SHA512Digest];
}
@end
