/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "objfw-defs.h"

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stddef.h>
#include <stdint.h>

#ifdef _PSP
# define INTMAX_MAX LONG_LONG_MAX
#endif

#ifdef __GNUC__
# define OF_INLINE inline __attribute__((always_inline))
# define OF_LIKELY(cond) __builtin_expect(!!(cond), 1)
# define OF_UNLIKELY(cond) __builtin_expect(!!(cond), 0)
# define OF_CONST_FUNC __attribute__((const))
#else
# define OF_INLINE inline
# define OF_LIKELY(cond) cond
# define OF_UNLIKELY(cond) cond
# define OF_CONST_FUNC
#endif

/* Required to build universal binaries on OS X */
#if __BIG_ENDIAN__ || __LITTLE_ENDIAN__
# if __BIG_ENDIAN__ && __LITTLE_ENDIAN__
#  error __BIG_ENDIAN__ and __LITTLE_ENDIAN__ defined!
# endif
# undef OF_BIG_ENDIAN
# if __BIG_ENDIAN__
#  define OF_BIG_ENDIAN
# endif
#endif

#ifdef __GNUC__
# if defined(__amd64__) || defined(__x86_64__)
#  define OF_AMD64_ASM
# elif defined(__i386__)
#  define OF_X86_ASM
# elif defined(__ppc__) || defined(__PPC__)
#  define OF_PPC_ASM
# elif defined(__arm__) || defined(__ARM__)
#  define OF_ARM_ASM
# endif
#endif

#ifndef _WIN32
# define OF_PATH_DELIM '/'
#else
# define OF_PATH_DELIM '\\'
#endif

#define OF_IVAR_OFFSET(ivar) ((char*)&ivar - (char*)self)
#define OF_GETTER(ivar, atomic) \
	return objc_getProperty(self, _cmd, OF_IVAR_OFFSET(ivar), atomic);
#define OF_SETTER(ivar, value, atomic, copy) \
	objc_setProperty(self, _cmd, OF_IVAR_OFFSET(ivar), value, atomic, copy);

static OF_INLINE uint16_t OF_CONST_FUNC
of_bswap16_const(uint16_t i)
{
	return (i & UINT16_C(0xFF00)) >> 8 |
	    (i & UINT16_C(0x00FF)) << 8;
}

static OF_INLINE uint32_t OF_CONST_FUNC
of_bswap32_const(uint32_t i)
{
	return (i & UINT32_C(0xFF000000)) >> 24 |
	    (i & UINT32_C(0x00FF0000)) >>  8 |
	    (i & UINT32_C(0x0000FF00)) <<  8 |
	    (i & UINT32_C(0x000000FF)) << 24;
}

static OF_INLINE uint64_t OF_CONST_FUNC
of_bswap64_const(uint64_t i)
{
	return (i & UINT64_C(0xFF00000000000000)) >> 56 |
	    (i & UINT64_C(0x00FF000000000000)) >> 40 |
	    (i & UINT64_C(0x0000FF0000000000)) >> 24 |
	    (i & UINT64_C(0x000000FF00000000)) >>  8 |
	    (i & UINT64_C(0x00000000FF000000)) <<  8 |
	    (i & UINT64_C(0x0000000000FF0000)) << 24 |
	    (i & UINT64_C(0x000000000000FF00)) << 40 |
	    (i & UINT64_C(0x00000000000000FF)) << 56;
}

static OF_INLINE uint16_t OF_CONST_FUNC
of_bswap16_nonconst(uint16_t i)
{
#if defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "xchgb	%h0, %b0"
	    : "=Q"(i)
	    : "0"(i)
	);
#elif defined(OF_PPC_ASM)
	__asm__ (
	    "lhbrx	%0, 0, %1"
	    : "=r"(i)
	    : "r"(&i), "m"(i)
	);
#elif defined(OF_ARM_ASM)
	__asm__ (
	    "rev16	%0, %0"
	    : "=r"(i)
	    : "0"(i)
	);
#else
	i = (i & UINT16_C(0xFF00)) >> 8 |
	    (i & UINT16_C(0x00FF)) << 8;
#endif
	return i;
}

static OF_INLINE uint32_t OF_CONST_FUNC
of_bswap32_nonconst(uint32_t i)
{
#if defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "bswap	%0"
	    : "=q"(i)
	    : "0"(i)
	);
#elif defined(OF_PPC_ASM)
	__asm__ (
	    "lwbrx	%0, 0, %1"
	    : "=r"(i)
	    : "r"(&i), "m"(i)
	);
#elif defined(OF_ARM_ASM)
	__asm__ (
	    "rev	%0, %0"
	    : "=r"(i)
	    : "0"(i)
	);
#else
	i = (i & UINT32_C(0xFF000000)) >> 24 |
	    (i & UINT32_C(0x00FF0000)) >>  8 |
	    (i & UINT32_C(0x0000FF00)) <<  8 |
	    (i & UINT32_C(0x000000FF)) << 24;
#endif
	return i;
}

static OF_INLINE uint64_t OF_CONST_FUNC
of_bswap64_nonconst(uint64_t i)
{
#if defined(OF_AMD64_ASM)
	__asm__ (
	    "bswap	%0"
	    : "=r"(i)
	    : "0"(i)
	);
#elif defined(OF_X86_ASM)
	__asm__ (
	    "bswap	%%eax\n\t"
	    "bswap	%%edx\n\t"
	    "xchgl	%%eax, %%edx"
	    : "=A"(i)
	    : "0"(i)
	);
#else
	i = (uint64_t)of_bswap32_nonconst(i & 0xFFFFFFFF) << 32 |
	    of_bswap32_nonconst(i >> 32);
#endif
	return i;
}

#ifdef __GNUC__
# define of_bswap16(i) \
	(__builtin_constant_p(i) ? of_bswap16_const(i) : of_bswap16_nonconst(i))
# define of_bswap32(i) \
	(__builtin_constant_p(i) ? of_bswap32_const(i) : of_bswap32_nonconst(i))
# define of_bswap64(i) \
	(__builtin_constant_p(i) ? of_bswap64_const(i) : of_bswap64_nonconst(i))
#else
# define of_bswap16(i) of_bswap16_const(i)
# define of_bswap32(i) of_bswap32_const(i)
# define of_bswap64(i) of_bswap64_const(i)
#endif

static OF_INLINE void
of_bswap32_vec(uint32_t *buffer, size_t length)
{
	while (length--) {
		*buffer = of_bswap32(*buffer);
		buffer++;
	}
}

#ifdef OF_BIG_ENDIAN
# define of_bswap16_if_be(i) of_bswap16(i)
# define of_bswap32_if_be(i) of_bswap32(i)
# define of_bswap64_if_be(i) of_bswap64(i)
# define of_bswap16_if_le(i) (i)
# define of_bswap32_if_le(i) (i)
# define of_bswap64_if_le(i) (i)
# define of_bswap32_vec_if_be(buffer, length) of_bswap32_vec(buffer, length)
#else
# define of_bswap16_if_be(i) (i)
# define of_bswap32_if_be(i) (i)
# define of_bswap64_if_be(i) (i)
# define of_bswap16_if_le(i) of_bswap16(i)
# define of_bswap32_if_le(i) of_bswap32(i)
# define of_bswap64_if_le(i) of_bswap64(i)
# define of_bswap32_vec_if_be(buffer, length)
#endif

#define OF_ROL(value, bits)						\
	(((value) << ((bits) % (sizeof(value) * 8))) |			\
	(value) >> (sizeof(value) * 8 - ((bits) % (sizeof(value) * 8))))

#define OF_HASH_INIT(hash) hash = 0
#define OF_HASH_ADD(hash, byte)		\
	{				\
		hash += (uint8_t)byte;	\
		hash += (hash << 10);	\
		hash ^= (hash >> 6);	\
	}
#define OF_HASH_FINALIZE(hash)		\
	{				\
		hash += (hash << 3);	\
		hash ^= (hash >> 11);	\
		hash += (hash << 15);	\
	}
