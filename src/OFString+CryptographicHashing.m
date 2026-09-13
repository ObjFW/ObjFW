/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFString.h"
#import "OFCryptographicHash.h"
#import "OFMD5Hash.h"
#import "OFRIPEMD160Hash.h"
#import "OFSHA1Hash.h"
#import "OFSHA224Hash.h"
#import "OFSHA256Hash.h"
#import "OFSHA384Hash.h"
#import "OFSHA512Hash.h"

int _OFString_CryptographicHashing_reference;

@implementation OFString (CryptographicHashing)
static OFString *
stringByHashing(Class <OFCryptographicHash> class, OFString *self)
{
	void *pool = objc_autoreleasePoolPush();
	id <OFCryptographicHash> hash =
	    [class hashWithAllowsSwappableMemory: true];
	size_t digestSize = [class digestSize];
	const unsigned char *digest;
	char cString[digestSize * 2];

	[hash updateWithBuffer: self.UTF8String length: self.UTF8StringLength];
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
