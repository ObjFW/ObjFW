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

#include <stdlib.h>
#include <string.h>

#import "OFSHA224Or256Hash.h"
#import "OFSecureData.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFOutOfRangeException.h"

@interface OFSHA224Or256Hash ()
- (void)of_resetState;
@end

static const uint32_t table[] = {
	0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5,
	0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
	0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3,
	0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
	0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC,
	0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
	0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7,
	0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
	0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13,
	0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
	0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3,
	0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
	0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5,
	0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
	0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208,
	0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2
};

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
	uint32_t new[8];
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

	for (i = 16; i < 64; i++) {
		uint32_t tmp;

		tmp = buffer[i - 2];
		buffer[i] = (OF_ROR(tmp, 17) ^ OF_ROR(tmp, 19) ^ (tmp >> 10)) +
		    buffer[i - 7];
		tmp = buffer[i - 15];
		buffer[i] += (OF_ROR(tmp, 7) ^ OF_ROR(tmp, 18) ^ (tmp >> 3)) +
		    buffer[i - 16];
	}

	for (i = 0; i < 64; i++) {
		uint32_t tmp1 = new[7] + (OF_ROR(new[4], 6) ^
		    OF_ROR(new[4], 11) ^ OF_ROR(new[4], 25)) +
		    ((new[4] & (new[5] ^ new[6])) ^ new[6]) +
		    table[i] + buffer[i];
		uint32_t tmp2 = (OF_ROR(new[0], 2) ^ OF_ROR(new[0], 13) ^
		    OF_ROR(new[0], 22)) +
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

@implementation OFSHA224Or256Hash
@synthesize calculated = _calculated;

+ (size_t)digestSize
{
	OF_UNRECOGNIZED_SELECTOR
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

		if (self.class == [OFSHA224Or256Hash class]) {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		}

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
	OFSHA224Or256Hash *copy = [[[self class] alloc] of_init];

	copy->_iVarsData = [_iVarsData copy];
	copy->_iVars = copy->_iVarsData.mutableItems;
	copy->_calculated = _calculated;

	return copy;
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
	byteSwapVectorIfLE(_iVars->state, 8);
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

- (void)of_resetState
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
