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

#import "OFSHA1Hash.h"

#import "OFHashAlreadyCalculatedException.h"

#define F(a, b, c, d) ((d) ^ ((b) & ((c) ^ (d))))
#define G(a, b, c, d) ((b) ^ (c) ^ (d))
#define H(a, b, c, d) (((b) & (c)) | ((d) & ((b) | (c))))
#define I(a, b, c, d) ((b) ^ (c) ^ (d))

static void
byteSwapVectorIfLE(uint32_t *vector, uint_fast8_t length)
{
	uint_fast8_t i;

	for (i = 0; i < length; i++)
		vector[i] = OF_BSWAP32_IF_LE(vector[i]);
}

static void
processBlock(uint32_t *state, uint32_t *buffer)
{
	uint32_t new[5];
	uint_fast8_t i;

	new[0] = state[0];
	new[1] = state[1];
	new[2] = state[2];
	new[3] = state[3];
	new[4] = state[4];

	byteSwapVectorIfLE(buffer, 16);

	for (i = 16; i < 80; i++) {
		uint32_t tmp = buffer[i - 3] ^ buffer[i - 8] ^
		    buffer[i - 14] ^ buffer[i - 16];
		buffer[i] = OF_ROL(tmp, 1);
	}

#define LOOP_BODY(f, k)							\
	{								\
		uint32_t tmp = OF_ROL(new[0], 5) +			\
		    f(new[0], new[1], new[2], new[3]) +			\
		    new[4] + k + buffer[i];				\
		new[4] = new[3];					\
		new[3] = new[2];					\
		new[2] = OF_ROL(new[1], 30);				\
		new[1] = new[0];					\
		new[0] = tmp;						\
	}

	for (i = 0; i < 20; i++)
		LOOP_BODY(F, 0x5A827999)
	for (; i < 40; i++)
		LOOP_BODY(G, 0x6ED9EBA1)
	for (; i < 60; i++)
		LOOP_BODY(H, 0x8F1BBCDC)
	for (; i < 80; i++)
		LOOP_BODY(I, 0xCA62C1D6)

#undef LOOP_BODY

	state[0] += new[0];
	state[1] += new[1];
	state[2] += new[2];
	state[3] += new[3];
	state[4] += new[4];
}

@implementation OFSHA1Hash
+ (size_t)digestSize
{
	return 20;
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
	_state[4] = 0xC3D2E1F0;

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

	_buffer.words[14] = OF_BSWAP32_IF_LE((uint32_t)(_bits >> 32));
	_buffer.words[15] = OF_BSWAP32_IF_LE((uint32_t)(_bits & 0xFFFFFFFF));

	processBlock(_state, _buffer.words);
	byteSwapVectorIfLE(_state, 5);
	_calculated = true;

	return (const uint8_t*)_state;
}

- (bool)isCalculated
{
	return _calculated;
}
@end
