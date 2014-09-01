/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <string.h>

#import "OFMD5Hash.h"

#import "OFHashAlreadyCalculatedException.h"

#define F(a, b, c) (((a) & (b)) | (~(a) & (c)))
#define G(a, b, c) (((a) & (c)) | ((b) & ~(c)))
#define H(a, b, c) ((a) ^ (b) ^ (c))
#define I(a, b, c) ((b) ^ ((a) | ~(c)))

static const uint32_t table[] = {
	0xD76AA478, 0xE8C7B756, 0x242070DB, 0xC1BDCEEE,
	0xF57C0FAF, 0x4787C62A, 0xA8304613, 0xFD469501,
	0x698098D8, 0x8B44F7AF, 0xFFFF5BB1, 0x895CD7BE,
	0x6B901122, 0xFD987193, 0xA679438E, 0x49B40821,

	0xF61E2562, 0xC040B340, 0x265E5A51, 0xE9B6C7AA,
	0xD62F105D, 0x02441453, 0xD8A1E681, 0xE7D3FBC8,
	0x21E1CDE6, 0xC33707D6, 0xF4D50D87, 0x455A14ED,
	0xA9E3E905, 0xFCEFA3F8, 0x676F02D9, 0x8D2A4C8A,

	0xFFFA3942, 0x8771F681, 0x6D9D6122, 0xFDE5380C,
	0xA4BEEA44, 0x4BDECFA9, 0xF6BB4B60, 0xBEBFBC70,
	0x289B7EC6, 0xEAA127FA, 0xD4EF3085, 0x04881D05,
	0xD9D4D039, 0xE6DB99E5, 0x1FA27CF8, 0xC4AC5665,

	0xF4292244, 0x432AFF97, 0xAB9423A7, 0xFC93A039,
	0x655B59C3, 0x8F0CCC92, 0xFFEFF47D, 0x85845DD1,
	0x6FA87E4F, 0xFE2CE6E0, 0xA3014314, 0x4E0811A1,
	0xF7537E82, 0xBD3AF235, 0x2AD7D2BB, 0xEB86D391
};
static const uint8_t wordOrder[] = {
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
	1, 6, 11, 0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12,
	5, 8, 11, 14, 1, 4, 7, 10, 13, 0, 3, 6, 9, 12, 15, 2,
	0, 7, 14, 5, 12, 3, 10, 1, 8, 15, 6, 13, 4, 11, 2, 9
};
static const uint8_t rotateBits[] = {
	7, 12, 17, 22,
	5, 9, 14, 20,
	4, 11, 16, 23,
	6, 10, 15, 21
};

static void
byteSwapVectorIfBE(uint32_t *vector, uint_fast8_t length)
{
	uint_fast8_t i;

	for (i = 0; i < length; i++)
		vector[i] = OF_BSWAP32_IF_BE(vector[i]);
}

static void
processBlock(uint32_t *state, uint32_t *buffer)
{
	uint32_t new[4];
	uint_fast8_t i = 0;

	new[0] = state[0];
	new[1] = state[1];
	new[2] = state[2];
	new[3] = state[3];

	byteSwapVectorIfBE(buffer, 16);

#define LOOP_BODY(f)							   \
	{								   \
		const uint_fast8_t a = (4 - (i & 3)) & 3;		   \
		const uint_fast8_t b = (a + 1) & 3;			   \
		const uint_fast8_t c = (a + 2) & 3;			   \
		const uint_fast8_t d = (a + 3) & 3;			   \
		const uint_fast8_t r = rotateBits[(i % 4) + (i / 16) * 4]; \
									   \
		new[a] += f(new[b], new[c], new[d]) +			   \
		    buffer[wordOrder[i]] + table[i];			   \
		new[a] = OF_ROL(new[a], r);				   \
		new[a] += new[b];					   \
	}

	for (; i < 16; i++)
		LOOP_BODY(F)
	for (; i < 32; i++)
		LOOP_BODY(G)
	for (; i < 48; i++)
		LOOP_BODY(H)
	for (; i < 64; i++)
		LOOP_BODY(I)

#undef LOOP_BODY

	state[0] += new[0];
	state[1] += new[1];
	state[2] += new[2];
	state[3] += new[3];
}

@implementation OFMD5Hash
+ (size_t)digestSize
{
	return 16;
}

+ (size_t)blockSize
{
	return 64;
}

+ (instancetype)hash
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	_state[0] = 0x67452301;
	_state[1] = 0xEFCDAB89;
	_state[2] = 0x98BADCFE;
	_state[3] = 0x10325476;

	return self;
}

- (void)updateWithBuffer: (const void*)buffer_
		  length: (size_t)length
{
	const uint8_t *buffer = buffer_;

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithHash: self];

	_bits += (length * 8);

	while (length > 0) {
		size_t min = 64 - _bufferLength;

		if (min > length)
			min = length;

		memcpy(_buffer.bytes + _bufferLength, buffer, min);
		_bufferLength += min;

		buffer += min;
		length -= min;

		if (_bufferLength == 64) {
			processBlock(_state, _buffer.words);
			_bufferLength = 0;
		}
	}
}

- (const uint8_t*)digest
{
	if (_calculated)
		return (const uint8_t*)_state;

	_buffer.bytes[_bufferLength] = 0x80;
	memset(_buffer.bytes + _bufferLength + 1, 0, 64 - _bufferLength - 1);

	if (_bufferLength >= 56) {
		processBlock(_state, _buffer.words);
		memset(_buffer.bytes, 0, 64);
	}

	_buffer.words[14] = OF_BSWAP32_IF_BE((uint32_t)(_bits & 0xFFFFFFFF));
	_buffer.words[15] = OF_BSWAP32_IF_BE((uint32_t)(_bits >> 32));

	processBlock(_state, _buffer.words);
	memset(&_buffer, 0, sizeof(_buffer));
	byteSwapVectorIfBE(_state, 4);
	_calculated = true;

	return (const uint8_t*)_state;
}

- (bool)isCalculated
{
	return _calculated;
}
@end
