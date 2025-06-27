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
#include <string.h>

#import "OFSHA384Or512Hash.h"
#import "OFSecureData.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFHashNotCalculatedException.h"
#import "OFOutOfRangeException.h"

static const size_t blockSize = 128;

@interface OFSHA384Or512Hash ()
- (void)of_resetState;
@end

static const uint64_t table[] = {
	0x428A2F98D728AE22, 0x7137449123EF65CD, 0xB5C0FBCFEC4D3B2F,
	0xE9B5DBA58189DBBC, 0x3956C25BF348B538, 0x59F111F1B605D019,
	0x923F82A4AF194F9B, 0xAB1C5ED5DA6D8118, 0xD807AA98A3030242,
	0x12835B0145706FBE, 0x243185BE4EE4B28C, 0x550C7DC3D5FFB4E2,
	0x72BE5D74F27B896F, 0x80DEB1FE3B1696B1, 0x9BDC06A725C71235,
	0xC19BF174CF692694, 0xE49B69C19EF14AD2, 0xEFBE4786384F25E3,
	0x0FC19DC68B8CD5B5, 0x240CA1CC77AC9C65, 0x2DE92C6F592B0275,
	0x4A7484AA6EA6E483, 0x5CB0A9DCBD41FBD4, 0x76F988DA831153B5,
	0x983E5152EE66DFAB, 0xA831C66D2DB43210, 0xB00327C898FB213F,
	0xBF597FC7BEEF0EE4, 0xC6E00BF33DA88FC2, 0xD5A79147930AA725,
	0x06CA6351E003826F, 0x142929670A0E6E70, 0x27B70A8546D22FFC,
	0x2E1B21385C26C926, 0x4D2C6DFC5AC42AED, 0x53380D139D95B3DF,
	0x650A73548BAF63DE, 0x766A0ABB3C77B2A8, 0x81C2C92E47EDAEE6,
	0x92722C851482353B, 0xA2BFE8A14CF10364, 0xA81A664BBC423001,
	0xC24B8B70D0F89791, 0xC76C51A30654BE30, 0xD192E819D6EF5218,
	0xD69906245565A910, 0xF40E35855771202A, 0x106AA07032BBD1B8,
	0x19A4C116B8D2D0C8, 0x1E376C085141AB53, 0x2748774CDF8EEB99,
	0x34B0BCB5E19B48A8, 0x391C0CB3C5C95A63, 0x4ED8AA4AE3418ACB,
	0x5B9CCA4F7763E373, 0x682E6FF3D6B2B8A3, 0x748F82EE5DEFB2FC,
	0x78A5636F43172F60, 0x84C87814A1F0AB72, 0x8CC702081A6439EC,
	0x90BEFFFA23631E28, 0xA4506CEBDE82BDE9, 0xBEF9A3F7B2C67915,
	0xC67178F2E372532B, 0xCA273ECEEA26619C, 0xD186B8C721C0C207,
	0xEADA7DD6CDE0EB1E, 0xF57D4F7FEE6ED178, 0x06F067AA72176FBA,
	0x0A637DC5A2C898A6, 0x113F9804BEF90DAE, 0x1B710B35131C471B,
	0x28DB77F523047D84, 0x32CAAB7B40C72493, 0x3C9EBE0A15C9BEBC,
	0x431D67C49C100D4C, 0x4CC5D4BECB3E42B6, 0x597F299CFC657E2A,
	0x5FCB6FAB3AD6FAEC, 0x6C44198C4A475817
};

static OF_INLINE void
byteSwapVectorIfLE(uint64_t *vector, uint_fast8_t length)
{
#ifndef OF_BIG_ENDIAN
	for (uint_fast8_t i = 0; i < length; i++)
		vector[i] = OFByteSwap64(vector[i]);
#endif
}

static void
processBlock(uint64_t *state, uint64_t *buffer)
{
	uint64_t new[8];
	uint_fast8_t i;

	new[0] = state[0];
	new[1] = state[1];
	new[2] = state[2];
	new[3] = state[3];
	new[4] = state[4];
	new[5] = state[5];
	new[6] = state[6];
	new[7] = state[7];

	byteSwapVectorIfLE(buffer, 16);

	for (i = 16; i < 80; i++) {
		uint64_t tmp;

		tmp = buffer[i - 2];
		buffer[i] = (OFRotateRight(tmp, 19) ^ OFRotateRight(tmp, 61) ^
		    (tmp >> 6)) + buffer[i - 7];
		tmp = buffer[i - 15];
		buffer[i] += (OFRotateRight(tmp, 1) ^ OFRotateRight(tmp, 8) ^
		    (tmp >> 7)) + buffer[i - 16];
	}

	for (i = 0; i < 80; i++) {
		uint64_t tmp1 = new[7] + (OFRotateRight(new[4], 14) ^
		    OFRotateRight(new[4], 18) ^ OFRotateRight(new[4], 41)) +
		    ((new[4] & (new[5] ^ new[6])) ^ new[6]) +
		    table[i] + buffer[i];
		uint64_t tmp2 = (OFRotateRight(new[0], 28) ^
		    OFRotateRight(new[0], 34) ^ OFRotateRight(new[0], 39)) +
		    ((new[0] & (new[1] | new[2])) | (new[1] & new[2]));

		new[7] = new[6];
		new[6] = new[5];
		new[5] = new[4];
		new[4] = new[3] + tmp1;
		new[3] = new[2];
		new[2] = new[1];
		new[1] = new[0];
		new[0] = tmp1 + tmp2;
	}

	state[0] += new[0];
	state[1] += new[1];
	state[2] += new[2];
	state[3] += new[3];
	state[4] += new[4];
	state[5] += new[5];
	state[6] += new[6];
	state[7] += new[7];
}

@implementation OFSHA384Or512Hash
@synthesize calculated = _calculated;
@synthesize allowsSwappableMemory = _allowsSwappableMemory;

+ (size_t)digestSize
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (size_t)blockSize
{
	return blockSize;
}

+ (instancetype)hashWithAllowsSwappableMemory: (bool)allowsSwappableMemory
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithAllowsSwappableMemory: allowsSwappableMemory]);
}

- (instancetype)initWithAllowsSwappableMemory: (bool)allowsSwappableMemory
{
	self = [super init];

	@try {
		_iVarsData = [[OFSecureData alloc]
			    initWithCount: sizeof(*_iVars)
		    allowsSwappableMemory: allowsSwappableMemory];
		_iVars = _iVarsData.mutableItems;
		_allowsSwappableMemory = allowsSwappableMemory;

		if (self.class == [OFSHA384Or512Hash class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

		[self of_resetState];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (void)dealloc
{
	objc_release(_iVarsData);

	[super dealloc];
}

- (size_t)digestSize
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)blockSize
{
	return blockSize;
}

- (id)copy
{
	OFSHA384Or512Hash *copy = [[[self class] alloc] of_init];

	copy->_iVarsData = [_iVarsData copy];
	copy->_iVars = copy->_iVarsData.mutableItems;
	copy->_allowsSwappableMemory = _allowsSwappableMemory;
	copy->_calculated = _calculated;

	return copy;
}

- (void)updateWithBuffer: (const void *)buffer_ length: (size_t)length
{
	const unsigned char *buffer = buffer_;

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	if (length > SIZE_MAX / 8)
		@throw [OFOutOfRangeException exception];

	if (UINT64_MAX - _iVars->bits[0] < (length * 8))
		_iVars->bits[1]++;
	_iVars->bits[0] += (length * 8);

	while (length > 0) {
		size_t min = 128 - _iVars->bufferLength;

		if (min > length)
			min = length;

		memcpy(_iVars->buffer.bytes + _iVars->bufferLength,
		    buffer, min);
		_iVars->bufferLength += min;

		buffer += min;
		length -= min;

		if (_iVars->bufferLength == 128) {
			processBlock(_iVars->state, _iVars->buffer.words);
			_iVars->bufferLength = 0;
		}
	}
}

- (const unsigned char *)digest
{
	if (!_calculated)
		@throw [OFHashNotCalculatedException exceptionWithObject: self];

	return (const unsigned char *)_iVars->state;
}

- (void)calculate
{
	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	_iVars->buffer.bytes[_iVars->bufferLength] = 0x80;
	OFZeroMemory(_iVars->buffer.bytes + _iVars->bufferLength + 1,
	    128 - _iVars->bufferLength - 1);

	if (_iVars->bufferLength >= 112) {
		processBlock(_iVars->state, _iVars->buffer.words);
		OFZeroMemory(_iVars->buffer.bytes, 128);
	}

	_iVars->buffer.words[14] = OFToBigEndian64(_iVars->bits[1]);
	_iVars->buffer.words[15] = OFToBigEndian64(_iVars->bits[0]);

	processBlock(_iVars->state, _iVars->buffer.words);
	OFZeroMemory(&_iVars->buffer, sizeof(_iVars->buffer));
	byteSwapVectorIfLE(_iVars->state, 8);
	_calculated = true;
}

- (void)reset
{
	[self of_resetState];
	OFZeroMemory(_iVars->bits, sizeof(_iVars->bits));
	OFZeroMemory(&_iVars->buffer, sizeof(_iVars->buffer));
	_iVars->bufferLength = 0;
	_calculated = false;
}

- (void)of_resetState
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
