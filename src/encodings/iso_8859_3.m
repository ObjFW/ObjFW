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

const of_char16_t of_iso_8859_3_table[] = {
	0x00A0, 0x0126, 0x02D8, 0x00A3, 0x00A4, 0xFFFF, 0x0124, 0x00A7,
	0x00A8, 0x0130, 0x015E, 0x011E, 0x0134, 0x00AD, 0xFFFF, 0x017B,
	0x00B0, 0x0127, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x0125, 0x00B7,
	0x00B8, 0x0131, 0x015F, 0x011F, 0x0135, 0x00BD, 0xFFFF, 0x017C,
	0x00C0, 0x00C1, 0x00C2, 0xFFFF, 0x00C4, 0x010A, 0x0108, 0x00C7,
	0x00C8, 0x00C9, 0x00CA, 0x00CB, 0x00CC, 0x00CD, 0x00CE, 0x00CF,
	0xFFFF, 0x00D1, 0x00D2, 0x00D3, 0x00D4, 0x0120, 0x00D6, 0x00D7,
	0x011C, 0x00D9, 0x00DA, 0x00DB, 0x00DC, 0x016C, 0x015C, 0x00DF,
	0x00E0, 0x00E1, 0x00E2, 0xFFFF, 0x00E4, 0x010B, 0x0109, 0x00E7,
	0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED, 0x00EE, 0x00EF,
	0xFFFF, 0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x0121, 0x00F6, 0x00F7,
	0x011D, 0x00F9, 0x00FA, 0x00FB, 0x00FC, 0x016D, 0x015D, 0x02D9
};
const size_t of_iso_8859_3_table_offset =
    256 - (sizeof(of_iso_8859_3_table) / sizeof(*of_iso_8859_3_table));

bool
of_unicode_to_iso_8859_3(const of_unichar_t *input, unsigned char *output,
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
				case 0x126:
					output[i] = 0xA1;
					break;
				case 0x2D8:
					output[i] = 0xA2;
					break;
				case 0xA3:
					output[i] = 0xA3;
					break;
				case 0xA4:
					output[i] = 0xA4;
					break;
				case 0x124:
					output[i] = 0xA6;
					break;
				case 0xA7:
					output[i] = 0xA7;
					break;
				case 0xA8:
					output[i] = 0xA8;
					break;
				case 0x130:
					output[i] = 0xA9;
					break;
				case 0x15E:
					output[i] = 0xAA;
					break;
				case 0x11E:
					output[i] = 0xAB;
					break;
				case 0x134:
					output[i] = 0xAC;
					break;
				case 0xAD:
					output[i] = 0xAD;
					break;
				case 0x17B:
					output[i] = 0xAF;
					break;
				case 0xB0:
					output[i] = 0xB0;
					break;
				case 0x127:
					output[i] = 0xB1;
					break;
				case 0xB2:
					output[i] = 0xB2;
					break;
				case 0xB3:
					output[i] = 0xB3;
					break;
				case 0xB4:
					output[i] = 0xB4;
					break;
				case 0xB5:
					output[i] = 0xB5;
					break;
				case 0x125:
					output[i] = 0xB6;
					break;
				case 0xB7:
					output[i] = 0xB7;
					break;
				case 0xB8:
					output[i] = 0xB8;
					break;
				case 0x131:
					output[i] = 0xB9;
					break;
				case 0x15F:
					output[i] = 0xBA;
					break;
				case 0x11F:
					output[i] = 0xBB;
					break;
				case 0x135:
					output[i] = 0xBC;
					break;
				case 0xBD:
					output[i] = 0xBD;
					break;
				case 0x17C:
					output[i] = 0xBF;
					break;
				case 0xC0:
					output[i] = 0xC0;
					break;
				case 0xC1:
					output[i] = 0xC1;
					break;
				case 0xC2:
					output[i] = 0xC2;
					break;
				case 0xC4:
					output[i] = 0xC4;
					break;
				case 0x10A:
					output[i] = 0xC5;
					break;
				case 0x108:
					output[i] = 0xC6;
					break;
				case 0xC7:
					output[i] = 0xC7;
					break;
				case 0xC8:
					output[i] = 0xC8;
					break;
				case 0xC9:
					output[i] = 0xC9;
					break;
				case 0xCA:
					output[i] = 0xCA;
					break;
				case 0xCB:
					output[i] = 0xCB;
					break;
				case 0xCC:
					output[i] = 0xCC;
					break;
				case 0xCD:
					output[i] = 0xCD;
					break;
				case 0xCE:
					output[i] = 0xCE;
					break;
				case 0xCF:
					output[i] = 0xCF;
					break;
				case 0xD1:
					output[i] = 0xD1;
					break;
				case 0xD2:
					output[i] = 0xD2;
					break;
				case 0xD3:
					output[i] = 0xD3;
					break;
				case 0xD4:
					output[i] = 0xD4;
					break;
				case 0x120:
					output[i] = 0xD5;
					break;
				case 0xD6:
					output[i] = 0xD6;
					break;
				case 0xD7:
					output[i] = 0xD7;
					break;
				case 0x11C:
					output[i] = 0xD8;
					break;
				case 0xD9:
					output[i] = 0xD9;
					break;
				case 0xDA:
					output[i] = 0xDA;
					break;
				case 0xDB:
					output[i] = 0xDB;
					break;
				case 0xDC:
					output[i] = 0xDC;
					break;
				case 0x16C:
					output[i] = 0xDD;
					break;
				case 0x15C:
					output[i] = 0xDE;
					break;
				case 0xDF:
					output[i] = 0xDF;
					break;
				case 0xE0:
					output[i] = 0xE0;
					break;
				case 0xE1:
					output[i] = 0xE1;
					break;
				case 0xE2:
					output[i] = 0xE2;
					break;
				case 0xE4:
					output[i] = 0xE4;
					break;
				case 0x10B:
					output[i] = 0xE5;
					break;
				case 0x109:
					output[i] = 0xE6;
					break;
				case 0xE7:
					output[i] = 0xE7;
					break;
				case 0xE8:
					output[i] = 0xE8;
					break;
				case 0xE9:
					output[i] = 0xE9;
					break;
				case 0xEA:
					output[i] = 0xEA;
					break;
				case 0xEB:
					output[i] = 0xEB;
					break;
				case 0xEC:
					output[i] = 0xEC;
					break;
				case 0xED:
					output[i] = 0xED;
					break;
				case 0xEE:
					output[i] = 0xEE;
					break;
				case 0xEF:
					output[i] = 0xEF;
					break;
				case 0xF1:
					output[i] = 0xF1;
					break;
				case 0xF2:
					output[i] = 0xF2;
					break;
				case 0xF3:
					output[i] = 0xF3;
					break;
				case 0xF4:
					output[i] = 0xF4;
					break;
				case 0x121:
					output[i] = 0xF5;
					break;
				case 0xF6:
					output[i] = 0xF6;
					break;
				case 0xF7:
					output[i] = 0xF7;
					break;
				case 0x11D:
					output[i] = 0xF8;
					break;
				case 0xF9:
					output[i] = 0xF9;
					break;
				case 0xFA:
					output[i] = 0xFA;
					break;
				case 0xFB:
					output[i] = 0xFB;
					break;
				case 0xFC:
					output[i] = 0xFC;
					break;
				case 0x16D:
					output[i] = 0xFD;
					break;
				case 0x15D:
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
