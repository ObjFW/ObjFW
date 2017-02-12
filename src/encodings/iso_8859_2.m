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

const of_char16_t of_iso_8859_2_table[] = {
	0x00A0, 0x0104, 0x02D8, 0x0141, 0x00A4, 0x013D, 0x015A, 0x00A7,
	0x00A8, 0x0160, 0x015E, 0x0164, 0x0179, 0x00AD, 0x017D, 0x017B,
	0x00B0, 0x0105, 0x02DB, 0x0142, 0x00B4, 0x013E, 0x015B, 0x02C7,
	0x00B8, 0x0161, 0x015F, 0x0165, 0x017A, 0x02DD, 0x017E, 0x017C,
	0x0154, 0x00C1, 0x00C2, 0x0102, 0x00C4, 0x0139, 0x0106, 0x00C7,
	0x010C, 0x00C9, 0x0118, 0x00CB, 0x011A, 0x00CD, 0x00CE, 0x010E,
	0x0110, 0x0143, 0x0147, 0x00D3, 0x00D4, 0x0150, 0x00D6, 0x00D7,
	0x0158, 0x016E, 0x00DA, 0x0170, 0x00DC, 0x00DD, 0x0162, 0x00DF,
	0x0155, 0x00E1, 0x00E2, 0x0103, 0x00E4, 0x013A, 0x0107, 0x00E7,
	0x010D, 0x00E9, 0x0119, 0x00EB, 0x011B, 0x00ED, 0x00EE, 0x010F,
	0x0111, 0x0144, 0x0148, 0x00F3, 0x00F4, 0x0151, 0x00F6, 0x00F7,
	0x0159, 0x016F, 0x00FA, 0x0171, 0x00FC, 0x00FD, 0x0163, 0x02D9
};
const size_t of_iso_8859_2_table_offset =
    256 - (sizeof(of_iso_8859_2_table) / sizeof(*of_iso_8859_2_table));

bool
of_unicode_to_iso_8859_2(const of_unichar_t *input, unsigned char *output,
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

			if OF_UNLIKELY (c >= 0x80 && c <= 0x9F)
				output[i] = c;
			else {
				switch ((of_char16_t)c) {
				case 0xA0:
					output[i] = 0xA0;
					break;
				case 0x104:
					output[i] = 0xA1;
					break;
				case 0x2D8:
					output[i] = 0xA2;
					break;
				case 0x141:
					output[i] = 0xA3;
					break;
				case 0xA4:
					output[i] = 0xA4;
					break;
				case 0x13D:
					output[i] = 0xA5;
					break;
				case 0x15A:
					output[i] = 0xA6;
					break;
				case 0xA7:
					output[i] = 0xA7;
					break;
				case 0xA8:
					output[i] = 0xA8;
					break;
				case 0x160:
					output[i] = 0xA9;
					break;
				case 0x15E:
					output[i] = 0xAA;
					break;
				case 0x164:
					output[i] = 0xAB;
					break;
				case 0x179:
					output[i] = 0xAC;
					break;
				case 0xAD:
					output[i] = 0xAD;
					break;
				case 0x17D:
					output[i] = 0xAE;
					break;
				case 0x17B:
					output[i] = 0xAF;
					break;
				case 0xB0:
					output[i] = 0xB0;
					break;
				case 0x105:
					output[i] = 0xB1;
					break;
				case 0x2DB:
					output[i] = 0xB2;
					break;
				case 0x142:
					output[i] = 0xB3;
					break;
				case 0xB4:
					output[i] = 0xB4;
					break;
				case 0x13E:
					output[i] = 0xB5;
					break;
				case 0x15B:
					output[i] = 0xB6;
					break;
				case 0x2C7:
					output[i] = 0xB7;
					break;
				case 0xB8:
					output[i] = 0xB8;
					break;
				case 0x161:
					output[i] = 0xB9;
					break;
				case 0x15F:
					output[i] = 0xBA;
					break;
				case 0x165:
					output[i] = 0xBB;
					break;
				case 0x17A:
					output[i] = 0xBC;
					break;
				case 0x2DD:
					output[i] = 0xBD;
					break;
				case 0x17E:
					output[i] = 0xBE;
					break;
				case 0x17C:
					output[i] = 0xBF;
					break;
				case 0x154:
					output[i] = 0xC0;
					break;
				case 0xC1:
					output[i] = 0xC1;
					break;
				case 0xC2:
					output[i] = 0xC2;
					break;
				case 0x102:
					output[i] = 0xC3;
					break;
				case 0xC4:
					output[i] = 0xC4;
					break;
				case 0x139:
					output[i] = 0xC5;
					break;
				case 0x106:
					output[i] = 0xC6;
					break;
				case 0xC7:
					output[i] = 0xC7;
					break;
				case 0x10C:
					output[i] = 0xC8;
					break;
				case 0xC9:
					output[i] = 0xC9;
					break;
				case 0x118:
					output[i] = 0xCA;
					break;
				case 0xCB:
					output[i] = 0xCB;
					break;
				case 0x11A:
					output[i] = 0xCC;
					break;
				case 0xCD:
					output[i] = 0xCD;
					break;
				case 0xCE:
					output[i] = 0xCE;
					break;
				case 0x10E:
					output[i] = 0xCF;
					break;
				case 0x110:
					output[i] = 0xD0;
					break;
				case 0x143:
					output[i] = 0xD1;
					break;
				case 0x147:
					output[i] = 0xD2;
					break;
				case 0xD3:
					output[i] = 0xD3;
					break;
				case 0xD4:
					output[i] = 0xD4;
					break;
				case 0x150:
					output[i] = 0xD5;
					break;
				case 0xD6:
					output[i] = 0xD6;
					break;
				case 0xD7:
					output[i] = 0xD7;
					break;
				case 0x158:
					output[i] = 0xD8;
					break;
				case 0x16E:
					output[i] = 0xD9;
					break;
				case 0xDA:
					output[i] = 0xDA;
					break;
				case 0x170:
					output[i] = 0xDB;
					break;
				case 0xDC:
					output[i] = 0xDC;
					break;
				case 0xDD:
					output[i] = 0xDD;
					break;
				case 0x162:
					output[i] = 0xDE;
					break;
				case 0xDF:
					output[i] = 0xDF;
					break;
				case 0x155:
					output[i] = 0xE0;
					break;
				case 0xE1:
					output[i] = 0xE1;
					break;
				case 0xE2:
					output[i] = 0xE2;
					break;
				case 0x103:
					output[i] = 0xE3;
					break;
				case 0xE4:
					output[i] = 0xE4;
					break;
				case 0x13A:
					output[i] = 0xE5;
					break;
				case 0x107:
					output[i] = 0xE6;
					break;
				case 0xE7:
					output[i] = 0xE7;
					break;
				case 0x10D:
					output[i] = 0xE8;
					break;
				case 0xE9:
					output[i] = 0xE9;
					break;
				case 0x119:
					output[i] = 0xEA;
					break;
				case 0xEB:
					output[i] = 0xEB;
					break;
				case 0x11B:
					output[i] = 0xEC;
					break;
				case 0xED:
					output[i] = 0xED;
					break;
				case 0xEE:
					output[i] = 0xEE;
					break;
				case 0x10F:
					output[i] = 0xEF;
					break;
				case 0x111:
					output[i] = 0xF0;
					break;
				case 0x144:
					output[i] = 0xF1;
					break;
				case 0x148:
					output[i] = 0xF2;
					break;
				case 0xF3:
					output[i] = 0xF3;
					break;
				case 0xF4:
					output[i] = 0xF4;
					break;
				case 0x151:
					output[i] = 0xF5;
					break;
				case 0xF6:
					output[i] = 0xF6;
					break;
				case 0xF7:
					output[i] = 0xF7;
					break;
				case 0x159:
					output[i] = 0xF8;
					break;
				case 0x16F:
					output[i] = 0xF9;
					break;
				case 0xFA:
					output[i] = 0xFA;
					break;
				case 0x171:
					output[i] = 0xFB;
					break;
				case 0xFC:
					output[i] = 0xFC;
					break;
				case 0xFD:
					output[i] = 0xFD;
					break;
				case 0x163:
					output[i] = 0xFE;
					break;
				case 0x2D9:
					output[i] = 0xFF;
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
