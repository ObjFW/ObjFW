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

#include <stdlib.h>

#import "OFPBKDF2.h"
#import "OFHMAC.h"
#import "OFSecureData.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

void
OFPBKDF2(OFPBKDF2Parameters param)
{
	void *pool = objc_autoreleasePoolPush();
	size_t blocks, digestSize = param.HMAC.digestSize;
	OFSecureData *buffer = [OFSecureData
		    dataWithCount: digestSize
	    allowsSwappableMemory: param.allowsSwappableMemory];
	OFSecureData *digest = [OFSecureData
		    dataWithCount: digestSize
	    allowsSwappableMemory: param.allowsSwappableMemory];
	unsigned char *bufferItems = buffer.mutableItems;
	unsigned char *digestItems = digest.mutableItems;
	OFSecureData *extendedSalt;
	unsigned char *extendedSaltItems;

	if (param.HMAC == nil || param.iterations == 0 || param.salt == NULL ||
	    param.password == NULL || param.key == NULL || param.keyLength == 0)
		@throw [OFInvalidArgumentException exception];

	blocks = param.keyLength / digestSize;
	if (param.keyLength % digestSize != 0)
		blocks++;

	if (param.saltLength > SIZE_MAX - 4 || blocks > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	extendedSalt = [OFSecureData
		    dataWithCount: param.saltLength + 4
	    allowsSwappableMemory: param.allowsSwappableMemory];
	extendedSaltItems = extendedSalt.mutableItems;

	@try {
		uint32_t i = OFToBigEndian32(1);

		[param.HMAC setKey: param.password
			    length: param.passwordLength];

		memcpy(extendedSaltItems, param.salt, param.saltLength);

		while (param.keyLength > 0) {
			size_t length;

			memcpy(extendedSaltItems + param.saltLength, &i, 4);

			[param.HMAC reset];
			[param.HMAC updateWithBuffer: extendedSaltItems
					      length: param.saltLength + 4];
			[param.HMAC calculate];
			memcpy(bufferItems, param.HMAC.digest, digestSize);
			memcpy(digestItems, param.HMAC.digest, digestSize);

			for (size_t j = 1; j < param.iterations; j++) {
				[param.HMAC reset];
				[param.HMAC updateWithBuffer: digestItems
						      length: digestSize];
				[param.HMAC calculate];
				memcpy(digestItems, param.HMAC.digest,
				    digestSize);

				for (size_t k = 0; k < digestSize; k++)
					bufferItems[k] ^= digestItems[k];
			}

			length = digestSize;
			if (length > param.keyLength)
				length = param.keyLength;

			memcpy(param.key, bufferItems, length);
			param.key += length;
			param.keyLength -= length;

			i = OFToBigEndian32(OFFromBigEndian32(i) + 1);
		}
	} @catch (id e) {
		[extendedSalt zero];
		[buffer zero];
		[digest zero];

		@throw e;
	} @finally {
		[param.HMAC zero];
	}

	objc_autoreleasePoolPop(pool);
}
