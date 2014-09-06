/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

const of_char16_t of_codepage_437[128] = {
	0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7,
	0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
	0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9,
	0x00FF, 0x00D6, 0x00DC, 0x00A2, 0x00A3, 0x00A5, 0x20A7, 0x0192,
	0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA,
	0x00BF, 0x2310, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
	0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556,
	0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
	0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F,
	0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
	0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B,
	0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
	0x03B1, 0x00DF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0x00B5, 0x03C4,
	0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x03B5, 0x2229,
	0x2261, 0x00B1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00F7, 0x2248,
	0x00B0, 0x2219, 0x00B7, 0x221A, 0x207F, 0x00B2, 0x25A0, 0x00A0
};

bool
of_unicode_to_codepage_437(const of_unichar_t *input, uint8_t *output,
    size_t length, bool lossy)
{
	size_t i;

	for (i = 0; i < length; i++) {
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
			case 0xA2:
				output[i] = 0x9B;
				break;
			case 0xA3:
				output[i] = 0x9C;
				break;
			case 0xA5:
				output[i] = 0x9D;
				break;
			case 0x20A7:
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
			case 0x2310:
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
			case 0x2561:
				output[i] = 0xB5;
				break;
			case 0x2562:
				output[i] = 0xB6;
				break;
			case 0x2556:
				output[i] = 0xB7;
				break;
			case 0x2555:
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
			case 0x255C:
				output[i] = 0xBD;
				break;
			case 0x255B:
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
			case 0x255E:
				output[i] = 0xC6;
				break;
			case 0x255F:
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
			case 0x2567:
				output[i] = 0xCF;
				break;
			case 0x2568:
				output[i] = 0xD0;
				break;
			case 0x2564:
				output[i] = 0xD1;
				break;
			case 0x2565:
				output[i] = 0xD2;
				break;
			case 0x2559:
				output[i] = 0xD3;
				break;
			case 0x2558:
				output[i] = 0xD4;
				break;
			case 0x2552:
				output[i] = 0xD5;
				break;
			case 0x2553:
				output[i] = 0xD6;
				break;
			case 0x256B:
				output[i] = 0xD7;
				break;
			case 0x256A:
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
			case 0x258C:
				output[i] = 0xDD;
				break;
			case 0x2590:
				output[i] = 0xDE;
				break;
			case 0x2580:
				output[i] = 0xDF;
				break;
			case 0x3B1:
				output[i] = 0xE0;
				break;
			case 0xDF:
				output[i] = 0xE1;
				break;
			case 0x393:
				output[i] = 0xE2;
				break;
			case 0x3C0:
				output[i] = 0xE3;
				break;
			case 0x3A3:
				output[i] = 0xE4;
				break;
			case 0x3C3:
				output[i] = 0xE5;
				break;
			case 0xB5:
				output[i] = 0xE6;
				break;
			case 0x3C4:
				output[i] = 0xE7;
				break;
			case 0x3A6:
				output[i] = 0xE8;
				break;
			case 0x398:
				output[i] = 0xE9;
				break;
			case 0x3A9:
				output[i] = 0xEA;
				break;
			case 0x3B4:
				output[i] = 0xEB;
				break;
			case 0x221E:
				output[i] = 0xEC;
				break;
			case 0x3C6:
				output[i] = 0xED;
				break;
			case 0x3B5:
				output[i] = 0xEE;
				break;
			case 0x2229:
				output[i] = 0xEF;
				break;
			case 0x2261:
				output[i] = 0xF0;
				break;
			case 0xB1:
				output[i] = 0xF1;
				break;
			case 0x2265:
				output[i] = 0xF2;
				break;
			case 0x2264:
				output[i] = 0xF3;
				break;
			case 0x2320:
				output[i] = 0xF4;
				break;
			case 0x2321:
				output[i] = 0xF5;
				break;
			case 0xF7:
				output[i] = 0xF6;
				break;
			case 0x2248:
				output[i] = 0xF7;
				break;
			case 0xB0:
				output[i] = 0xF8;
				break;
			case 0x2219:
				output[i] = 0xF9;
				break;
			case 0xB7:
				output[i] = 0xFA;
				break;
			case 0x221A:
				output[i] = 0xFB;
				break;
			case 0x207F:
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
