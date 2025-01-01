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

@interface OFCryptographicHashTests: OTTestCase
{
	OFStream *_stream;
}
@end

const unsigned char testFileMD5[16] =
    "\x00\x8B\x9D\x1B\x58\xDF\xF8\xFE\xEE\xF3\xAE\x8D\xBB\x68\x2D\x38";
const unsigned char testFileRIPEMD160[20] =
    "\x46\x02\x97\xF5\x85\xDF\xB9\x21\x00\xC8\xF9\x87\xC6\xEC\x84\x0D"
    "\xCE\xE6\x08\x8B";
const unsigned char testFileSHA1[20] =
    "\xC9\x9A\xB8\x7E\x1E\xC8\xEC\x65\xD5\xEB\xE4\x2E\x0D\xA6\x80\x96"
    "\xF5\x94\xE7\x17";
const unsigned char testFileSHA224[28] =
    "\x27\x69\xD8\x04\x2D\x0F\xCA\x84\x6C\xF1\x62\x44\xBA\x0C\xBD\x46"
    "\x64\x5F\x4F\x20\x02\x4D\x15\xED\x1C\x61\x1F\xF7";
const unsigned char testFileSHA256[32] =
    "\x1A\x02\xD6\x46\xF5\xA6\xBA\xAA\xFF\x7F\xD5\x87\xBA\xC3\xF6\xC6"
    "\xB5\x67\x93\x8F\x0F\x44\x90\xB8\xF5\x35\x89\xF0\x5A\x23\x7F\x69";
const unsigned char testFileSHA384[48] =
    "\x7E\xDE\x62\xE2\x10\xA5\x1E\x18\x8A\x11\x7F\x78\xD7\xC7\x55\xB6"
    "\x43\x94\x1B\xD2\x78\x5C\xCF\xF3\x8A\xB8\x98\x22\xC7\x0E\xFE\xF1"
    "\xEC\x53\xE9\x1A\xB3\x51\x70\x8C\x1F\x3F\x56\x12\x44\x01\x91\x54";
const unsigned char testFileSHA512[64] =
    "\x8F\x36\x6E\x3C\x19\x4B\xBB\xC7\x82\xAA\xCD\x7D\x55\xA2\xD3\x29"
    "\x29\x97\x6A\x3F\xEB\x9B\xB2\xCB\x75\xC9\xEC\xC8\x10\x07\xD6\x07"
    "\x31\x4A\xB1\x30\x97\x82\x58\xA5\x1F\x71\x42\xE6\x56\x07\x99\x57"
    "\xB2\xB8\x3B\xA1\x8A\x41\x64\x33\x69\x21\x8C\x2A\x44\x6D\xF2\xA0";

@implementation OFCryptographicHashTests
- (void)setUp
{
	OFIRI *IRI;

	[super setUp];

	IRI = [OFIRI IRIWithString: @"embedded:testfile.bin"];
	_stream = [[OFIRIHandler openItemAtIRI: IRI mode: @"r"] retain];
}

- (void)tearDown
{
	[_stream close];

	[super tearDown];
}

- (void)dealloc
{
	[_stream release];

	[super dealloc];
}

- (void)testHash: (Class)hashClass
  expectedDigest: (const unsigned char *)expectedDigest
{
	id <OFCryptographicHash> hash =
	    [hashClass hashWithAllowsSwappableMemory: true];
	id <OFCryptographicHash> copy;

	OTAssertNotNil(hash);

	while (!_stream.atEndOfStream) {
		char buffer[64];
		size_t length = [_stream readIntoBuffer: buffer length: 64];
		[hash updateWithBuffer: buffer length: length];
	}

	copy = [[hash copy] autorelease];

	[hash calculate];
	[copy calculate];

	OTAssertEqual(memcmp(hash.digest, expectedDigest, hash.digestSize), 0);
	OTAssertEqual(memcmp(hash.digest, expectedDigest, hash.digestSize), 0);

	OTAssertThrowsSpecific([hash updateWithBuffer: "" length: 1],
	    OFHashAlreadyCalculatedException);
}

- (void)testMD5
{
	[self testHash: [OFMD5Hash class] expectedDigest: testFileMD5];
}

- (void)testRIPEMD160
{
	[self	  testHash: [OFRIPEMD160Hash class]
	    expectedDigest: testFileRIPEMD160];
}

- (void)testSHA1
{
	[self testHash: [OFSHA1Hash class] expectedDigest: testFileSHA1];
}

- (void)testSHA224
{
	[self testHash: [OFSHA224Hash class] expectedDigest: testFileSHA224];
}

- (void)testSHA256
{
	[self testHash: [OFSHA256Hash class] expectedDigest: testFileSHA256];
}

- (void)testSHA384
{
	[self testHash: [OFSHA384Hash class] expectedDigest: testFileSHA384];
}

- (void)testSHA512
{
	[self testHash: [OFSHA512Hash class] expectedDigest: testFileSHA512];
}
@end
