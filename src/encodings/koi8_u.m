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

const of_char16_t of_koi8_u_table[] = {
	0x2500, 0x2502, 0x250C, 0x2510, 0x2514, 0x2518, 0x251C, 0x2524,
	0x252C, 0x2534, 0x253C, 0x2580, 0x2584, 0x2588, 0x258C, 0x2590,
	0x2591, 0x2592, 0x2593, 0x2320, 0x25A0, 0x2219, 0x221A, 0x2248,
	0x2264,	0x2265, 0x00A0, 0x2321, 0x00B0, 0x00B2, 0x00B7, 0x00F7,
	0x2550, 0x2551, 0x2552, 0x0451, 0x0454, 0x2554, 0x0456, 0x0457,
	0x2557, 0x2558, 0x2559, 0x255A, 0x255B, 0x0491, 0x255D, 0x255E,
	0x255F, 0x2560, 0x2561, 0x0401, 0x0404, 0x2563, 0x0406, 0x0407,
	0x2566, 0x2567, 0x2568, 0x2569, 0x256A, 0x0490, 0x256C, 0x00A9,
	0x044E, 0x0430, 0x0431, 0x0446, 0x0434, 0x0435, 0x0444, 0x0433,
	0x0445, 0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E,
	0x043F, 0x044F, 0x0440, 0x0441, 0x0442, 0x0443, 0x0436, 0x0432,
	0x044C, 0x044B, 0x0437, 0x0448, 0x044D, 0x0449, 0x0447, 0x044A,
	0x042E, 0x0410, 0x0411, 0x0426, 0x0414, 0x0415, 0x0424, 0x0413,
	0x0425, 0x0418, 0x0419, 0x041A, 0x041B, 0x041C, 0x041D, 0x041E,
	0x041F, 0x042F, 0x0420, 0x0421, 0x0422, 0x0423, 0x0416, 0x0412,
	0x042C, 0x042B, 0x0417, 0x0428, 0x042D, 0x0429, 0x0427, 0x042A
};
const size_t of_koi8_u_table_offset =
    256 - (sizeof(of_koi8_u_table) / sizeof(*of_koi8_u_table));

bool
of_unicode_to_koi8_u(const of_unichar_t *input, unsigned char *output,
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

			if OF_LIKELY (c >= 0x438 && c <= 0x43F)
				output[i] = 0xC9 + (c - 0x438);
			else if OF_LIKELY (c >= 0x418 && c <= 0x41F)
				output[i] = 0xE9 + (c - 0x418);
			else {
				switch ((of_char16_t)c) {
				case 0x2500:
					output[i] = 0x80;
					break;
				case 0x2502:
					output[i] = 0x81;
					break;
				case 0x250C:
					output[i] = 0x82;
					break;
				case 0x2510:
					output[i] = 0x83;
					break;
				case 0x2514:
					output[i] = 0x84;
					break;
				case 0x2518:
					output[i] = 0x85;
					break;
				case 0x251C:
					output[i] = 0x86;
					break;
				case 0x2524:
					output[i] = 0x87;
					break;
				case 0x252C:
					output[i] = 0x88;
					break;
				case 0x2534:
					output[i] = 0x89;
					break;
				case 0x253C:
					output[i] = 0x8A;
					break;
				case 0x2580:
					output[i] = 0x8B;
					break;
				case 0x2584:
					output[i] = 0x8C;
					break;
				case 0x2588:
					output[i] = 0x8D;
					break;
				case 0x258C:
					output[i] = 0x8E;
					break;
				case 0x2590:
					output[i] = 0x8F;
					break;
				case 0x2591:
					output[i] = 0x90;
					break;
				case 0x2592:
					output[i] = 0x91;
					break;
				case 0x2593:
					output[i] = 0x92;
					break;
				case 0x2320:
					output[i] = 0x93;
					break;
				case 0x25A0:
					output[i] = 0x94;
					break;
				case 0x2219:
					output[i] = 0x95;
					break;
				case 0x221A:
					output[i] = 0x96;
					break;
				case 0x2248:
					output[i] = 0x97;
					break;
				case 0x2264:
					output[i] = 0x98;
					break;
				case 0x2265:
					output[i] = 0x99;
					break;
				case 0xA0:
					output[i] = 0x9A;
					break;
				case 0x2321:
					output[i] = 0x9B;
					break;
				case 0xB0:
					output[i] = 0x9C;
					break;
				case 0xB2:
					output[i] = 0x9D;
					break;
				case 0xB7:
					output[i] = 0x9E;
					break;
				case 0xF7:
					output[i] = 0x9F;
					break;
				case 0x2550:
					output[i] = 0xA0;
					break;
				case 0x2551:
					output[i] = 0xA1;
					break;
				case 0x2552:
					output[i] = 0xA2;
					break;
				case 0x451:
					output[i] = 0xA3;
					break;
				case 0x454:
					output[i] = 0xA4;
					break;
				case 0x2554:
					output[i] = 0xA5;
					break;
				case 0x456:
					output[i] = 0xA6;
					break;
				case 0x457:
					output[i] = 0xA7;
					break;
				case 0x2557:
					output[i] = 0xA8;
					break;
				case 0x2558:
					output[i] = 0xA9;
					break;
				case 0x2559:
					output[i] = 0xAA;
					break;
				case 0x255A:
					output[i] = 0xAB;
					break;
				case 0x255B:
					output[i] = 0xAC;
					break;
				case 0x491:
					output[i] = 0xAD;
					break;
				case 0x255D:
					output[i] = 0xAE;
					break;
				case 0x255E:
					output[i] = 0xAF;
					break;
				case 0x255F:
					output[i] = 0xB0;
					break;
				case 0x2560:
					output[i] = 0xB1;
					break;
				case 0x2561:
					output[i] = 0xB2;
					break;
				case 0x401:
					output[i] = 0xB3;
					break;
				case 0x404:
					output[i] = 0xB4;
					break;
				case 0x2563:
					output[i] = 0xB5;
					break;
				case 0x406:
					output[i] = 0xB6;
					break;
				case 0x407:
					output[i] = 0xB7;
					break;
				case 0x2566:
					output[i] = 0xB8;
					break;
				case 0x2567:
					output[i] = 0xB9;
					break;
				case 0x2568:
					output[i] = 0xBA;
					break;
				case 0x2569:
					output[i] = 0xBB;
					break;
				case 0x256A:
					output[i] = 0xBC;
					break;
				case 0x490:
					output[i] = 0xBD;
					break;
				case 0x256C:
					output[i] = 0xBE;
					break;
				case 0xA9:
					output[i] = 0xBF;
					break;
				case 0x44E:
					output[i] = 0xC0;
					break;
				case 0x430:
					output[i] = 0xC1;
					break;
				case 0x431:
					output[i] = 0xC2;
					break;
				case 0x446:
					output[i] = 0xC3;
					break;
				case 0x434:
					output[i] = 0xC4;
					break;
				case 0x435:
					output[i] = 0xC5;
					break;
				case 0x444:
					output[i] = 0xC6;
					break;
				case 0x433:
					output[i] = 0xC7;
					break;
				case 0x445:
					output[i] = 0xC8;
					break;
				case 0x44F:
					output[i] = 0xD1;
					break;
				case 0x440:
					output[i] = 0xD2;
					break;
				case 0x441:
					output[i] = 0xD3;
					break;
				case 0x442:
					output[i] = 0xD4;
					break;
				case 0x443:
					output[i] = 0xD5;
					break;
				case 0x436:
					output[i] = 0xD6;
					break;
				case 0x432:
					output[i] = 0xD7;
					break;
				case 0x44C:
					output[i] = 0xD8;
					break;
				case 0x44B:
					output[i] = 0xD9;
					break;
				case 0x437:
					output[i] = 0xDA;
					break;
				case 0x448:
					output[i] = 0xDB;
					break;
				case 0x44D:
					output[i] = 0xDC;
					break;
				case 0x449:
					output[i] = 0xDD;
					break;
				case 0x447:
					output[i] = 0xDE;
					break;
				case 0x44A:
					output[i] = 0xDF;
					break;
				case 0x42E:
					output[i] = 0xE0;
					break;
				case 0x410:
					output[i] = 0xE1;
					break;
				case 0x411:
					output[i] = 0xE2;
					break;
				case 0x426:
					output[i] = 0xE3;
					break;
				case 0x414:
					output[i] = 0xE4;
					break;
				case 0x415:
					output[i] = 0xE5;
					break;
				case 0x424:
					output[i] = 0xE6;
					break;
				case 0x413:
					output[i] = 0xE7;
					break;
				case 0x425:
					output[i] = 0xE8;
					break;
				case 0x42F:
					output[i] = 0xF1;
					break;
				case 0x420:
					output[i] = 0xF2;
					break;
				case 0x421:
					output[i] = 0xF3;
					break;
				case 0x422:
					output[i] = 0xF4;
					break;
				case 0x423:
					output[i] = 0xF5;
					break;
				case 0x416:
					output[i] = 0xF6;
					break;
				case 0x412:
					output[i] = 0xF7;
					break;
				case 0x42C:
					output[i] = 0xF8;
					break;
				case 0x42B:
					output[i] = 0xF9;
					break;
				case 0x417:
					output[i] = 0xFA;
					break;
				case 0x428:
					output[i] = 0xFB;
					break;
				case 0x42D:
					output[i] = 0xFC;
					break;
				case 0x429:
					output[i] = 0xFD;
					break;
				case 0x427:
					output[i] = 0xFE;
					break;
				case 0x42A:
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
