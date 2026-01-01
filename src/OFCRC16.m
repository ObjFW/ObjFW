/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFCRC16.h"
#import "OFObject.h"
#import "OFOnce.h"

static const uint16_t CRC16Magic = 0xA001;
static uint16_t *CRC16Table = NULL;

static void
initCRC16Table(void)
{
	uint16_t CRC = 1;

	CRC16Table = OFAllocZeroedMemory(256, sizeof(uint16_t));

	for (size_t i = 128; i > 0; i >>= 1) {
		CRC = (CRC >> 1) ^ (CRC16Magic & (~(CRC & 1) + 1));

		for (size_t j = 0; j < 256; j += i << 1)
			CRC16Table[i + j] = CRC ^ CRC16Table[j];
	}
}

uint16_t
_OFCRC16(uint16_t CRC, const void *bytes_, size_t length)
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	const unsigned char *bytes = bytes_;

	OFOnce(&onceControl, initCRC16Table);

	for (size_t i = 0; i < length; i++) {
		CRC ^= bytes[i];
		CRC = (CRC >> 8) ^ CRC16Table[CRC & 0xFF];
	}

	return CRC;
}
