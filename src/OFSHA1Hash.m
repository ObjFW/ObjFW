/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include <string.h>

#import "OFSHA1Hash.h"
#import "OFSecureData.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFOutOfRangeException.h"

@interface OFSHA1Hash ()
- (void)of_resetState;
@end

#define F(a, b, c, d) ((d) ^ ((b) & ((c) ^ (d))))
#define G(a, b, c, d) ((b) ^ (c) ^ (d))
#define H(a, b, c, d) (((b) & (c)) | ((d) & ((b) | (c))))
#define I(a, b, c, d) ((b) ^ (c) ^ (d))

static OF_INLINE void
byteSwapVectorIfLE(uint32_t *vector, uint_fast8_t length)
{
#ifndef OF_BIG_ENDIAN
	for (uint_fast8_t i = 0; i < length; i++)
		vector[i] = OF_BSWAP32(vector[i]);
#endif
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
@synthesize calculated = _calculated;

+ (size_t)digestSize
{
	return 20;
}

+ (size_t)blockSize
{
	return 64;
}

+ (instancetype)cryptoHash
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		_iVarsData = [[OFSecureData alloc]
		    initWithCount: sizeof(*_iVars)];
		_iVars = _iVarsData.mutableItems;

		[self of_resetState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)of_init
{
	return [super init];
}

- (void)dealloc
{
	[_iVarsData release];

	[super dealloc];
}

- (id)copy
{
	OFSHA1Hash *copy = [[OFSHA1Hash alloc] of_init];

	copy->_iVarsData = [_iVarsData copy];
	copy->_iVars = copy->_iVarsData.mutableItems;
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

- (void)updateWithBuffer: (const void *)buffer_
		  length: (size_t)length
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
	if (_calculated)
		return (const unsigned char *)_iVars->state;

	_iVars->buffer.bytes[_iVars->bufferLength] = 0x80;
	of_explicit_memset(_iVars->buffer.bytes + _iVars->bufferLength + 1, 0,
	    64 - _iVars->bufferLength - 1);

	if (_iVars->bufferLength >= 56) {
		processBlock(_iVars->state, _iVars->buffer.words);
		of_explicit_memset(_iVars->buffer.bytes, 0, 64);
	}

	_iVars->buffer.words[14] =
	    OF_BSWAP32_IF_LE((uint32_t)(_iVars->bits >> 32));
	_iVars->buffer.words[15] =
	    OF_BSWAP32_IF_LE((uint32_t)(_iVars->bits & 0xFFFFFFFF));

	processBlock(_iVars->state, _iVars->buffer.words);
	of_explicit_memset(&_iVars->buffer, 0, sizeof(_iVars->buffer));
	byteSwapVectorIfLE(_iVars->state, 5);
	_calculated = true;

	return (const unsigned char *)_iVars->state;
}

- (void)reset
{
	[self of_resetState];
	_iVars->bits = 0;
	of_explicit_memset(&_iVars->buffer, 0, sizeof(_iVars->buffer));
	_iVars->bufferLength = 0;
	_calculated = false;
}
@end
