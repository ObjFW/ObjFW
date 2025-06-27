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

#include <string.h>

#import "OFRIPEMD160Hash.h"
#import "OFSecureData.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFHashNotCalculatedException.h"
#import "OFOutOfRangeException.h"

static const size_t digestSize = 20;
static const size_t blockSize = 64;

OF_DIRECT_MEMBERS
@interface OFRIPEMD160Hash ()
- (void)of_resetState;
@end

#define F(a, b, c) ((a) ^ (b) ^ (c))
#define G(a, b, c) (((a) & (b)) | (~(a) & (c)))
#define H(a, b, c) (((a) | ~(b)) ^ (c))
#define I(a, b, c) (((a) & (c)) | ((b) & ~(c)))
#define J(a, b, c) ((a) ^ ((b) | ~(c)))

static const uint8_t wordOrder[] = {
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
	7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8,
	3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12,
	1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2,
	4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13
};
static const uint8_t wordOrder2[] = {
	5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12,
	6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2,
	15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13,
	8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14,
	12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11
};
static const uint8_t rotateBits[] = {
	11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8,
	7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12,
	11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5,
	11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12,
	9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6
};
static const uint8_t rotateBits2[] = {
	8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6,
	9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
	9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5,
	15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
	8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11
};

static OF_INLINE void
byteSwapVectorIfBE(uint32_t *vector, uint_fast8_t length)
{
#ifdef OF_BIG_ENDIAN
	for (uint_fast8_t i = 0; i < length; i++)
		vector[i] = OFByteSwap32(vector[i]);
#endif
}

static void
processBlock(uint32_t *state, uint32_t *buffer)
{
	uint32_t new[5], new2[5];
	uint_fast8_t i = 0;

	new[0] = new2[0] = state[0];
	new[1] = new2[1] = state[1];
	new[2] = new2[2] = state[2];
	new[3] = new2[3] = state[3];
	new[4] = new2[4] = state[4];

	byteSwapVectorIfBE(buffer, 16);

#define LOOP_BODY(f, g, k, k2)						\
	{								\
		uint32_t tmp;						\
									\
		tmp = new[0] + f(new[1], new[2], new[3]) +		\
		    buffer[wordOrder[i]] + k;				\
		tmp = OFRotateLeft(tmp, rotateBits[i]) + new[4];	\
									\
		new[0] = new[4];					\
		new[4] = new[3];					\
		new[3] = OFRotateLeft(new[2], 10);			\
		new[2] = new[1];					\
		new[1] = tmp;						\
									\
		tmp = new2[0] + g(new2[1], new2[2], new2[3]) +		\
		    buffer[wordOrder2[i]] + k2;				\
		tmp = OFRotateLeft(tmp, rotateBits2[i]) + new2[4];	\
									\
		new2[0] = new2[4];					\
		new2[4] = new2[3];					\
		new2[3] = OFRotateLeft(new2[2], 10);			\
		new2[2] = new2[1];					\
		new2[1] = tmp;						\
	}

	for (; i < 16; i++)
		LOOP_BODY(F, J, 0x00000000, 0x50A28BE6)
	for (; i < 32; i++)
		LOOP_BODY(G, I, 0x5A827999, 0x5C4DD124)
	for (; i < 48; i++)
		LOOP_BODY(H, H, 0x6ED9EBA1, 0x6D703EF3)
	for (; i < 64; i++)
		LOOP_BODY(I, G, 0x8F1BBCDC, 0x7A6D76E9)
	for (; i < 80; i++)
		LOOP_BODY(J, F, 0xA953FD4E, 0x00000000)

#undef LOOP_BODY

	new2[3] += state[1] + new[2];
	state[1] = state[2] + new[3] + new2[4];
	state[2] = state[3] + new[4] + new2[0];
	state[3] = state[4] + new[0] + new2[1];
	state[4] = state[0] + new[1] + new2[2];
	state[0] = new2[3];
}

@implementation OFRIPEMD160Hash
@synthesize calculated = _calculated;
@synthesize allowsSwappableMemory = _allowsSwappableMemory;

+ (size_t)digestSize
{
	return digestSize;
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
	return digestSize;
}

- (size_t)blockSize
{
	return blockSize;
}

- (id)copy
{
	OFRIPEMD160Hash *copy = [[OFRIPEMD160Hash alloc] of_init];

	copy->_iVarsData = [_iVarsData copy];
	copy->_iVars = copy->_iVarsData.mutableItems;
	copy->_allowsSwappableMemory = _allowsSwappableMemory;
	copy->_calculated = _calculated;

	return copy;
}

- (void)of_resetState
{
	_iVars->state[0] = 0x67452301;
	_iVars->state[1] = 0xEFCDAB89;
	_iVars->state[2] = 0x98BADCFE;
	_iVars->state[3] = 0x10325476;
	_iVars->state[4] = 0xC3D2E1F0;
}

- (void)updateWithBuffer: (const void *)buffer_ length: (size_t)length
{
	const unsigned char *buffer = buffer_;

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	if (length > SIZE_MAX / 8)
		@throw [OFOutOfRangeException exception];

	_iVars->bits += (length * 8);

	while (length > 0) {
		size_t min = 64 - _iVars->bufferLength;

		if (min > length)
			min = length;

		memcpy(_iVars->buffer.bytes + _iVars->bufferLength,
		    buffer, min);
		_iVars->bufferLength += min;

		buffer += min;
		length -= min;

		if (_iVars->bufferLength == 64) {
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
	    64 - _iVars->bufferLength - 1);

	if (_iVars->bufferLength >= 56) {
		processBlock(_iVars->state, _iVars->buffer.words);
		OFZeroMemory(_iVars->buffer.bytes, 64);
	}

	_iVars->buffer.words[14] =
	    OFToLittleEndian32((uint32_t)(_iVars->bits & 0xFFFFFFFF));
	_iVars->buffer.words[15] =
	    OFToLittleEndian32((uint32_t)(_iVars->bits >> 32));

	processBlock(_iVars->state, _iVars->buffer.words);
	OFZeroMemory(&_iVars->buffer, sizeof(_iVars->buffer));
	byteSwapVectorIfBE(_iVars->state, 5);
	_calculated = true;
}

- (void)reset
{
	[self of_resetState];
	_iVars->bits = 0;
	OFZeroMemory(&_iVars->buffer, sizeof(_iVars->buffer));
	_iVars->bufferLength = 0;
	_calculated = false;
}
@end
