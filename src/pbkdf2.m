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

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "pbkdf2.h"

void of_pbkdf2(OFHMAC *HMAC, size_t iterations,
    const unsigned char *salt, size_t saltLength,
    const char *password, size_t passwordLength,
    unsigned char *key, size_t keyLength)
{
	size_t blocks, digestSize = [HMAC digestSize];
	unsigned char *extendedSalt;
	unsigned char buffer[digestSize];
	unsigned char digest[digestSize];

	if (HMAC == nil || iterations == 0 || salt == NULL ||
	    password == NULL || key == NULL || keyLength == 0)
		@throw [OFInvalidArgumentException exception];

	blocks = keyLength / digestSize;
	if (keyLength % digestSize != 0)
		blocks++;

	if (saltLength > SIZE_MAX - 4 || blocks > UINT32_MAX)
		@throw [OFOutOfRangeException exception];

	if ((extendedSalt = malloc(saltLength + 4)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: saltLength + 4];

	@try {
		uint32_t i = OF_BSWAP32_IF_LE(1);

		[HMAC setKey: password
		      length: passwordLength];

		memcpy(extendedSalt, salt, saltLength);

		while (keyLength > 0) {
			size_t length;

			memcpy(extendedSalt + saltLength, &i, 4);

			[HMAC reset];
			[HMAC updateWithBuffer: extendedSalt
					length: saltLength + 4];
			memcpy(buffer, [HMAC digest], digestSize);
			memcpy(digest, [HMAC digest], digestSize);

			for (size_t j = 1; j < iterations; j++) {
				[HMAC reset];
				[HMAC updateWithBuffer: digest
						length: digestSize];
				memcpy(digest, [HMAC digest], digestSize);

				for (size_t k = 0; k < digestSize; k++)
					buffer[k] ^= digest[k];
			}

			length = digestSize;
			if (length > keyLength)
				length = keyLength;

			memcpy(key, buffer, length);
			key += length;
			keyLength -= length;

			i = OF_BSWAP32_IF_LE(OF_BSWAP32_IF_LE(i) + 1);
		}
	} @finally {
		of_explicit_memset(extendedSalt, 0, saltLength + 4);
		of_explicit_memset(buffer, 0, digestSize);
		of_explicit_memset(digest, 0, digestSize);

		[HMAC zero];

		free(extendedSalt);
	}
}
