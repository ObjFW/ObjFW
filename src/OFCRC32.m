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

#import "OFCRC32.h"

static const uint32_t CRC32Magic = 0xEDB88320;

uint32_t
_OFCRC32(uint32_t CRC, const void *bytes_, size_t length)
{
	const unsigned char *bytes = bytes_;

	for (size_t i = 0; i < length; i++) {
		CRC ^= bytes[i];

		for (uint8_t j = 0; j < 8; j++)
			CRC = (CRC >> 1) ^ (CRC32Magic & (~(CRC & 1) + 1));
	}

	return CRC;
}
