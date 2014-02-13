/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFObject.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(OF_APPLE_RUNTIME)
# import <objc/runtime.h>
#endif

#ifdef __GNUC__
# define OF_INLINE inline __attribute__((always_inline))
# define OF_LIKELY(cond) (__builtin_expect(!!(cond), 1))
# define OF_UNLIKELY(cond) (__builtin_expect(!!(cond), 0))
# define OF_CONST_FUNC __attribute__((const))
#else
# define OF_INLINE inline
# define OF_LIKELY(cond) cond
# define OF_UNLIKELY(cond) cond
# define OF_CONST_FUNC
#endif

/* Required to build universal binaries on OS X */
#ifdef OF_UNIVERSAL
# if __BIG_ENDIAN__
#  define OF_BIG_ENDIAN
#  define OF_FLOAT_BIG_ENDIAN
# elif !__LITTLE_ENDIAN__
#  error OF_UNIVERSAL defined, but neither __BIG_ENDIAN__ nor __LITTLE_ENDIAN__!
# endif
#endif

#ifdef OF_BIG_ENDIAN
# define OF_BYTE_ORDER_NATIVE OF_BYTE_ORDER_BIG_ENDIAN
#else
# define OF_BYTE_ORDER_NATIVE OF_BYTE_ORDER_LITTLE_ENDIAN
#endif

#if __STDC_VERSION__ >= 201112L && defined(OF_HAVE_MAX_ALIGN_T)
# define OF_BIGGEST_ALIGNMENT _Alignof(max_align_t)
#else
# ifdef __BIGGEST_ALIGNMENT__
#  define OF_BIGGEST_ALIGNMENT __BIGGEST_ALIGNMENT__
# else
#  /* Hopefully no arch needs more than 16 bytes padding */
#  define OF_BIGGEST_ALIGNMENT 16
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
#  ifdef __ARM_ARCH_7__
#   define OF_ARMV7_ASM
#  endif
#  ifdef __ARM_ARCH_7A__
#   define OF_ARMV7_ASM
#  endif
#  ifdef __ARM_ARCH_7R__
#   define OF_ARMV7_ASM
#  endif
#  ifdef __ARM_ARCH_7M__
#   define OF_ARMV7_ASM
#  endif
#  ifdef __ARM_ARCH_7EM__
#   define OF_ARMV7_ASM
#  endif
#  ifdef __ARM_ARCH_6__
#   define OF_ARMV6_ASM
#  endif
#  ifdef __ARM_ARCH_6J__
#   define OF_ARMV6_ASM
#  endif
#  ifdef __ARM_ARCH_6K__
#   define OF_ARMV6_ASM
#  endif
#  ifdef __ARM_ARCH_6Z__
#   define OF_ARMV6_ASM
#  endif
#  ifdef __ARM_ARCH_6ZK__
#   define OF_ARMV6_ASM
#  endif
#  ifdef __ARM_ARCH_6T2__
#   define OF_ARMV6_ASM
#  endif
#  ifdef OF_ARMV7_ASM
#   define OF_ARMV6_ASM
#  endif
# endif
#endif

#define OF_ENSURE(cond)							\
	if (!(cond)) {							\
		fprintf(stderr, "Failed to ensure condition in "	\
		    __FILE__ ":%d:\n" #cond "\n", __LINE__);		\
		abort();						\
	}

#if __STDC_VERSION__ >= 201112L
# /* C11 compiler, but old libc */
# ifndef static_assert
#  define static_assert _Static_assert
# endif
#else
# define static_assert assert
#endif

#if !defined(_WIN32) && !defined(__DJGPP__)
# define OF_PATH_DELIMITER '/'
# define OF_PATH_DELIMITER_STRING @"/"
# define OF_IS_PATH_DELIMITER(c) (c == '/')
#else
# define OF_PATH_DELIMITER '\\'
# define OF_PATH_DELIMITER_STRING @"\\"
# define OF_IS_PATH_DELIMITER(c) (c == '\\' || c == '/')
#endif
#define OF_PATH_CURRENT_DIRECTORY @"."
#define OF_PATH_PARENT_DIRECTORY @".."

extern id objc_getProperty(id, SEL, ptrdiff_t, BOOL);
extern void objc_setProperty(id, SEL, ptrdiff_t, id, BOOL, signed char);

#define OF_IVAR_OFFSET(ivar) ((intptr_t)&ivar - (intptr_t)self)
#define OF_GETTER(ivar, atomic) \
	return objc_getProperty(self, _cmd, OF_IVAR_OFFSET(ivar), atomic);
#define OF_SETTER(ivar, value, atomic, copy) \
	objc_setProperty(self, _cmd, OF_IVAR_OFFSET(ivar), value, atomic, copy);

#define OF_UNRECOGNIZED_SELECTOR		\
	[self doesNotRecognizeSelector: _cmd];	\
	abort();
#define OF_INVALID_INIT_METHOD				\
	@try {						\
		[self doesNotRecognizeSelector: _cmd];	\
	} @catch (id e) {				\
		[self release];				\
		@throw e;				\
	}						\
							\
	abort();

#ifdef OF_HAVE_CLASS_EXTENSIONS
# define OF_PRIVATE_CATEGORY
#else
# define OF_PRIVATE_CATEGORY Private
#endif

static OF_INLINE uint16_t OF_CONST_FUNC
OF_BSWAP16_CONST(uint16_t i)
{
	return (i & UINT16_C(0xFF00)) >> 8 |
	    (i & UINT16_C(0x00FF)) << 8;
}

static OF_INLINE uint32_t OF_CONST_FUNC
OF_BSWAP32_CONST(uint32_t i)
{
	return (i & UINT32_C(0xFF000000)) >> 24 |
	    (i & UINT32_C(0x00FF0000)) >>  8 |
	    (i & UINT32_C(0x0000FF00)) <<  8 |
	    (i & UINT32_C(0x000000FF)) << 24;
}

static OF_INLINE uint64_t OF_CONST_FUNC
OF_BSWAP64_CONST(uint64_t i)
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
OF_BSWAP16_NONCONST(uint16_t i)
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
#elif defined(OF_ARMV6_ASM)
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
OF_BSWAP32_NONCONST(uint32_t i)
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
#elif defined(OF_ARMV6_ASM)
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
OF_BSWAP64_NONCONST(uint64_t i)
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
	i = (uint64_t)OF_BSWAP32_NONCONST((uint32_t)(i & 0xFFFFFFFF)) << 32 |
	    OF_BSWAP32_NONCONST((uint32_t)(i >> 32));
#endif
	return i;
}

#ifdef __GNUC__
# define OF_BSWAP16(i) \
	(__builtin_constant_p(i) ? OF_BSWAP16_CONST(i) : OF_BSWAP16_NONCONST(i))
# define OF_BSWAP32(i) \
	(__builtin_constant_p(i) ? OF_BSWAP32_CONST(i) : OF_BSWAP32_NONCONST(i))
# define OF_BSWAP64(i) \
	(__builtin_constant_p(i) ? OF_BSWAP64_CONST(i) : OF_BSWAP64_NONCONST(i))
#else
# define OF_BSWAP16(i) OF_BSWAP16_CONST(i)
# define OF_BSWAP32(i) OF_BSWAP32_CONST(i)
# define OF_BSWAP64(i) OF_BSWAP64_CONST(i)
#endif

static OF_INLINE float OF_CONST_FUNC
OF_BSWAP_FLOAT(float f)
{
	union {
		float f;
		uint32_t i;
	} u;

	u.f = f;
	u.i = OF_BSWAP32(u.i);

	return u.f;
}

static OF_INLINE double OF_CONST_FUNC
OF_BSWAP_DOUBLE(double d)
{
	union {
		double d;
		uint64_t i;
	} u;

	u.d = d;
	u.i = OF_BSWAP64(u.i);

	return u.d;
}

#ifdef OF_BIG_ENDIAN
# define OF_BSWAP16_IF_BE(i) OF_BSWAP16(i)
# define OF_BSWAP32_IF_BE(i) OF_BSWAP32(i)
# define OF_BSWAP64_IF_BE(i) OF_BSWAP64(i)
# define OF_BSWAP16_IF_LE(i) (i)
# define OF_BSWAP32_IF_LE(i) (i)
# define OF_BSWAP64_IF_LE(i) (i)
#else
# define OF_BSWAP16_IF_BE(i) (i)
# define OF_BSWAP32_IF_BE(i) (i)
# define OF_BSWAP64_IF_BE(i) (i)
# define OF_BSWAP16_IF_LE(i) OF_BSWAP16(i)
# define OF_BSWAP32_IF_LE(i) OF_BSWAP32(i)
# define OF_BSWAP64_IF_LE(i) OF_BSWAP64(i)
#endif

#ifdef OF_FLOAT_BIG_ENDIAN
# define OF_BSWAP_FLOAT_IF_BE(i) OF_BSWAP_FLOAT(i)
# define OF_BSWAP_DOUBLE_IF_BE(i) OF_BSWAP_DOUBLE(i)
# define OF_BSWAP_FLOAT_IF_LE(i) (i)
# define OF_BSWAP_DOUBLE_IF_LE(i) (i)
#else
# define OF_BSWAP_FLOAT_IF_BE(i) (i)
# define OF_BSWAP_DOUBLE_IF_BE(i) (i)
# define OF_BSWAP_FLOAT_IF_LE(i) OF_BSWAP_FLOAT(i)
# define OF_BSWAP_DOUBLE_IF_LE(i) OF_BSWAP_DOUBLE(i)
#endif

#define OF_ROL(value, bits)						   \
	(((value) << ((bits) % (sizeof(value) * 8))) |			   \
	((value) >> (sizeof(value) * 8 - ((bits) % (sizeof(value) * 8)))))
#define OF_ROR(value, bits)						   \
	(((value) >> ((bits) % (sizeof(value) * 8))) |			   \
	((value) << (sizeof(value) * 8 - ((bits) % (sizeof(value) * 8)))))

#define OF_HASH_INIT(hash) hash = of_hash_seed;
#define OF_HASH_ADD(hash, byte)			\
	{					\
		hash += (uint8_t)(byte);	\
		hash += (hash << 10);		\
		hash ^= (hash >> 6);		\
	}
#define OF_HASH_FINALIZE(hash)		\
	{				\
		hash += (hash << 3);	\
		hash ^= (hash >> 11);	\
		hash += (hash << 15);	\
	}
#define OF_HASH_ADD_HASH(hash, other)				\
	{							\
		uint32_t otherCopy = other;			\
		OF_HASH_ADD(hash, (otherCopy >> 24) & 0xFF);	\
		OF_HASH_ADD(hash, (otherCopy >> 16) & 0xFF);	\
		OF_HASH_ADD(hash, (otherCopy >>  8) & 0xFF);	\
		OF_HASH_ADD(hash, otherCopy & 0xFF);		\
	}

static OF_INLINE of_range_t
of_range(size_t start, size_t length)
{
	of_range_t range = { start, length };

	return range;
}

static OF_INLINE of_point_t
of_point(float x, float y)
{
	of_point_t point = { x, y };

	return point;
}

static OF_INLINE of_dimension_t
of_dimension(float width, float height)
{
	of_dimension_t dimension = { width, height };

	return dimension;
}

static OF_INLINE of_rectangle_t
of_rectangle(float x, float y, float width, float height)
{
	of_rectangle_t rectangle = {
		of_point(x, y),
		of_dimension(width, height)
	};

	return rectangle;
}

static OF_INLINE char*
of_strdup(const char *string)
{
	char *copy;
	size_t length = strlen(string);

	if ((copy = malloc(length + 1)) == NULL)
		return NULL;

	memcpy(copy, string, length + 1);

	return copy;
}
