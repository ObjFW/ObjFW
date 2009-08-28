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

#ifndef OF_CONFIGURED
#error You are missing the libobjfw definitions!
#error Please use objfw-config!
#endif

#include <stdint.h>

#ifdef __GNUC__
#define OF_INLINE inline __attribute__((always_inline))
#define OF_LIKELY(cond) __builtin_expect(!!(cond), 1)
#define OF_UNLIKELY(cond) __builtin_expect(!!(cond), 0)
#else
#define OF_INLINE inline
#define OF_LIKELY(cond) cond
#define OF_UNLIKELY(cond) cond
#endif

#ifdef __GNUC__
#if defined(__amd64__) || defined(__x86_64__)
#define OF_AMD64_ASM
#elif defined(__i386__)
#define OF_X86_ASM
#endif
#endif

static OF_INLINE uint16_t
OF_BSWAP16(uint16_t i)
{
#if defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	asm("xchgb	%h0, %b0" : "=Q"(i) : "Q"(i));
#else
	i = (i & UINT16_C(0xFF00)) >> 8 |
	    (i & UINT16_C(0x00FF)) << 8;
#endif
	return i;
}

static OF_INLINE uint32_t
OF_BSWAP32(uint32_t i)
{
#if defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	asm("bswap	%0" : "=q"(i) : "q"(i));
#else
	i = (i & UINT32_C(0xFF000000)) >> 24 |
	    (i & UINT32_C(0x00FF0000)) >>  8 |
	    (i & UINT32_C(0x0000FF00)) <<  8 |
	    (i & UINT32_C(0x000000FF)) << 24;
#endif
	return i;
}

static OF_INLINE uint64_t
OF_BSWAP64(uint64_t i)
{
#if defined(OF_AMD64_ASM)
	asm("bswap	%0" : "=r"(i) : "r"(i));
#elif defined(OF_X86_ASM)
	asm("bswap	%%eax\n\t"
	    "bswap	%%edx\n\t"
	    "xchgl	%%eax, %%edx" : "=A"(i): "A"(i));
#else
	i = (i & UINT64_C(0xFF00000000000000)) >> 56 |
	    (i & UINT64_C(0x00FF000000000000)) >> 40 |
	    (i & UINT64_C(0x0000FF0000000000)) >> 24 |
	    (i & UINT64_C(0x000000FF00000000)) >>  8 |
	    (i & UINT64_C(0x00000000FF000000)) <<  8 |
	    (i & UINT64_C(0x0000000000FF0000)) << 24 |
	    (i & UINT64_C(0x000000000000FF00)) << 40 |
	    (i & UINT64_C(0x00000000000000FF)) << 56;
#endif
	return i;
}

static OF_INLINE void
OF_BSWAP32_V(uint32_t *buf, size_t len)
{
	while (len--) {
		*buf = OF_BSWAP32(*buf);
		buf++;
	}
}

#ifdef OF_BIG_ENDIAN
#define OF_BSWAP16_IF_BE(i) OF_BSWAP16(i)
#define OF_BSWAP32_IF_BE(i) OF_BSWAP32(i)
#define OF_BSWAP64_IF_BE(i) OF_BSWAP64(i)
#define OF_BSWAP16_IF_LE(i) i
#define OF_BSWAP32_IF_LE(i) i
#define OF_BSWAP64_IF_LE(i) i
#define OF_BSWAP32_V_IF_BE(buf, len) OF_BSWAP32_V(buf, len)
#else
#define OF_BSWAP16_IF_BE(i) i
#define OF_BSWAP32_IF_BE(i) i
#define OF_BSWAP64_IF_BE(i) i
#define OF_BSWAP16_IF_LE(i) OF_BSWAP16(i)
#define OF_BSWAP32_IF_LE(i) OF_BSWAP32(i)
#define OF_BSWAP64_IF_LE(i) OF_BSWAP64(i)
#define OF_BSWAP32_V_IF_BE(buf, len)
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
