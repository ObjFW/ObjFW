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

#import "crc32.h"

#define CRC32_MAGIC 0xEDB88320

uint32_t
of_crc32(uint32_t crc, const unsigned char *bytes, size_t length)
{
	for (size_t i = 0; i < length; i++) {
		crc ^= bytes[i];

		for (uint8_t j = 0; j < 8; j++)
			crc = (crc >> 1) ^ (CRC32_MAGIC & (~(crc & 1) + 1));
	}

	return crc;
}
