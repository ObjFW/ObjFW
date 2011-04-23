/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFString.h"
#import "OFDataArray.h"
#import "base64.h"

const uint8_t of_base64_encode_table[64] = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
	'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b',
	'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
	'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '/'
};

const int8_t of_base64_decode_table[128] = {
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54,
	55, 56, 57, 58, 59, 60, 61, -1, -1, -1,  0, -1, -1, -1,  0,  1,  2,
	 3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
	20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30,
	31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
	48, 49, 50, 51, -1, -1, -1, -1, -1
};

OFString*
of_base64_encode(const char *data, size_t length)
{
	OFMutableString *ret = [OFMutableString string];
	uint8_t *buffer = (uint8_t*)data;
	size_t i;
	uint8_t rest;
	char tb[4];
	uint32_t sb;

	rest = length % 3;

	for (i = 0; i < length - rest; i += 3) {
		sb = (buffer[i] << 16) | (buffer[i + 1] << 8) | buffer[i + 2];

		tb[0] = of_base64_encode_table[(sb & 0xFC0000) >> 18];
		tb[1] = of_base64_encode_table[(sb & 0x03F000) >> 12];
		tb[2] = of_base64_encode_table[(sb & 0x000FC0) >> 6];
		tb[3] = of_base64_encode_table[sb & 0x00003F];

		[ret appendCStringWithoutUTF8Checking: tb
					       length: 4];
	}

	switch (rest) {
	case 1:
		tb[0] = of_base64_encode_table[buffer[i] >> 2];
		tb[1] = of_base64_encode_table[(buffer[i] & 3) << 4];
		tb[2] = tb[3] = '=';

		[ret appendCStringWithoutUTF8Checking: tb
					       length: 4];

		break;
	case 2:
		sb = (buffer[i] << 16) | (buffer[i + 1] << 8);

		tb[0] = of_base64_encode_table[(sb & 0xFC0000) >> 18];
		tb[1] = of_base64_encode_table[(sb & 0x03F000) >> 12];
		tb[2] = of_base64_encode_table[(sb & 0x000FC0) >> 6];
		tb[3] = '=';

		[ret appendCStringWithoutUTF8Checking: tb
					       length: 4];

		break;
	}

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}

BOOL
of_base64_decode(OFDataArray *data, const char *cString, size_t len)
{
	const uint8_t *buffer = (const uint8_t*)cString;
	size_t i;

	if ((len & 3) != 0)
		return NO;

	for (i = 0; i < len; i += 4) {
		uint32_t sb = 0;
		uint8_t count = 3;
		char db[3];
		char tmp;

		if (buffer[i] > 0x7F || buffer[i + 1] > 0x7F ||
		    buffer[i + 2] > 0x7F || buffer[i + 3] > 0x7F)
			return NO;

		if (buffer[i] == '=' || buffer[i + 1] == '=' ||
		    (buffer[i + 2] == '=' && buffer[i + 3] != '='))
			return NO;

		if (buffer[i + 2] == '=')
			count--;
		if (buffer[i + 3] == '=')
			count--;

		if ((tmp = of_base64_decode_table[buffer[i]]) == -1)
			return NO;

		sb |= tmp << 18;

		if ((tmp = of_base64_decode_table[buffer[i + 1]]) == -1)
			return NO;

		sb |= tmp << 12;

		if ((tmp = of_base64_decode_table[buffer[i + 2]]) == -1)
			return NO;

		sb |= tmp << 6;

		if ((tmp = of_base64_decode_table[buffer[i + 3]]) == -1)
			return NO;

		sb |= tmp;

		db[0] = (sb & 0xFF0000) >> 16;
		db[1] = (sb & 0x00FF00) >> 8;
		db[2] = sb & 0x0000FF;

		[data addNItems: count
		     fromCArray: db];
	}

	return YES;
}
