/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#ifdef OF_BIG_ENDIAN
static inline void
OF_BSWAP_V(uint8_t *buf, size_t len)
{
	uint32_t t;

	while (len--) {
		t = (uint32_t)((uint32_t)buf[3] << 8 | buf[2]) << 16 |
		    ((uint32_t)buf[1] << 8 | buf[0]);
		*(uint32_t*)buf = t;
		buf += sizeof(t);
	}
}
#else
#define OF_BSWAP_V(buf, len)
#endif

#define OF_ROL(val, bits) \
	(((val) << (bits)) | ((val) >> (32 - (bits))))
