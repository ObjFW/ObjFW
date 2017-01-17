/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFString.h"

const of_char16_t of_windows_1251[128] = {
	0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021,
	0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F,
	0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
	0xFFFF, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F,
	0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7,
	0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407,
	0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7,
	0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
	0x0410, 0x0411, 0x0412, 0x0413, 0x0414, 0x0415, 0x0416, 0x0417,
	0x0418, 0x0419, 0x041A, 0x041B, 0x041C, 0x041D, 0x041E, 0x041F,
	0x0420, 0x0421, 0x0422, 0x0423, 0x0424, 0x0425, 0x0426, 0x0427,
	0x0428, 0x0429, 0x042A, 0x042B, 0x042C, 0x042D, 0x042E, 0x042F,
	0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437,
	0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F,
	0x0440, 0x0441, 0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447,
	0x0448, 0x0449, 0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F
};

bool
of_unicode_to_windows_1251(const of_unichar_t *input, unsigned char *output,
    size_t length, bool lossy)
{
	for (size_t i = 0; i < length; i++) {
		of_unichar_t c = input[i];

		if OF_UNLIKELY (c > 0x7F) {
			if OF_UNLIKELY (c > 0xFFFF) {
				if (lossy) {
					output[i] = '?';
					continue;
				} else
					return false;
			}

			if OF_LIKELY (c >= 0x410 && c <= 0x44F)
				output[i] = 0xC0 + (c - 0x410);
			else {
				switch ((of_char16_t)c) {
				case 0x402:
					output[i] = 0x80;
					break;
				case 0x403:
					output[i] = 0x81;
					break;
				case 0x201A:
					output[i] = 0x82;
					break;
				case 0x453:
					output[i] = 0x83;
					break;
				case 0x201E:
					output[i] = 0x84;
					break;
				case 0x2026:
					output[i] = 0x85;
					break;
				case 0x2020:
					output[i] = 0x86;
					break;
				case 0x2021:
					output[i] = 0x87;
					break;
				case 0x20AC:
					output[i] = 0x88;
					break;
				case 0x2030:
					output[i] = 0x89;
					break;
				case 0x409:
					output[i] = 0x8A;
					break;
				case 0x2039:
					output[i] = 0x8B;
					break;
				case 0x40A:
					output[i] = 0x8C;
					break;
				case 0x40C:
					output[i] = 0x8D;
					break;
				case 0x40B:
					output[i] = 0x8E;
					break;
				case 0x40F:
					output[i] = 0x8F;
					break;
				case 0x452:
					output[i] = 0x90;
					break;
				case 0x2018:
					output[i] = 0x91;
					break;
				case 0x2019:
					output[i] = 0x92;
					break;
				case 0x201C:
					output[i] = 0x93;
					break;
				case 0x201D:
					output[i] = 0x94;
					break;
				case 0x2022:
					output[i] = 0x95;
					break;
				case 0x2013:
					output[i] = 0x96;
					break;
				case 0x2014:
					output[i] = 0x97;
					break;
				case 0x2122:
					output[i] = 0x99;
					break;
				case 0x459:
					output[i] = 0x9A;
					break;
				case 0x203A:
					output[i] = 0x9B;
					break;
				case 0x45A:
					output[i] = 0x9C;
					break;
				case 0x45C:
					output[i] = 0x9D;
					break;
				case 0x45B:
					output[i] = 0x9E;
					break;
				case 0x45F:
					output[i] = 0x9F;
					break;
				case 0xA0:
					output[i] = 0xA0;
					break;
				case 0x40E:
					output[i] = 0xA1;
					break;
				case 0x45E:
					output[i] = 0xA2;
					break;
				case 0x408:
					output[i] = 0xA3;
					break;
				case 0xA4:
					output[i] = 0xA4;
					break;
				case 0x490:
					output[i] = 0xA5;
					break;
				case 0xA6:
					output[i] = 0xA6;
					break;
				case 0xA7:
					output[i] = 0xA7;
					break;
				case 0x401:
					output[i] = 0xA8;
					break;
				case 0xA9:
					output[i] = 0xA9;
					break;
				case 0x404:
					output[i] = 0xAA;
					break;
				case 0xAB:
					output[i] = 0xAB;
					break;
				case 0xAC:
					output[i] = 0xAC;
					break;
				case 0xAD:
					output[i] = 0xAD;
					break;
				case 0xAE:
					output[i] = 0xAE;
					break;
				case 0x407:
					output[i] = 0xAF;
					break;
				case 0xB0:
					output[i] = 0xB0;
					break;
				case 0xB1:
					output[i] = 0xB1;
					break;
				case 0x406:
					output[i] = 0xB2;
					break;
				case 0x456:
					output[i] = 0xB3;
					break;
				case 0x491:
					output[i] = 0xB4;
					break;
				case 0xB5:
					output[i] = 0xB5;
					break;
				case 0xB6:
					output[i] = 0xB6;
					break;
				case 0xB7:
					output[i] = 0xB7;
					break;
				case 0x451:
					output[i] = 0xB8;
					break;
				case 0x2116:
					output[i] = 0xB9;
					break;
				case 0x454:
					output[i] = 0xBA;
					break;
				case 0xBB:
					output[i] = 0xBB;
					break;
				case 0x458:
					output[i] = 0xBC;
					break;
				case 0x405:
					output[i] = 0xBD;
					break;
				case 0x455:
					output[i] = 0xBE;
					break;
				case 0x457:
					output[i] = 0xBF;
					break;
				default:
					if (lossy)
						output[i] = '?';
					else
						return false;

					break;
				}
			}
		} else
			output[i] = (unsigned char)c;
	}

	return true;
}
