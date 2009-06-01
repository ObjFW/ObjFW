/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#ifdef __GNUC__
#define OF_INLINE inline __attribute__((always_inline))
#define OF_LIKELY(cond) __builtin_expect(!!(cond), 1)
#define OF_UNLIKELY(cond) __builtin_expect(!!(cond), 0)
#else
#define OF_INLINE inline
#define OF_LIKELY(cond) cond
#define OF_UNLIKELY(cond) cond
#endif

#if defined(OF_BIG_ENDIAN)
static OF_INLINE void
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
#elif defined(OF_LITTLE_ENDIAN)
#define OF_BSWAP_V(buf, len)
#else
#error Please define either OF_BIG_ENDIAN or OF_LITTLE_ENDIAN!
#endif

#define OF_ROL(val, bits) \
	(((val) << (bits)) | ((val) >> (32 - (bits))))

#define OF_HASH_INIT(hash) hash = 0
#define OF_HASH_ADD(hash, byte)		\
	{				\
		hash += byte;		\
		hash += (hash << 10);	\
		hash ^= (hash >> 6);	\
	}
#define OF_HASH_FINALIZE(hash)		\
	{				\
		hash += (hash << 3);	\
		hash ^= (hash >> 11);	\
		hash += (hash << 15);	\
	}
