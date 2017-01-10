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

const of_char16_t of_codepage_850[128] = {
	0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7,
	0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
	0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9,
	0x00FF, 0x00D6, 0x00DC, 0x00F8, 0x00A3, 0x00D8, 0x00D7, 0x0192,
	0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA,
	0x00BF, 0x00AE, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
	0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x00C1, 0x00C2, 0x00C0,
	0x00A9, 0x2563, 0x2551, 0x2557, 0x255D, 0x00A2, 0x00A5, 0x2510,
	0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x00E3, 0x00C3,
	0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x00A4,
	0x00F0, 0x00D0, 0x00CA, 0x00CB, 0x00C8, 0x0131, 0x00CD, 0x00CE,
	0x00CF, 0x2518, 0x250C, 0x2588, 0x2584, 0x00A6, 0x00CC, 0x2580,
	0x00D3, 0x00DF, 0x00D4, 0x00D2, 0x00F5, 0x00D5, 0x00B5, 0x00FE,
	0x00DE, 0x00DA, 0x00DB, 0x00D9, 0x00FD, 0x00DD, 0x00AF, 0x00B4,
	0x00AD, 0x00B1, 0x2017, 0x00BE, 0x00B6, 0x00A7, 0x00F7, 0x00B8,
	0x00B0, 0x00A8, 0x00B7, 0x00B9, 0x00B3, 0x00B2, 0x25A0, 0x00A0
};

bool
of_unicode_to_codepage_850(const of_unichar_t *input, uint8_t *output,
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

			switch ((of_char16_t)c) {
			case 0xC7:
				output[i] = 0x80;
				break;
			case 0xFC:
				output[i] = 0x81;
				break;
			case 0xE9:
				output[i] = 0x82;
				break;
			case 0xE2:
				output[i] = 0x83;
				break;
			case 0xE4:
				output[i] = 0x84;
				break;
			case 0xE0:
				output[i] = 0x85;
				break;
			case 0xE5:
				output[i] = 0x86;
				break;
			case 0xE7:
				output[i] = 0x87;
				break;
			case 0xEA:
				output[i] = 0x88;
				break;
			case 0xEB:
				output[i] = 0x89;
				break;
			case 0xE8:
				output[i] = 0x8A;
				break;
			case 0xEF:
				output[i] = 0x8B;
				break;
			case 0xEE:
				output[i] = 0x8C;
				break;
			case 0xEC:
				output[i] = 0x8D;
				break;
			case 0xC4:
				output[i] = 0x8E;
				break;
			case 0xC5:
				output[i] = 0x8F;
				break;
			case 0xC9:
				output[i] = 0x90;
				break;
			case 0xE6:
				output[i] = 0x91;
				break;
			case 0xC6:
				output[i] = 0x92;
				break;
			case 0xF4:
				output[i] = 0x93;
				break;
			case 0xF6:
				output[i] = 0x94;
				break;
			case 0xF2:
				output[i] = 0x95;
				break;
			case 0xFB:
				output[i] = 0x96;
				break;
			case 0xF9:
				output[i] = 0x97;
				break;
			case 0xFF:
				output[i] = 0x98;
				break;
			case 0xD6:
				output[i] = 0x99;
				break;
			case 0xDC:
				output[i] = 0x9A;
				break;
			case 0xF8:
				output[i] = 0x9B;
				break;
			case 0xA3:
				output[i] = 0x9C;
				break;
			case 0xD8:
				output[i] = 0x9D;
				break;
			case 0xD7:
				output[i] = 0x9E;
				break;
			case 0x192:
				output[i] = 0x9F;
				break;
			case 0xE1:
				output[i] = 0xA0;
				break;
			case 0xED:
				output[i] = 0xA1;
				break;
			case 0xF3:
				output[i] = 0xA2;
				break;
			case 0xFA:
				output[i] = 0xA3;
				break;
			case 0xF1:
				output[i] = 0xA4;
				break;
			case 0xD1:
				output[i] = 0xA5;
				break;
			case 0xAA:
				output[i] = 0xA6;
				break;
			case 0xBA:
				output[i] = 0xA7;
				break;
			case 0xBF:
				output[i] = 0xA8;
				break;
			case 0xAE:
				output[i] = 0xA9;
				break;
			case 0xAC:
				output[i] = 0xAA;
				break;
			case 0xBD:
				output[i] = 0xAB;
				break;
			case 0xBC:
				output[i] = 0xAC;
				break;
			case 0xA1:
				output[i] = 0xAD;
				break;
			case 0xAB:
				output[i] = 0xAE;
				break;
			case 0xBB:
				output[i] = 0xAF;
				break;
			case 0x2591:
				output[i] = 0xB0;
				break;
			case 0x2592:
				output[i] = 0xB1;
				break;
			case 0x2593:
				output[i] = 0xB2;
				break;
			case 0x2502:
				output[i] = 0xB3;
				break;
			case 0x2524:
				output[i] = 0xB4;
				break;
			case 0xC1:
				output[i] = 0xB5;
				break;
			case 0xC2:
				output[i] = 0xB6;
				break;
			case 0xC0:
				output[i] = 0xB7;
				break;
			case 0xA9:
				output[i] = 0xB8;
				break;
			case 0x2563:
				output[i] = 0xB9;
				break;
			case 0x2551:
				output[i] = 0xBA;
				break;
			case 0x2557:
				output[i] = 0xBB;
				break;
			case 0x255D:
				output[i] = 0xBC;
				break;
			case 0xA2:
				output[i] = 0xBD;
				break;
			case 0xA5:
				output[i] = 0xBE;
				break;
			case 0x2510:
				output[i] = 0xBF;
				break;
			case 0x2514:
				output[i] = 0xC0;
				break;
			case 0x2534:
				output[i] = 0xC1;
				break;
			case 0x252C:
				output[i] = 0xC2;
				break;
			case 0x251C:
				output[i] = 0xC3;
				break;
			case 0x2500:
				output[i] = 0xC4;
				break;
			case 0x253C:
				output[i] = 0xC5;
				break;
			case 0xE3:
				output[i] = 0xC6;
				break;
			case 0xC3:
				output[i] = 0xC7;
				break;
			case 0x255A:
				output[i] = 0xC8;
				break;
			case 0x2554:
				output[i] = 0xC9;
				break;
			case 0x2569:
				output[i] = 0xCA;
				break;
			case 0x2566:
				output[i] = 0xCB;
				break;
			case 0x2560:
				output[i] = 0xCC;
				break;
			case 0x2550:
				output[i] = 0xCD;
				break;
			case 0x256C:
				output[i] = 0xCE;
				break;
			case 0xA4:
				output[i] = 0xCF;
				break;
			case 0xF0:
				output[i] = 0xD0;
				break;
			case 0xD0:
				output[i] = 0xD1;
				break;
			case 0xCA:
				output[i] = 0xD2;
				break;
			case 0xCB:
				output[i] = 0xD3;
				break;
			case 0xC8:
				output[i] = 0xD4;
				break;
			case 0x131:
				output[i] = 0xD5;
				break;
			case 0xCD:
				output[i] = 0xD6;
				break;
			case 0xCE:
				output[i] = 0xD7;
				break;
			case 0xCF:
				output[i] = 0xD8;
				break;
			case 0x2518:
				output[i] = 0xD9;
				break;
			case 0x250C:
				output[i] = 0xDA;
				break;
			case 0x2588:
				output[i] = 0xDB;
				break;
			case 0x2584:
				output[i] = 0xDC;
				break;
			case 0xA6:
				output[i] = 0xDD;
				break;
			case 0xCC:
				output[i] = 0xDE;
				break;
			case 0x2580:
				output[i] = 0xDF;
				break;
			case 0xD3:
				output[i] = 0xE0;
				break;
			case 0xDF:
				output[i] = 0xE1;
				break;
			case 0xD4:
				output[i] = 0xE2;
				break;
			case 0xD2:
				output[i] = 0xE3;
				break;
			case 0xF5:
				output[i] = 0xE4;
				break;
			case 0xD5:
				output[i] = 0xE5;
				break;
			case 0xB5:
				output[i] = 0xE6;
				break;
			case 0xFE:
				output[i] = 0xE7;
				break;
			case 0xDE:
				output[i] = 0xE8;
				break;
			case 0xDA:
				output[i] = 0xE9;
				break;
			case 0xDB:
				output[i] = 0xEA;
				break;
			case 0xD9:
				output[i] = 0xEB;
				break;
			case 0xFD:
				output[i] = 0xEC;
				break;
			case 0xDD:
				output[i] = 0xED;
				break;
			case 0xAF:
				output[i] = 0xEE;
				break;
			case 0xB4:
				output[i] = 0xEF;
				break;
			case 0xAD:
				output[i] = 0xF0;
				break;
			case 0xB1:
				output[i] = 0xF1;
				break;
			case 0x2017:
				output[i] = 0xF2;
				break;
			case 0xBE:
				output[i] = 0xF3;
				break;
			case 0xB6:
				output[i] = 0xF4;
				break;
			case 0xA7:
				output[i] = 0xF5;
				break;
			case 0xF7:
				output[i] = 0xF6;
				break;
			case 0xB8:
				output[i] = 0xF7;
				break;
			case 0xB0:
				output[i] = 0xF8;
				break;
			case 0xA8:
				output[i] = 0xF9;
				break;
			case 0xB7:
				output[i] = 0xFA;
				break;
			case 0xB9:
				output[i] = 0xFB;
				break;
			case 0xB3:
				output[i] = 0xFC;
				break;
			case 0xB2:
				output[i] = 0xFD;
				break;
			case 0x25A0:
				output[i] = 0xFE;
				break;
			case 0xA0:
				output[i] = 0xFF;
				break;
			default:
				if (lossy)
					output[i] = '?';
				else
					return false;

				break;
			}
		} else
			output[i] = (uint8_t)c;
	}

	return true;
}
