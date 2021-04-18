/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFCRC16.h"

#define CRC16_MAGIC 0xA001

uint16_t
OFCRC16(uint16_t crc, const void *bytes_, size_t length)
{
	const unsigned char *bytes = bytes_;

	for (size_t i = 0; i < length; i++) {
		crc ^= bytes[i];

		for (uint8_t j = 0; j < 8; j++)
			crc = (crc >> 1) ^ (CRC16_MAGIC & (~(crc & 1) + 1));
	}

	return crc;
}
