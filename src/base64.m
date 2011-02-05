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
#import "base64.h"

const char of_base64_table[64] = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
	'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b',
	'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
	'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '/'
};

OFString*
of_base64_encode(const char *buf, size_t len)
{
	OFMutableString *ret = [OFMutableString string];
	size_t i, rest;
	char tb[4];
	uint32_t sb;

	rest = len % 3;

	for (i = 0; i < len - rest; i += 3) {
		sb = (buf[i] << 16) | (buf[i + 1] << 8) | buf[i + 2];

		tb[0] = of_base64_table[(sb & 0xFC0000) >> 18];
		tb[1] = of_base64_table[(sb & 0x03F000) >> 12];
		tb[2] = of_base64_table[(sb & 0x000FC0) >> 6];
		tb[3] = of_base64_table[(sb & 0x00003F)];

		[ret appendCStringWithoutUTF8Checking: tb
					       length: 4];
	}

	switch (rest) {
	case 1:;
		tb[0] = of_base64_table[buf[i] >> 2];
		tb[1] = of_base64_table[(buf[i] & 3) << 4];
		tb[2] = tb[3] = '=';

		[ret appendCStringWithoutUTF8Checking: tb
					       length: 4];

		break;
	case 2:;
		sb = (buf[i] << 16) | (buf[i + 1] << 8);

		tb[0] = of_base64_table[(sb & 0xFC0000) >> 18];
		tb[1] = of_base64_table[(sb & 0x03F000) >> 12];
		tb[2] = of_base64_table[(sb & 0x000FC0) >> 6];
		tb[3] = '=';

		[ret appendCStringWithoutUTF8Checking: tb
					       length: 4];

		break;
	}

	return ret;
}
