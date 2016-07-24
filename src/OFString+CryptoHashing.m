/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFString.h"
#import "OFCryptoHash.h"
#import "OFMD5Hash.h"
#import "OFRIPEMD160Hash.h"
#import "OFSHA1Hash.h"
#import "OFSHA224Hash.h"
#import "OFSHA256Hash.h"
#import "OFSHA384Hash.h"
#import "OFSHA512Hash.h"

int _OFString_CryptoHashing_reference;

@implementation OFString (CryptoHashing)
- (OFString*)OF_cryptoHashWithClass: (Class <OFCryptoHash>)class
{
	void *pool = objc_autoreleasePoolPush();
	id <OFCryptoHash> hash = [class cryptoHash];
	size_t digestSize = [class digestSize];
	const uint8_t *digest;
	char cString[digestSize * 2];

	[hash updateWithBuffer: [self UTF8String]
			length: [self UTF8StringLength]];
	digest = [hash digest];

	for (size_t i = 0; i < digestSize; i++) {
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
	return [self OF_cryptoHashWithClass: [OFMD5Hash class]];
}

- (OFString*)RIPEMD160Hash
{
	return [self OF_cryptoHashWithClass: [OFRIPEMD160Hash class]];
}

- (OFString*)SHA1Hash
{
	return [self OF_cryptoHashWithClass: [OFSHA1Hash class]];
}

- (OFString*)SHA224Hash
{
	return [self OF_cryptoHashWithClass: [OFSHA224Hash class]];
}

- (OFString*)SHA256Hash
{
	return [self OF_cryptoHashWithClass: [OFSHA256Hash class]];
}

- (OFString*)SHA384Hash
{
	return [self OF_cryptoHashWithClass: [OFSHA384Hash class]];
}

- (OFString*)SHA512Hash
{
	return [self OF_cryptoHashWithClass: [OFSHA512Hash class]];
}
@end
