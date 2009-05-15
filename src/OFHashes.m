/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <string.h>

#import "OFHashes.h"
#import "OFMacros.h"

/*******
 * MD5 *
 *******/

/* The four MD5 core functions - F1 is optimized somewhat */
#define F1(x, y, z) (z ^ (x & (y ^ z)))
#define F2(x, y, z) F1(z, x, y)
#define F3(x, y, z) (x ^ y ^ z)
#define F4(x, y, z) (y ^ (x | ~z))

/* This is the central step in the MD5 algorithm. */
#define MD5STEP(f, w, x, y, z, data, s) \
	(w += f(x, y, z) + data, w = w << s | w >> (32 - s), w += x)

static inline void
md5_transform(uint32_t buf[4], const uint32_t in[16])
{
	register uint32_t a, b, c, d;

	a = buf[0];
	b = buf[1];
	c = buf[2];
	d = buf[3];

	MD5STEP(F1, a, b, c, d, in[0]  + 0xD76AA478, 7);
	MD5STEP(F1, d, a, b, c, in[1]  + 0xE8C7B756, 12);
	MD5STEP(F1, c, d, a, b, in[2]  + 0x242070DB, 17);
	MD5STEP(F1, b, c, d, a, in[3]  + 0xC1BDCEEE, 22);
	MD5STEP(F1, a, b, c, d, in[4]  + 0xF57C0FAF, 7);
	MD5STEP(F1, d, a, b, c, in[5]  + 0x4787C62A, 12);
	MD5STEP(F1, c, d, a, b, in[6]  + 0xA8304613, 17);
	MD5STEP(F1, b, c, d, a, in[7]  + 0xFD469501, 22);
	MD5STEP(F1, a, b, c, d, in[8]  + 0x698098D8, 7);
	MD5STEP(F1, d, a, b, c, in[9]  + 0x8B44F7AF, 12);
	MD5STEP(F1, c, d, a, b, in[10] + 0xFFFF5BB1, 17);
	MD5STEP(F1, b, c, d, a, in[11] + 0x895CD7Be, 22);
	MD5STEP(F1, a, b, c, d, in[12] + 0x6B901122, 7);
	MD5STEP(F1, d, a, b, c, in[13] + 0xFD987193, 12);
	MD5STEP(F1, c, d, a, b, in[14] + 0xA679438e, 17);
	MD5STEP(F1, b, c, d, a, in[15] + 0x49B40821, 22);

	MD5STEP(F2, a, b, c, d, in[1]  + 0xF61E2562, 5);
	MD5STEP(F2, d, a, b, c, in[6]  + 0xC040B340, 9);
	MD5STEP(F2, c, d, a, b, in[11] + 0x265E5A51, 14);
	MD5STEP(F2, b, c, d, a, in[0]  + 0xE9B6C7AA, 20);
	MD5STEP(F2, a, b, c, d, in[5]  + 0xD62F105D, 5);
	MD5STEP(F2, d, a, b, c, in[10] + 0x02441453, 9);
	MD5STEP(F2, c, d, a, b, in[15] + 0xD8A1E681, 14);
	MD5STEP(F2, b, c, d, a, in[4]  + 0xE7D3FBC8, 20);
	MD5STEP(F2, a, b, c, d, in[9]  + 0x21E1CDE6, 5);
	MD5STEP(F2, d, a, b, c, in[14] + 0xC33707D6, 9);
	MD5STEP(F2, c, d, a, b, in[3]  + 0xF4D50D87, 14);
	MD5STEP(F2, b, c, d, a, in[8]  + 0x455A14ED, 20);
	MD5STEP(F2, a, b, c, d, in[13] + 0xA9E3E905, 5);
	MD5STEP(F2, d, a, b, c, in[2]  + 0xFCEFA3F8, 9);
	MD5STEP(F2, c, d, a, b, in[7]  + 0x676F02D9, 14);
	MD5STEP(F2, b, c, d, a, in[12] + 0x8D2A4C8a, 20);

	MD5STEP(F3, a, b, c, d, in[5]  + 0xFFFA3942, 4);
	MD5STEP(F3, d, a, b, c, in[8]  + 0x8771F681, 11);
	MD5STEP(F3, c, d, a, b, in[11] + 0x6D9D6122, 16);
	MD5STEP(F3, b, c, d, a, in[14] + 0xFDE5380c, 23);
	MD5STEP(F3, a, b, c, d, in[1]  + 0xA4BEEA44, 4);
	MD5STEP(F3, d, a, b, c, in[4]  + 0x4BDECFA9, 11);
	MD5STEP(F3, c, d, a, b, in[7]  + 0xF6BB4B60, 16);
	MD5STEP(F3, b, c, d, a, in[10] + 0xBEBFBC70, 23);
	MD5STEP(F3, a, b, c, d, in[13] + 0x289B7EC6, 4);
	MD5STEP(F3, d, a, b, c, in[0]  + 0xEAA127FA, 11);
	MD5STEP(F3, c, d, a, b, in[3]  + 0xD4EF3085, 16);
	MD5STEP(F3, b, c, d, a, in[6]  + 0x04881D05, 23);
	MD5STEP(F3, a, b, c, d, in[9]  + 0xD9D4D039, 4);
	MD5STEP(F3, d, a, b, c, in[12] + 0xE6DB99E5, 11);
	MD5STEP(F3, c, d, a, b, in[15] + 0x1FA27CF8, 16);
	MD5STEP(F3, b, c, d, a, in[2]  + 0xC4AC5665, 23);

	MD5STEP(F4, a, b, c, d, in[0]  + 0xF4292244, 6);
	MD5STEP(F4, d, a, b, c, in[7]  + 0x432AFF97, 10);
	MD5STEP(F4, c, d, a, b, in[14] + 0xAB9423A7, 15);
	MD5STEP(F4, b, c, d, a, in[5]  + 0xFC93A039, 21);
	MD5STEP(F4, a, b, c, d, in[12] + 0x655B59C3, 6);
	MD5STEP(F4, d, a, b, c, in[3]  + 0x8F0CCC92, 10);
	MD5STEP(F4, c, d, a, b, in[10] + 0xFFEFF47d, 15);
	MD5STEP(F4, b, c, d, a, in[1]  + 0x85845DD1, 21);
	MD5STEP(F4, a, b, c, d, in[8]  + 0x6FA87E4F, 6);
	MD5STEP(F4, d, a, b, c, in[15] + 0xFE2CE6E0, 10);
	MD5STEP(F4, c, d, a, b, in[6]  + 0xA3014314, 15);
	MD5STEP(F4, b, c, d, a, in[13] + 0x4E0811A1, 21);
	MD5STEP(F4, a, b, c, d, in[4]  + 0xF7537E82, 6);
	MD5STEP(F4, d, a, b, c, in[11] + 0xBD3AF235, 10);
	MD5STEP(F4, c, d, a, b, in[2]  + 0x2AD7D2BB, 15);
	MD5STEP(F4, b, c, d, a, in[9]  + 0xEB86D391, 21);

	buf[0] += a;
	buf[1] += b;
	buf[2] += c;
	buf[3] += d;
}

@implementation OFMD5Hash
+ md5Hash
{
	return [[[OFMD5Hash alloc] init] autorelease];
}

- init
{
	self = [super init];

	buf[0] = 0x67452301;
	buf[1] = 0xEFCDAB89;
	buf[2] = 0x98BADCFE;
	buf[3] = 0x10325476;

	return self;
}

- updateWithBuffer: (const char*)buffer
	    ofSize: (size_t)size
{
	uint32_t t;

	if (calculated)
		return self;
	if (size == 0)
		return self;

	/* Update bitcount */
	t = bits[0];
	if ((bits[0] = t + ((uint32_t)size << 3)) < t)
		/* Carry from low to high */
		bits[1]++;
	bits[1] += size >> 29;

	/* Bytes already in shsInfo->data */
	t = (t >> 3) & 0x3F;

	/* Handle any leading odd-sized chunks */
	if (t) {
		uint8_t *p = in + t;

		t = 64 - t;

		if (size < t) {
			memcpy(p, buffer, size);
			return self;
		}

		memcpy(p, buffer, t);
		OF_BSWAP_V(in, 16);
		md5_transform(buf, (uint32_t*)in);

		buffer += t;
		size -= t;
	}

	/* Process data in 64-byte chunks */
	while (size >= 64) {
		memcpy(in, buffer, 64);
		OF_BSWAP_V(in, 16);
		md5_transform(buf, (uint32_t*)in);

		buffer += 64;
		size -= 64;
	}

	/* Handle any remaining bytes of data. */
	memcpy(in, buffer, size);

	return self;
}

- (char*)digest
{
	uint8_t	*p;
	size_t	count;

	if (calculated)
		return (char*)buf;

	/* Compute number of bytes mod 64 */
	count = (bits[0] >> 3) & 0x3F;

	/*
	 * Set the first char of padding to 0x80. This is safe since there is
	 * always at least one byte free
	 */
	p = in + count;
	*p++ = 0x80;

	/* Bytes of padding needed to make 64 bytes */
	count = 64 - 1 - count;

	/* Pad out to 56 mod 64 */
	if (count < 8) {
		/* Two lots of padding: Pad the first block to 64 bytes */
		memset(p, 0, count);
		OF_BSWAP_V(in, 16);
		md5_transform(buf, (uint32_t*)in);

		/* Now fill the next block with 56 bytes */
		memset(in, 0, 56);
	} else {
		/* Pad block to 56 bytes */
		memset(p, 0, count - 8);
	}
	OF_BSWAP_V(in, 14);

	/* Append length in bits and transform */
	((uint32_t*)in)[14] = bits[0];
	((uint32_t*)in)[15] = bits[1];

	md5_transform(buf, (uint32_t*)in);
	OF_BSWAP_V((uint8_t*)buf, 4);

	calculated = YES;

	return (char*)buf;
}
@end

#undef F1
#undef F2
#undef F3
#undef F4
#undef MD5STEP

/********
 * SHA1 *
 ********/

/* blk0() and blk() perform the initial expand. */
#ifndef OF_BIG_ENDIAN
#define blk0(i)							\
	(block->l[i] = (OF_ROL(block->l[i], 24) & 0xFF00FF00) |	\
	    (OF_ROL(block->l[i], 8) & 0x00FF00FF))
#else
#define blk0(i) block->l[i]
#endif
#define blk(i) \
	(block->l[i & 15] = OF_ROL(block->l[(i + 13) & 15] ^	\
	    block->l[(i + 8) & 15] ^ block->l[(i + 2) & 15] ^	\
	    block->l[i & 15], 1))

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
	char	      workspace[64];
	sha1_c64l16_t *block;

	block = (sha1_c64l16_t*)workspace;
	memcpy(block, buffer, 64);

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
    const char *buf, size_t size)
{
	size_t i, j;

	j = (size_t)((*count >> 3) & 63);
	*count += (size << 3);

	if ((j + size) > 63) {
		memcpy(&buffer[j], buf, (i = 64 - j));

		sha1_transform(state, buffer);

		for (; i + 63 < size; i += 64)
			sha1_transform(state, &buf[i]);

		j = 0;
	} else
		i = 0;

	memcpy(&buffer[j], &buf[i], size - i);
}

@implementation OFSHA1Hash
+ sha1Hash
{
	return [[[OFSHA1Hash alloc] init] autorelease];
}

- init
{
	self = [super init];

	state[0] = 0x67452301;
	state[1] = 0xEFCDAB89;
	state[2] = 0x98BADCFE;
	state[3] = 0x10325476;
	state[4] = 0xC3D2E1F0;

	return self;
}

- updateWithBuffer: (const char*)buf
	    ofSize: (size_t)size
{
	if (calculated)
		return self;
	if (size == 0)
		return self;

	sha1_update(state, &count, buffer, buf, size);

	return self;
}

- (char*)digest
{
	size_t i;
	char   finalcount[8];

	if (calculated)
		return digest;

	for (i = 0; i < 8; i++)
		/* Endian independent */
		finalcount[i] = (char)((count >> ((7 - (i & 7)) * 8)) & 255);
	sha1_update(state, &count, buffer, "\200", 1);

	while ((count & 504) != 448)
		sha1_update(state, &count, buffer, "\0", 1);
	/* Should cause a sha1_transform() */
	sha1_update(state, &count, buffer, finalcount, 8);

	for (i = 0; i < SHA1_DIGEST_SIZE; i++)
		digest[i] = (char)((state[i >> 2] >>
		    ((3 - (i & 3)) * 8)) & 255);

	return digest;
}
@end

#undef blk0
#undef blk
#undef R0
#undef R1
#undef R2
#undef R3
#undef R4
