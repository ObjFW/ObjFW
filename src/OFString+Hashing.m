/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFString.h"
#import "OFHash.h"
#import "OFMD5Hash.h"
#import "OFRIPEMD160Hash.h"
#import "OFSHA1Hash.h"
#import "OFSHA224Hash.h"
#import "OFSHA256Hash.h"
#import "OFSHA384Hash.h"
#import "OFSHA512Hash.h"

int _OFString_Hashing_reference;

@implementation OFString (Hashing)
- (OFString*)OF_hashAsStringWithHash: (Class <OFHash>)hashClass
{
	void *pool = objc_autoreleasePoolPush();
	id <OFHash> hash = [hashClass hash];
	size_t digestSize = [hashClass digestSize];
	const uint8_t *digest;
	char cString[digestSize * 2];
	size_t i;

	[hash updateWithBuffer: [self UTF8String]
			length: [self UTF8StringLength]];
	digest = [hash digest];

	for (i = 0; i < digestSize; i++) {
		uint8_t high, low;

		high = digest[i] >> 4;
		low  = digest[i] & 0x0F;

		cString[i * 2] = (high > 9 ? high - 10 + 'a' : high + '0');
		cString[i * 2 + 1] = (low > 9 ? low - 10 + 'a' : low + '0');
	}

	objc_autoreleasePoolPop(pool);

	return [OFString stringWithCString: cString
				  encoding: OF_STRING_ENCODING_ASCII
				    length: digestSize * 2];
}

- (OFString*)MD5Hash
{
	return [self OF_hashAsStringWithHash: [OFMD5Hash class]];
}

- (OFString*)RIPEMD160Hash
{
	return [self OF_hashAsStringWithHash: [OFRIPEMD160Hash class]];
}

- (OFString*)SHA1Hash
{
	return [self OF_hashAsStringWithHash: [OFSHA1Hash class]];
}

- (OFString*)SHA224Hash
{
	return [self OF_hashAsStringWithHash: [OFSHA224Hash class]];
}

- (OFString*)SHA256Hash
{
	return [self OF_hashAsStringWithHash: [OFSHA256Hash class]];
}

- (OFString*)SHA384Hash
{
	return [self OF_hashAsStringWithHash: [OFSHA384Hash class]];
}

- (OFString*)SHA512Hash
{
	return [self OF_hashAsStringWithHash: [OFSHA512Hash class]];
}
@end
