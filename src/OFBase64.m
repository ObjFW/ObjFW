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

#import "OFBase64.h"
#import "OFString.h"
#import "OFData.h"

static const unsigned char encodeTable[64] = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
	'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b',
	'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
	'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '/'
};

static const signed char decodeTable[128] = {
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54,
	55, 56, 57, 58, 59, 60, 61, -1, -1, -1,  0, -1, -1, -1,  0,  1,  2,
	 3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
	20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30,
	31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
	48, 49, 50, 51, -1, -1, -1, -1, -1
};

OFString *
_OFBase64Encode(const void *data, size_t length)
{
	OFMutableString *ret = [OFMutableString string];
	uint8_t *buffer = (uint8_t *)data;
	size_t i;
	uint8_t rest;
	char tb[4];
	uint32_t sb;

	rest = length % 3;

	for (i = 0; i < length - rest; i += 3) {
		sb = (buffer[i] << 16) | (buffer[i + 1] << 8) | buffer[i + 2];

		tb[0] = encodeTable[(sb & 0xFC0000) >> 18];
		tb[1] = encodeTable[(sb & 0x03F000) >> 12];
		tb[2] = encodeTable[(sb & 0x000FC0) >> 6];
		tb[3] = encodeTable[sb & 0x00003F];

		[ret appendCString: tb
			  encoding: OFStringEncodingASCII
			    length: 4];
	}

	switch (rest) {
	case 1:
		tb[0] = encodeTable[buffer[i] >> 2];
		tb[1] = encodeTable[(buffer[i] & 3) << 4];
		tb[2] = tb[3] = '=';

		[ret appendCString: tb
			  encoding: OFStringEncodingASCII
			    length: 4];

		break;
	case 2:
		sb = (buffer[i] << 16) | (buffer[i + 1] << 8);

		tb[0] = encodeTable[(sb & 0xFC0000) >> 18];
		tb[1] = encodeTable[(sb & 0x03F000) >> 12];
		tb[2] = encodeTable[(sb & 0x000FC0) >> 6];
		tb[3] = '=';

		[ret appendCString: tb
			  encoding: OFStringEncodingASCII
			    length: 4];

		break;
	}

	[ret makeImmutable];

	return ret;
}

bool
_OFBase64Decode(OFMutableData *data, const char *string, size_t length)
{
	const uint8_t *buffer = (const uint8_t *)string;
	size_t i;

	if ((length & 3) != 0)
		return false;

	if (data.itemSize != 1)
		return false;

	for (i = 0; i < length; i += 4) {
		uint32_t sb = 0;
		uint8_t count = 3;
		char db[3];
		int8_t tmp;

		if (buffer[i] > 0x7F || buffer[i + 1] > 0x7F ||
		    buffer[i + 2] > 0x7F || buffer[i + 3] > 0x7F)
			return false;

		if (buffer[i] == '=' || buffer[i + 1] == '=' ||
		    (buffer[i + 2] == '=' && buffer[i + 3] != '='))
			return false;

		if (buffer[i + 2] == '=')
			count--;
		if (buffer[i + 3] == '=')
			count--;

		if ((tmp = decodeTable[buffer[i]]) == -1)
			return false;

		sb |= tmp << 18;

		if ((tmp = decodeTable[buffer[i + 1]]) == -1)
			return false;

		sb |= tmp << 12;

		if ((tmp = decodeTable[buffer[i + 2]]) == -1)
			return false;

		sb |= tmp << 6;

		if ((tmp = decodeTable[buffer[i + 3]]) == -1)
			return false;

		sb |= tmp;

		db[0] = (sb & 0xFF0000) >> 16;
		db[1] = (sb & 0x00FF00) >> 8;
		db[2] = sb & 0x0000FF;

		[data addItems: db count: count];
	}

	return true;
}
