/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "macros.h"

/* blk0() and blk() perform the initial expand. */
#ifndef OF_BIG_ENDIAN
#define blk0(i)							\
	(block.l[i] = (OF_ROL(block.l[i], 24) & 0xFF00FF00) |	\
	    (OF_ROL(block.l[i], 8) & 0x00FF00FF))
#else
#define blk0(i) block.l[i]
#endif
#define blk(i) \
	(block.l[i & 15] = OF_ROL(block.l[(i + 13) & 15] ^	\
	    block.l[(i + 8) & 15] ^ block.l[(i + 2) & 15] ^	\
	    block.l[i & 15], 1))

/* (R0+R1), R2, R3, R4 are the different operations used in SHA1 */
#define R0(v, w, x, y, z, i)						\
	z += ((w & (x ^ y)) ^ y) + blk0(i) + 0x5A827999 + OF_ROL(v, 5);	\
	w = OF_ROL(w, 30);
#define R1(v, w, x, y, z, i)						\
	z += ((w & (x ^ y)) ^ y) + blk(i) +  0x5A827999 + OF_ROL(v, 5);	\
	w = OF_ROL(w, 30);
#define R2(v, w, x, y, z, i)						\
	z += (w ^ x ^ y) + blk(i) + 0x6ED9EBA1 + OF_ROL(v, 5);		\
	w = OF_ROL(w, 30);
#define R3(v, w, x, y, z, i)						     \
	z += (((w | x) & y) | (w & x)) + blk(i) + 0x8F1BBCDC + OF_ROL(v, 5); \
	w = OF_ROL(w, 30);
#define R4(v, w, x, y, z, i)						\
	z += (w ^ x ^ y) + blk(i) + 0xCA62C1D6 + OF_ROL(v, 5);		\
	w = OF_ROL(w, 30);

typedef union {
	char	 c[64];
	uint32_t l[16];
} sha1_c64l16_t;

static inline void
sha1_transform(uint32_t state[5], const char buffer[64])
{
	uint32_t      a, b, c, d, e;
	sha1_c64l16_t block;

	memcpy(block.c, buffer, 64);

	/* Copy state[] to working vars */
	a = state[0];
	b = state[1];
	c = state[2];
	d = state[3];
	e = state[4];

	/* 4 rounds of 20 operations each. Loop unrolled. */
	R0(a,b,c,d,e, 0); R0(e,a,b,c,d, 1); R0(d,e,a,b,c, 2); R0(c,d,e,a,b, 3);
	R0(b,c,d,e,a, 4); R0(a,b,c,d,e, 5); R0(e,a,b,c,d, 6); R0(d,e,a,b,c, 7);
	R0(c,d,e,a,b, 8); R0(b,c,d,e,a, 9); R0(a,b,c,d,e,10); R0(e,a,b,c,d,11);
	R0(d,e,a,b,c,12); R0(c,d,e,a,b,13); R0(b,c,d,e,a,14); R0(a,b,c,d,e,15);
	R1(e,a,b,c,d,16); R1(d,e,a,b,c,17); R1(c,d,e,a,b,18); R1(b,c,d,e,a,19);
	R2(a,b,c,d,e,20); R2(e,a,b,c,d,21); R2(d,e,a,b,c,22); R2(c,d,e,a,b,23);
	R2(b,c,d,e,a,24); R2(a,b,c,d,e,25); R2(e,a,b,c,d,26); R2(d,e,a,b,c,27);
	R2(c,d,e,a,b,28); R2(b,c,d,e,a,29); R2(a,b,c,d,e,30); R2(e,a,b,c,d,31);
	R2(d,e,a,b,c,32); R2(c,d,e,a,b,33); R2(b,c,d,e,a,34); R2(a,b,c,d,e,35);
	R2(e,a,b,c,d,36); R2(d,e,a,b,c,37); R2(c,d,e,a,b,38); R2(b,c,d,e,a,39);
	R3(a,b,c,d,e,40); R3(e,a,b,c,d,41); R3(d,e,a,b,c,42); R3(c,d,e,a,b,43);
	R3(b,c,d,e,a,44); R3(a,b,c,d,e,45); R3(e,a,b,c,d,46); R3(d,e,a,b,c,47);
	R3(c,d,e,a,b,48); R3(b,c,d,e,a,49); R3(a,b,c,d,e,50); R3(e,a,b,c,d,51);
	R3(d,e,a,b,c,52); R3(c,d,e,a,b,53); R3(b,c,d,e,a,54); R3(a,b,c,d,e,55);
	R3(e,a,b,c,d,56); R3(d,e,a,b,c,57); R3(c,d,e,a,b,58); R3(b,c,d,e,a,59);
	R4(a,b,c,d,e,60); R4(e,a,b,c,d,61); R4(d,e,a,b,c,62); R4(c,d,e,a,b,63);
	R4(b,c,d,e,a,64); R4(a,b,c,d,e,65); R4(e,a,b,c,d,66); R4(d,e,a,b,c,67);
	R4(c,d,e,a,b,68); R4(b,c,d,e,a,69); R4(a,b,c,d,e,70); R4(e,a,b,c,d,71);
	R4(d,e,a,b,c,72); R4(c,d,e,a,b,73); R4(b,c,d,e,a,74); R4(a,b,c,d,e,75);
	R4(e,a,b,c,d,76); R4(d,e,a,b,c,77); R4(c,d,e,a,b,78); R4(b,c,d,e,a,79);

	/* Add the working vars back into state[] */
	state[0] += a;
	state[1] += b;
	state[2] += c;
	state[3] += d;
	state[4] += e;
}

static inline void
sha1_update(uint32_t *state, uint64_t *count, char *buffer,
    const char *buf, size_t length)
{
	size_t i, j;

	j = (size_t)((*count >> 3) & 63);
	*count += (length << 3);

	if ((j + length) > 63) {
		memcpy(&buffer[j], buf, (i = 64 - j));

		sha1_transform(state, buffer);

		for (; i + 63 < length; i += 64)
			sha1_transform(state, &buf[i]);

		j = 0;
	} else
		i = 0;

	memcpy(&buffer[j], &buf[i], length - i);
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

- (void)updateWithBuffer: (const void*)buffer
		  length: (size_t)length
{
	if (length == 0)
		return;

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithClass: [self class]
				  hash: self];

	sha1_update(_state, &_count, _buffer, buffer, length);
}

- (uint8_t*)digest
{
	size_t i;
	char finalcount[8];

	if (_calculated)
		return _digest;

	for (i = 0; i < 8; i++)
		/* Endian independent */
		finalcount[i] = (char)((_count >> ((7 - (i & 7)) * 8)) & 255);
	sha1_update(_state, &_count, _buffer, "\200", 1);

	while ((_count & 504) != 448)
		sha1_update(_state, &_count, _buffer, "\0", 1);
	/* Should cause a sha1_transform() */
	sha1_update(_state, &_count, _buffer, finalcount, 8);

	for (i = 0; i < OF_SHA1_DIGEST_SIZE; i++)
		_digest[i] = (char)((_state[i >> 2] >>
		    ((3 - (i & 3)) * 8)) & 255);

	_calculated = YES;

	return _digest;
}
@end
