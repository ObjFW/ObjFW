/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <stdio.h>
#import <string.h>

#import "OFHashes.h"
#import "OFFile.h"

const uint8_t testfile_md5[MD5_DIGEST_SIZE] =
    "\x00\x8B\x9D\x1B\x58\xDF\xF8\xFE\xEE\xF3\xAE\x8D\xBB\x68\x2D\x38";
const uint8_t testfile_sha1[SHA1_DIGEST_SIZE] =
    "\xC9\x9A\xB8\x7E\x1E\xC8\xEC\x65\xD5\xEB\xE4\x2E\x0D\xA6\x80\x96\xF5"
    "\x94\xE7\x17";

int
main()
{
	uint8_t buf[64];
	size_t	len;

	OFMD5Hash  *md5  = [OFMD5Hash new];
	OFSHA1Hash *sha1 = [OFSHA1Hash new];
	OFFile *f = [OFFile newWithPath: "testfile"
				andMode: "rb"];

	while (![f atEndOfFile]) {
		len = [f readIntoBuffer: buf
			       withSize: 1
			      andNItems: 64];
		[md5 updateWithBuffer: buf
			       ofSize: len];
		[sha1 updateWithBuffer: buf
				ofSize: len];
	}
	[f free];

	if (!memcmp([md5 digest], testfile_md5, MD5_DIGEST_SIZE))
		puts("Correct MD5 sum calculated!");
	else {
		puts("MD5 SUM MISMATCH!!");
		return 1;
	}
	[md5 free];

	if (!memcmp([sha1 digest], testfile_sha1, SHA1_DIGEST_SIZE))
		puts("Correct SHA1 sum calculated!");
	else {
		puts("SHA1 SUM MISMATCH!!");
		return 1;
	}
	[sha1 free];

	return 0;
}
