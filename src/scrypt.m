/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFHMAC.h"
#import "OFSHA256Hash.h"
#import "OFSecureData.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "scrypt.h"
#import "pbkdf2.h"

void
of_salsa20_8_core(uint32_t buffer[16])
{
	uint32_t tmp[16];

	for (uint_fast8_t i = 0; i < 16; i++)
		tmp[i] = OF_BSWAP32_IF_BE(buffer[i]);

	for (uint_fast8_t i = 0; i < 8; i += 2) {
		tmp[ 4] ^= OF_ROL(tmp[ 0] + tmp[12],  7);
		tmp[ 8] ^= OF_ROL(tmp[ 4] + tmp[ 0],  9);
		tmp[12] ^= OF_ROL(tmp[ 8] + tmp[ 4], 13);
		tmp[ 0] ^= OF_ROL(tmp[12] + tmp[ 8], 18);
		tmp[ 9] ^= OF_ROL(tmp[ 5] + tmp[ 1],  7);
		tmp[13] ^= OF_ROL(tmp[ 9] + tmp[ 5],  9);
		tmp[ 1] ^= OF_ROL(tmp[13] + tmp[ 9], 13);
		tmp[ 5] ^= OF_ROL(tmp[ 1] + tmp[13], 18);
		tmp[14] ^= OF_ROL(tmp[10] + tmp[ 6],  7);
		tmp[ 2] ^= OF_ROL(tmp[14] + tmp[10],  9);
		tmp[ 6] ^= OF_ROL(tmp[ 2] + tmp[14], 13);
		tmp[10] ^= OF_ROL(tmp[ 6] + tmp[ 2], 18);
		tmp[ 3] ^= OF_ROL(tmp[15] + tmp[11],  7);
		tmp[ 7] ^= OF_ROL(tmp[ 3] + tmp[15],  9);
		tmp[11] ^= OF_ROL(tmp[ 7] + tmp[ 3], 13);
		tmp[15] ^= OF_ROL(tmp[11] + tmp[ 7], 18);
		tmp[ 1] ^= OF_ROL(tmp[ 0] + tmp[ 3],  7);
		tmp[ 2] ^= OF_ROL(tmp[ 1] + tmp[ 0],  9);
		tmp[ 3] ^= OF_ROL(tmp[ 2] + tmp[ 1], 13);
		tmp[ 0] ^= OF_ROL(tmp[ 3] + tmp[ 2], 18);
		tmp[ 6] ^= OF_ROL(tmp[ 5] + tmp[ 4],  7);
		tmp[ 7] ^= OF_ROL(tmp[ 6] + tmp[ 5],  9);
		tmp[ 4] ^= OF_ROL(tmp[ 7] + tmp[ 6], 13);
		tmp[ 5] ^= OF_ROL(tmp[ 4] + tmp[ 7], 18);
		tmp[11] ^= OF_ROL(tmp[10] + tmp[ 9],  7);
		tmp[ 8] ^= OF_ROL(tmp[11] + tmp[10],  9);
		tmp[ 9] ^= OF_ROL(tmp[ 8] + tmp[11], 13);
		tmp[10] ^= OF_ROL(tmp[ 9] + tmp[ 8], 18);
		tmp[12] ^= OF_ROL(tmp[15] + tmp[14],  7);
		tmp[13] ^= OF_ROL(tmp[12] + tmp[15],  9);
		tmp[14] ^= OF_ROL(tmp[13] + tmp[12], 13);
		tmp[15] ^= OF_ROL(tmp[14] + tmp[13], 18);
	}

	for (uint_fast8_t i = 0; i < 16; i++)
		buffer[i] = OF_BSWAP32_IF_BE(OF_BSWAP32_IF_BE(buffer[i]) +
		    tmp[i]);

	of_explicit_memset(tmp, 0, sizeof(tmp));
}

void
of_scrypt_block_mix(uint32_t *output, const uint32_t *input, size_t blockSize)
{
	uint32_t tmp[16];

	/* Check defined here and executed in of_scrypt() */
#define OVERFLOW_CHECK_1					\
	if (param.blockSize > SIZE_MAX / 2 ||			\
	    2 * param.blockSize - 1 > SIZE_MAX / 16)		\
		@throw [OFOutOfRangeException exception];

	memcpy(tmp, input + (2 * blockSize - 1) * 16, 64);

	for (size_t i = 0; i < 2 * blockSize; i++) {
		for (size_t j = 0; j < 16; j++)
			tmp[j] ^= input[i * 16 + j];

		of_salsa20_8_core(tmp);

		/*
		 * Even indices are stored in the first half and odd ones in
		 * the second.
		 */
		memcpy(output + ((i / 2) + (i & 1) * blockSize) * 16, tmp, 64);
	}

	of_explicit_memset(tmp, 0, sizeof(tmp));
}

void
of_scrypt_romix(uint32_t *buffer, size_t blockSize, size_t costFactor,
    uint32_t *tmp)
{
	/* Check defined here and executed in of_scrypt() */
#define OVERFLOW_CHECK_2						\
	if (param.blockSize > SIZE_MAX / 128 / param.costFactor)	\
		@throw [OFOutOfRangeException exception];

	uint32_t *tmp2 = tmp + 32 * blockSize;

	memcpy(tmp, buffer, 128 * blockSize);

	for (size_t i = 0; i < costFactor; i++) {
		memcpy(tmp2 + i * 32 * blockSize, tmp, 128 * blockSize);
		of_scrypt_block_mix(tmp, tmp2 + i * 32 * blockSize, blockSize);
	}

	for (size_t i = 0; i < costFactor; i++) {
		uint32_t j = OF_BSWAP32_IF_BE(tmp[(2 * blockSize - 1) * 16]) &
		    (costFactor - 1);

		for (size_t k = 0; k < 32 * blockSize; k++)
			tmp[k] ^= tmp2[j * 32 * blockSize + k];

		of_scrypt_block_mix(buffer, tmp, blockSize);

		if (i < costFactor - 1)
			memcpy(tmp, buffer, 128 * blockSize);
	}
}

void
of_scrypt(of_scrypt_parameters_t param)
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
			of_scrypt_romix(bufferItems + i * 32 * param.blockSize,
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
