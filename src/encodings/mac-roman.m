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

#import "OFString.h"

#import "common.h"

const OFChar16 _OFMacRomanTable[] OF_VISIBILITY_INTERNAL = {
	0x00C4, 0x00C5, 0x00C7, 0x00C9, 0x00D1, 0x00D6, 0x00DC, 0x00E1,
	0x00E0, 0x00E2, 0x00E4, 0x00E3, 0x00E5, 0x00E7, 0x00E9, 0x00E8,
	0x00EA, 0x00EB, 0x00ED, 0x00EC, 0x00EE, 0x00EF, 0x00F1, 0x00F3,
	0x00F2, 0x00F4, 0x00F6, 0x00F5, 0x00FA, 0x00F9, 0x00FB, 0x00FC,
	0x2020, 0x00B0, 0x00A2, 0x00A3, 0x00A7, 0x2022, 0x00B6, 0x00DF,
	0x00AE, 0x00A9, 0x2122, 0x00B4, 0x00A8, 0x2260, 0x00C6, 0x00D8,
	0x221E, 0x00B1, 0x2264, 0x2265, 0x00A5, 0x00B5, 0x2202, 0x2211,
	0x220F, 0x03C0, 0x222B, 0x00AA, 0x00BA, 0x03A9, 0x00E6, 0x00F8,
	0x00BF, 0x00A1, 0x00AC, 0x221A, 0x0192, 0x2248, 0x2206, 0x00AB,
	0x00BB, 0x2026, 0x00A0, 0x00C0, 0x00C3, 0x00D5, 0x0152, 0x0153,
	0x2013, 0x2014, 0x201C, 0x201D, 0x2018, 0x2019, 0x00F7, 0x25CA,
	0x00FF, 0x0178, 0x2044, 0x20AC, 0x2039, 0x203A, 0xFB01, 0xFB02,
	0x2021, 0x00B7, 0x201A, 0x201E, 0x2030, 0x00C2, 0x00CA, 0x00C1,
	0x00CB, 0x00C8, 0x00CD, 0x00CE, 0x00CF, 0x00CC, 0x00D3, 0x00D4,
	0xF8FF, 0x00D2, 0x00DA, 0x00DB, 0x00D9, 0x0131, 0x02C6, 0x02DC,
	0x00AF, 0x02D8, 0x02D9, 0x02DA, 0x00B8, 0x02DD, 0x02DB, 0x02C7
};
const size_t _OFMacRomanTableOffset OF_VISIBILITY_INTERNAL =
    256 - (sizeof(_OFMacRomanTable) / sizeof(*_OFMacRomanTable));

static const unsigned char page0[] = {
	0xCA, 0xC1, 0xA2, 0xA3, 0x00, 0xB4, 0x00, 0xA4,
	0xAC, 0xA9, 0xBB, 0xC7, 0xC2, 0x00, 0xA8, 0xF8,
	0xA1, 0xB1, 0x00, 0x00, 0xAB, 0xB5, 0xA6, 0xE1,
	0xFC, 0x00, 0xBC, 0xC8, 0x00, 0x00, 0x00, 0xC0,
	0xCB, 0xE7, 0xE5, 0xCC, 0x80, 0x81, 0xAE, 0x82,
	0xE9, 0x83, 0xE6, 0xE8, 0xED, 0xEA, 0xEB, 0xEC,
	0x00, 0x84, 0xF1, 0xEE, 0xEF, 0xCD, 0x85, 0x00,
	0xAF, 0xF4, 0xF2, 0xF3, 0x86, 0x00, 0x00, 0xA7,
	0x88, 0x87, 0x89, 0x8B, 0x8A, 0x8C, 0xBE, 0x8D,
	0x8F, 0x8E, 0x90, 0x91, 0x93, 0x92, 0x94, 0x95,
	0x00, 0x96, 0x98, 0x97, 0x99, 0x9B, 0x9A, 0xD6,
	0xBF, 0x9D, 0x9C, 0x9E, 0x9F, 0x00, 0x00, 0xD8
};
static const uint8_t page0Start = 0xA0;

static const unsigned char page1[] = {
	0xF5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0xCE, 0xCF, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xD9,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0xC4
};
static const uint8_t page1Start = 0x31;

static const unsigned char page2[] = {
	0xF6, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0xF9, 0xFA, 0xFB, 0xFE, 0xF7, 0xFD
};
static const uint8_t page2Start = 0xC6;

static const unsigned char page3[] = {
	0xBD, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xB9
};
static const uint8_t page3Start = 0xA9;

static const unsigned char page20[] = {
	0xD0, 0xD1, 0x00, 0x00, 0x00, 0xD4, 0xD5, 0xE2,
	0x00, 0xD2, 0xD3, 0xE3, 0x00, 0xA0, 0xE0, 0xA5,
	0x00, 0x00, 0x00, 0xC9, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0xE4, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xDC, 0xDD,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0xDA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0xDB
};
static const uint8_t page20Start = 0x13;

static const unsigned char page21[] = {
	0xAA
};
static const uint8_t page21Start = 0x22;

static const unsigned char page22[] = {
	0xB6, 0x00, 0x00, 0x00, 0xC6, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0xB8, 0x00, 0xB7,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0xC3, 0x00, 0x00, 0x00, 0xB0, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC5, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAD, 0x00,
	0x00, 0x00, 0xB2, 0xB3
};
static const uint8_t page22Start = 0x02;

static const unsigned char page25[] = {
	0xD7
};
static const uint8_t page25Start = 0xCA;

static const unsigned char pageF8[] = {
	0xF0
};
static const uint8_t pageF8Start = 0xFF;

static const unsigned char pageFB[] = {
	0xDE, 0xDF
};
static const uint8_t pageFBStart = 0x01;

bool OF_VISIBILITY_INTERNAL
_OFUnicodeToMacRoman(const OFUnichar *input, unsigned char *output,
    size_t length, bool lossy, bool insecure)
{
	for (size_t i = 0; i < length; i++) {
		OFUnichar c;

		if OF_UNLIKELY (!insecure && input[i] == 0)
			return false;

		c = input[i];

		if OF_UNLIKELY (c > 0x7F) {
			uint8_t idx;

			if OF_UNLIKELY (c > 0xFFFF) {
				if (lossy) {
					output[i] = '?';
					continue;
				} else
					return false;
			}

			switch (c >> 8) {
			CASE_MISSING_IS_ERROR(0)
			CASE_MISSING_IS_ERROR(1)
			CASE_MISSING_IS_ERROR(2)
			CASE_MISSING_IS_ERROR(3)
			CASE_MISSING_IS_ERROR(20)
			CASE_MISSING_IS_ERROR(21)
			CASE_MISSING_IS_ERROR(22)
			CASE_MISSING_IS_ERROR(25)
			CASE_MISSING_IS_ERROR(F8)
			CASE_MISSING_IS_ERROR(FB)
			default:
				if (lossy) {
					output[i] = '?';
					continue;
				} else
					return false;
			}
		} else
			output[i] = (unsigned char)c;
	}

	return true;
}
