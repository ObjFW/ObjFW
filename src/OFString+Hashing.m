/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFString.h"
#import "OFMD5Hash.h"
#import "OFSHA1Hash.h"
#import "OFAutoreleasePool.h"

int _OFString_Hashing_reference;

@implementation OFString (Hashing)
- (OFString*)md5Hash
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMD5Hash *hash = [OFMD5Hash md5Hash];
	uint8_t *digest;
	char ret_c[32];
	size_t i;

	[hash updateWithBuffer: string
			ofSize: length];
	digest = [hash digest];

	for (i = 0; i < 16; i++) {
		uint8_t high, low;

		high = digest[i] >> 4;
		low  = digest[i] & 0x0F;

		ret_c[i * 2] = (high > 9 ? high - 10 + 'a' : high + '0');
		ret_c[i * 2 + 1] = (low > 9 ? low - 10 + 'a' : low + '0');
	}

	[pool release];

	return [OFString stringWithCString: ret_c
				    length: 32];
}

- (OFString*)sha1Hash
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMD5Hash *hash = [OFSHA1Hash sha1Hash];
	uint8_t *digest;
	char ret_c[40];
	size_t i;

	[hash updateWithBuffer: string
			ofSize: length];
	digest = [hash digest];

	for (i = 0; i < 20; i++) {
		uint8_t high, low;

		high = digest[i] >> 4;
		low  = digest[i] & 0x0F;

		ret_c[i * 2] = (high > 9 ? high - 10 + 'a' : high + '0');
		ret_c[i * 2 + 1] = (low > 9 ? low - 10 + 'a' : low + '0');
	}

	[pool release];

	return [OFString stringWithCString: ret_c
				    length: 40];
}
@end
