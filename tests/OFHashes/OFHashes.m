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

#import <stdio.h>
#import <string.h>

#import "OFHashes.h"
#import "OFFile.h"

const uint8_t testfile_md5[16] =
    "\x00\x8B\x9D\x1B\x58\xDF\xF8\xFE\xEE\xF3\xAE\x8D\xBB\x68\x2D\x38";

int
main()
{
	uint8_t buf[64];
	size_t	len;

	OFMD5Hash *md5 = [OFMD5Hash new];
	OFFile *f = [OFFile newWithPath: "testfile"
				andMode: "r"];

	while (![f atEndOfFile]) {
		len = [f readIntoBuffer: buf
			       withSize: 1
			      andNItems: 64];
		[md5 updateWithBuffer: buf
			       ofSize: len];
	}
	[f free];

	if (!memcmp([md5 digest], testfile_md5, 16))
		puts("Correct MD5 sum calculated!");
	else {
		puts("MD5 SUM MISMATCH!!");
		return 1;
	}
	[md5 free];

	return 0;
}
