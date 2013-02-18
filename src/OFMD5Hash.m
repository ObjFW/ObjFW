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

#import "OFMD5Hash.h"

#import "OFHashAlreadyCalculatedException.h"

#import "macros.h"

/* The four MD5 core functions - F1 is optimized somewhat */
#define F1(x, y, z) (z ^ (x & (y ^ z)))
#define F2(x, y, z) F1(z, x, y)
#define F3(x, y, z) (x ^ y ^ z)
#define F4(x, y, z) (y ^ (x | ~z))

/* This is the central step in the MD5 algorithm. */
#define MD5STEP(f, w, x, y, z, data, s) \
	(w += f(x, y, z) + data, w = w << s | w >> (32 - s), w += x)

#ifdef OF_BIG_ENDIAN
static OF_INLINE void
BSWAP32_VEC_IF_BE(uint32_t *buffer, size_t length)
{
	while (length--) {
		*buffer = OF_BSWAP32(*buffer);
		buffer++;
	}
}
#else
# define BSWAP32_VEC_IF_BE(buffer, length)
#endif

static void
md5_transform(uint32_t buffer[4], const uint32_t in[16])
{
	register uint32_t a, b, c, d;

	a = buffer[0];
	b = buffer[1];
	c = buffer[2];
	d = buffer[3];

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

	buffer[0] += a;
	buffer[1] += b;
	buffer[2] += c;
	buffer[3] += d;
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

- init
{
	self = [super init];

	_buffer[0] = 0x67452301;
	_buffer[1] = 0xEFCDAB89;
	_buffer[2] = 0x98BADCFE;
	_buffer[3] = 0x10325476;

	return self;
}

- (void)updateWithBuffer: (const void*)buffer_
		  length: (size_t)length
{
	uint32_t t;
	const char *buffer = buffer_;

	if (length == 0)
		return;

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithClass: [self class]
				  hash: self];

	/* Update bitcount */
	t = _bits[0];
	if ((_bits[0] = t + ((uint32_t)length << 3)) < t)
		/* Carry from low to high */
		_bits[1]++;
	_bits[1] += (uint32_t)length >> 29;

	/* Bytes already in shsInfo->data */
	t = (t >> 3) & 0x3F;

	/* Handle any leading odd-sized chunks */
	if (t) {
		uint8_t *p = _in.u8 + t;

		t = 64 - t;

		if (length < t) {
			memcpy(p, buffer, length);
			return;
		}

		memcpy(p, buffer, t);
		BSWAP32_VEC_IF_BE(_in.u32, 16);
		md5_transform(_buffer, _in.u32);

		buffer += t;
		length -= t;
	}

	/* Process data in 64-byte chunks */
	while (length >= 64) {
		memcpy(_in.u8, buffer, 64);
		BSWAP32_VEC_IF_BE(_in.u32, 16);
		md5_transform(_buffer, _in.u32);

		buffer += 64;
		length -= 64;
	}

	/* Handle any remaining bytes of data. */
	memcpy(_in.u8, buffer, length);
}

- (uint8_t*)digest
{
	uint8_t	*p;
	size_t count;

	if (_calculated)
		return (uint8_t*)_buffer;

	/* Compute number of bytes mod 64 */
	count = (_bits[0] >> 3) & 0x3F;

	/*
	 * Set the first char of padding to 0x80. This is safe since there is
	 * always at least one byte free
	 */
	p = _in.u8 + count;
	*p++ = 0x80;

	/* Bytes of padding needed to make 64 bytes */
	count = 64 - 1 - count;

	/* Pad out to 56 mod 64 */
	if (count < 8) {
		/* Two lots of padding: Pad the first block to 64 bytes */
		memset(p, 0, count);
		BSWAP32_VEC_IF_BE(_in.u32, 16);
		md5_transform(_buffer, _in.u32);

		/* Now fill the next block with 56 bytes */
		memset(_in.u8, 0, 56);
	} else {
		/* Pad block to 56 bytes */
		memset(p, 0, count - 8);
	}
	BSWAP32_VEC_IF_BE(_in.u32, 14);

	/* Append length in bits and transform */
	_in.u32[14] = _bits[0];
	_in.u32[15] = _bits[1];

	md5_transform(_buffer, _in.u32);
	BSWAP32_VEC_IF_BE(_buffer, 4);

	_calculated = YES;

	return (uint8_t*)_buffer;
}
@end
