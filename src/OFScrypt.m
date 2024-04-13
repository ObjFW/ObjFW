/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFHMAC.h"
#import "OFSHA256Hash.h"
#import "OFSecureData.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "OFScrypt.h"
#import "OFPBKDF2.h"

void
OFSalsa20_8Core(uint32_t buffer[16])
{
	uint32_t tmp[16];

	for (uint_fast8_t i = 0; i < 16; i++)
		tmp[i] = OFToLittleEndian32(buffer[i]);

	for (uint_fast8_t i = 0; i < 8; i += 2) {
		tmp[ 4] ^= OFRotateLeft(tmp[ 0] + tmp[12],  7);
		tmp[ 8] ^= OFRotateLeft(tmp[ 4] + tmp[ 0],  9);
		tmp[12] ^= OFRotateLeft(tmp[ 8] + tmp[ 4], 13);
		tmp[ 0] ^= OFRotateLeft(tmp[12] + tmp[ 8], 18);
		tmp[ 9] ^= OFRotateLeft(tmp[ 5] + tmp[ 1],  7);
		tmp[13] ^= OFRotateLeft(tmp[ 9] + tmp[ 5],  9);
		tmp[ 1] ^= OFRotateLeft(tmp[13] + tmp[ 9], 13);
		tmp[ 5] ^= OFRotateLeft(tmp[ 1] + tmp[13], 18);
		tmp[14] ^= OFRotateLeft(tmp[10] + tmp[ 6],  7);
		tmp[ 2] ^= OFRotateLeft(tmp[14] + tmp[10],  9);
		tmp[ 6] ^= OFRotateLeft(tmp[ 2] + tmp[14], 13);
		tmp[10] ^= OFRotateLeft(tmp[ 6] + tmp[ 2], 18);
		tmp[ 3] ^= OFRotateLeft(tmp[15] + tmp[11],  7);
		tmp[ 7] ^= OFRotateLeft(tmp[ 3] + tmp[15],  9);
		tmp[11] ^= OFRotateLeft(tmp[ 7] + tmp[ 3], 13);
		tmp[15] ^= OFRotateLeft(tmp[11] + tmp[ 7], 18);
		tmp[ 1] ^= OFRotateLeft(tmp[ 0] + tmp[ 3],  7);
		tmp[ 2] ^= OFRotateLeft(tmp[ 1] + tmp[ 0],  9);
		tmp[ 3] ^= OFRotateLeft(tmp[ 2] + tmp[ 1], 13);
		tmp[ 0] ^= OFRotateLeft(tmp[ 3] + tmp[ 2], 18);
		tmp[ 6] ^= OFRotateLeft(tmp[ 5] + tmp[ 4],  7);
		tmp[ 7] ^= OFRotateLeft(tmp[ 6] + tmp[ 5],  9);
		tmp[ 4] ^= OFRotateLeft(tmp[ 7] + tmp[ 6], 13);
		tmp[ 5] ^= OFRotateLeft(tmp[ 4] + tmp[ 7], 18);
		tmp[11] ^= OFRotateLeft(tmp[10] + tmp[ 9],  7);
		tmp[ 8] ^= OFRotateLeft(tmp[11] + tmp[10],  9);
		tmp[ 9] ^= OFRotateLeft(tmp[ 8] + tmp[11], 13);
		tmp[10] ^= OFRotateLeft(tmp[ 9] + tmp[ 8], 18);
		tmp[12] ^= OFRotateLeft(tmp[15] + tmp[14],  7);
		tmp[13] ^= OFRotateLeft(tmp[12] + tmp[15],  9);
		tmp[14] ^= OFRotateLeft(tmp[13] + tmp[12], 13);
		tmp[15] ^= OFRotateLeft(tmp[14] + tmp[13], 18);
	}

	for (uint_fast8_t i = 0; i < 16; i++)
		buffer[i] = OFToLittleEndian32(OFFromLittleEndian32(buffer[i]) +
		    tmp[i]);

	OFZeroMemory(tmp, sizeof(tmp));
}

void
OFScryptBlockMix(uint32_t *output, const uint32_t *input, size_t blockSize)
{
	uint32_t tmp[16];

	/* Check defined here and executed in OFScrypt() */
#define OVERFLOW_CHECK_1					\
	if (param.blockSize > SIZE_MAX / 2 ||			\
	    2 * param.blockSize - 1 > SIZE_MAX / 16)		\
		@throw [OFOutOfRangeException exception];

	memcpy(tmp, input + (2 * blockSize - 1) * 16, 64);

	for (size_t i = 0; i < 2 * blockSize; i++) {
		for (size_t j = 0; j < 16; j++)
			tmp[j] ^= input[i * 16 + j];

		OFSalsa20_8Core(tmp);

		/*
		 * Even indices are stored in the first half and odd ones in
		 * the second.
		 */
		memcpy(output + ((i / 2) + (i & 1) * blockSize) * 16, tmp, 64);
	}

	OFZeroMemory(tmp, sizeof(tmp));
}

void
OFScryptROMix(uint32_t *buffer, size_t blockSize, size_t costFactor,
    uint32_t *tmp)
{
	/* Check defined here and executed in OFScrypt() */
#define OVERFLOW_CHECK_2						\
	if (param.blockSize > SIZE_MAX / 128 / param.costFactor)	\
		@throw [OFOutOfRangeException exception];

	uint32_t *tmp2 = tmp + 32 * blockSize;

	memcpy(tmp, buffer, 128 * blockSize);

	for (size_t i = 0; i < costFactor; i++) {
		memcpy(tmp2 + i * 32 * blockSize, tmp, 128 * blockSize);
		OFScryptBlockMix(tmp, tmp2 + i * 32 * blockSize, blockSize);
	}

	for (size_t i = 0; i < costFactor; i++) {
		uint32_t j = OFFromLittleEndian32(
		    tmp[(2 * blockSize - 1) * 16]) & (costFactor - 1);

		for (size_t k = 0; k < 32 * blockSize; k++)
			tmp[k] ^= tmp2[j * 32 * blockSize + k];

		OFScryptBlockMix(buffer, tmp, blockSize);

		if (i < costFactor - 1)
			memcpy(tmp, buffer, 128 * blockSize);
	}
}

void
OFScrypt(OFScryptParameters param)
{
	OFSecureData *tmp = nil, *buffer = nil;
	OFHMAC *HMAC = nil;

	if (param.blockSize == 0 || param.costFactor <= 1 ||
	    (param.costFactor & (param.costFactor - 1)) != 0 ||
	    param.parallelization == 0)
		@throw [OFInvalidArgumentException exception];

	/*
	 * These are defined by the functions above. They are defined there so
	 * that the check is next to the code and easy to verify, but actually
	 * checked here for performance.
	 */
	OVERFLOW_CHECK_1
	OVERFLOW_CHECK_2

	@try {
		uint32_t *tmpItems, *bufferItems;

		if (param.costFactor > SIZE_MAX - 1 ||
		    (param.costFactor + 1) > SIZE_MAX / 128)
			@throw [OFOutOfRangeException exception];

		tmp = [[OFSecureData alloc]
			    initWithCount: (param.costFactor + 1) * 128
				 itemSize: param.blockSize
		    allowsSwappableMemory: param.allowsSwappableMemory];
		tmpItems = tmp.mutableItems;

		if (param.parallelization > SIZE_MAX / 128)
			@throw [OFOutOfRangeException exception];

		buffer = [[OFSecureData alloc]
			    initWithCount: param.parallelization * 128
				 itemSize: param.blockSize
		    allowsSwappableMemory: param.allowsSwappableMemory];
		bufferItems = buffer.mutableItems;

		HMAC = [[OFHMAC alloc]
			initWithHashClass: [OFSHA256Hash class]
		    allowsSwappableMemory: param.allowsSwappableMemory];

		OFPBKDF2((OFPBKDF2Parameters){
			.HMAC                  = HMAC,
			.iterations            = 1,
			.salt                  = param.salt,
			.saltLength            = param.saltLength,
			.password              = param.password,
			.passwordLength        = param.passwordLength,
			.key                   = (unsigned char *)bufferItems,
			.keyLength             = param.parallelization * 128 *
			                         param.blockSize,
			.allowsSwappableMemory = param.allowsSwappableMemory
		});

		for (size_t i = 0; i < param.parallelization; i++)
			OFScryptROMix(bufferItems + i * 32 * param.blockSize,
			    param.blockSize, param.costFactor, tmpItems);

		OFPBKDF2((OFPBKDF2Parameters){
			.HMAC                  = HMAC,
			.iterations            = 1,
			.salt                  = (unsigned char *)bufferItems,
			.saltLength            = param.parallelization * 128 *
			                         param.blockSize,
			.password              = param.password,
			.passwordLength        = param.passwordLength,
			.key                   = param.key,
			.keyLength             = param.keyLength,
			.allowsSwappableMemory = param.allowsSwappableMemory
		});
	} @finally {
		[tmp release];
		[buffer release];
		[HMAC release];
	}
}
