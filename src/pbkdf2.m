/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include <stdlib.h>

#import "OFHMAC.h"
#import "OFSecureData.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "pbkdf2.h"

void of_pbkdf2(OFHMAC *HMAC, size_t iterations,
    const unsigned char *salt, size_t saltLength,
    const char *password, size_t passwordLength,
    unsigned char *key, size_t keyLength)
{
	void *pool = objc_autoreleasePoolPush();
	size_t blocks, digestSize = [HMAC digestSize];
	OFSecureData *buffer = [OFSecureData dataWithCount: digestSize];
	OFSecureData *digest = [OFSecureData dataWithCount: digestSize];
	unsigned char *bufferItems = [buffer items];
	unsigned char *digestItems = [digest items];
	OFSecureData *extendedSalt;
	unsigned char *extendedSaltItems;

	if (HMAC == nil || iterations == 0 || salt == NULL ||
	    password == NULL || key == NULL || keyLength == 0)
		@throw [OFInvalidArgumentException exception];

	blocks = keyLength / digestSize;
	if (keyLength % digestSize != 0)
		blocks++;

	if (saltLength > SIZE_MAX - 4 || blocks > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	extendedSalt = [OFSecureData dataWithCount: saltLength + 4];
	extendedSaltItems = [extendedSalt items];

	@try {
		uint32_t i = OF_BSWAP32_IF_LE(1);

		[HMAC setKey: password
		      length: passwordLength];

		memcpy(extendedSaltItems, salt, saltLength);

		while (keyLength > 0) {
			size_t length;

			memcpy(extendedSaltItems + saltLength, &i, 4);

			[HMAC reset];
			[HMAC updateWithBuffer: extendedSaltItems
					length: saltLength + 4];
			memcpy(bufferItems, [HMAC digest], digestSize);
			memcpy(digestItems, [HMAC digest], digestSize);

			for (size_t j = 1; j < iterations; j++) {
				[HMAC reset];
				[HMAC updateWithBuffer: digestItems
						length: digestSize];
				memcpy(digestItems, [HMAC digest], digestSize);

				for (size_t k = 0; k < digestSize; k++)
					bufferItems[k] ^= digestItems[k];
			}

			length = digestSize;
			if (length > keyLength)
				length = keyLength;

			memcpy(key, bufferItems, length);
			key += length;
			keyLength -= length;

			i = OF_BSWAP32_IF_LE(OF_BSWAP32_IF_LE(i) + 1);
		}
	} @catch (id e) {
		[extendedSalt zero];
		[buffer zero];
		[digest zero];

		@throw e;
	} @finally {
		[HMAC zero];
	}

	objc_autoreleasePoolPop(pool);
}
