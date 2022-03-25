/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFData+CryptographicHashing.h"
#import "OFString.h"
#import "OFCryptographicHash.h"
#import "OFMD5Hash.h"
#import "OFRIPEMD160Hash.h"
#import "OFSHA1Hash.h"
#import "OFSHA224Hash.h"
#import "OFSHA256Hash.h"
#import "OFSHA384Hash.h"
#import "OFSHA512Hash.h"

int _OFData_CryptographicHashing_reference;

@implementation OFData (CryptographicHashing)
static OFString *
stringByHashing(Class <OFCryptographicHash> class, OFData *self)
{
	void *pool = objc_autoreleasePoolPush();
	id <OFCryptographicHash> hash =
	    [class hashWithAllowsSwappableMemory: true];
	size_t digestSize = [class digestSize];
	const unsigned char *digest;
	char cString[digestSize * 2];

	[hash updateWithBuffer: self->_items
			length: self->_count * self->_itemSize];
	[hash calculate];
	digest = hash.digest;

	for (size_t i = 0; i < digestSize; i++) {
		uint8_t high, low;

		high = digest[i] >> 4;
		low  = digest[i] & 0x0F;

		cString[i * 2] = (high > 9 ? high - 10 + 'a' : high + '0');
		cString[i * 2 + 1] = (low > 9 ? low - 10 + 'a' : low + '0');
	}

	objc_autoreleasePoolPop(pool);

	return [OFString stringWithCString: cString
				  encoding: OFStringEncodingASCII
				    length: digestSize * 2];
}

- (OFString *)stringByMD5Hashing
{
	return stringByHashing([OFMD5Hash class], self);
}

- (OFString *)stringByRIPEMD160Hashing
{
	return stringByHashing([OFRIPEMD160Hash class], self);
}

- (OFString *)stringBySHA1Hashing
{
	return stringByHashing([OFSHA1Hash class], self);
}

- (OFString *)stringBySHA224Hashing
{
	return stringByHashing([OFSHA224Hash class], self);
}

- (OFString *)stringBySHA256Hashing
{
	return stringByHashing([OFSHA256Hash class], self);
}

- (OFString *)stringBySHA384Hashing
{
	return stringByHashing([OFSHA384Hash class], self);
}

- (OFString *)stringBySHA512Hashing
{
	return stringByHashing([OFSHA512Hash class], self);
}
@end
