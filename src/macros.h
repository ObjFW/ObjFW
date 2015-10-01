/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef OF_OBJFW_RUNTIME
# import "runtime.h"
#endif
#ifdef OF_APPLE_RUNTIME
# import <objc/objc.h>
# import <objc/runtime.h>
# import <objc/message.h>
#endif

#if defined(__GNUC__)
# define restrict __restrict__
#elif __STDC_VERSION__ < 199901L
# define restrict
#endif

#if __STDC_VERSION__ >= 201112L && !defined(static_assert)
/* C11 compiler, but old libc */
# define static_assert _Static_assert
#endif

#if defined(OF_HAVE__THREAD_LOCAL)
# define OF_HAVE_COMPILER_TLS
# ifdef OF_HAVE_THREADS_H
#  include <threads.h>
# else
#  define thread_local _Thread_local
# endif
#elif defined(OF_HAVE___THREAD)
# define OF_HAVE_COMPILER_TLS
# define thread_local __thread
#endif

#ifdef __GNUC__
# define OF_INLINE inline __attribute__((__always_inline__))
# define OF_LIKELY(cond) (__builtin_expect(!!(cond), 1))
# define OF_UNLIKELY(cond) (__builtin_expect(!!(cond), 0))
# define OF_CONST_FUNC __attribute__((__const__))
# define OF_NO_RETURN_FUNC __attribute__((__noreturn__))
#else
# define OF_INLINE inline
# define OF_LIKELY(cond) cond
# define OF_UNLIKELY(cond) cond
# define OF_CONST_FUNC
# define OF_NO_RETURN_FUNC
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
#  /* Hopefully no arch needs more than 16 byte alignment */
#  define OF_BIGGEST_ALIGNMENT 16
# endif
#endif

#ifdef __GNUC__
# define __GCC_VERSION__ (__GNUC__ * 100 + __GNUC_MINOR__)
#else
# define __GCC_VERSION__ 0
#endif

#if defined(__clang__) || __GCC_VERSION__ >= 406 || defined(OBJC_NEW_PROPERTIES)
# define OF_HAVE_PROPERTIES
# define OF_HAVE_OPTIONAL_PROTOCOLS
# if defined(__clang__) || __GCC_VERSION__ >= 406 || defined(OF_APPLE_RUNTIME)
#  define OF_HAVE_FAST_ENUMERATION
# endif
# define OF_HAVE_CLASS_EXTENSIONS
# define OF_PRIVATE_CATEGORY
#else
# define OF_PRIVATE_CATEGORY Private
#endif

#ifndef __has_feature
# define __has_feature(x) 0
#endif

#ifndef __has_attribute
# define __has_attribute(x) 0
#endif

#if __has_feature(objc_bool)
# undef YES
# define YES __objc_yes
# undef NO
# define NO __objc_no
# ifndef __cplusplus
#  undef true
#  define true ((bool)1)
#  undef false
#  define false ((bool)0)
# endif
#endif

#if !__has_feature(objc_instancetype)
# define instancetype id
#endif

#if __has_feature(blocks)
# define OF_HAVE_BLOCKS
#endif

#if __has_feature(objc_arc)
# define OF_RETURNS_RETAINED __attribute__((__ns_returns_retained__))
# define OF_RETURNS_NOT_RETAINED __attribute__((__ns_returns_not_retained__))
# define OF_RETURNS_INNER_POINTER \
	__attribute__((__objc_returns_inner_pointer__))
# define OF_CONSUMED __attribute__((__ns_consumed__))
# define OF_WEAK_UNAVAILABLE __attribute__((__objc_arc_weak_unavailable__))
#else
# define OF_RETURNS_RETAINED
# define OF_RETURNS_NOT_RETAINED
# define OF_RETURNS_INNER_POINTER
# define OF_CONSUMED
# define OF_WEAK_UNAVAILABLE
# define __unsafe_unretained
# define __bridge
# define __autoreleasing
#endif

#if __has_feature(objc_generics)
# define OF_HAVE_GENERICS
# define OF_GENERIC(...) <__VA_ARGS__>
#else
# define OF_GENERIC(...)
#endif

#if __has_feature(nullability)
# define OF_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
# define OF_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
# define OF_NONNULL _Nonnull
# define OF_NULLABLE _Nullable
# define OF_NULLABLE_PROPERTY(...) (__VA_ARGS__, nullable)
#else
# define OF_ASSUME_NONNULL_BEGIN
# define OF_ASSUME_NONNULL_END
# define OF_NONNULL
# define OF_NULLABLE
# define OF_NULLABLE_PROPERTY
# define nonnull
# define nullable
#endif

#if __has_feature(objc_kindof)
# define OF_KINDOF(cls) __kindof cls
#else
# define OF_KINDOF(cls) id
#endif

#if defined(__clang__) || __GCC_VERSION__ >= 405
# define OF_UNREACHABLE __builtin_unreachable();
#else
# define OF_UNREACHABLE abort();
#endif

#if defined(__clang__) || __GCC_VERSION__ >= 406
# define OF_SENTINEL __attribute__((__sentinel__))
# define OF_NO_RETURN __attribute__((__noreturn__))
#else
# define OF_SENTINEL
# define OF_NO_RETURN
#endif

#if __has_attribute(__objc_requires_super__)
# define OF_REQUIRES_SUPER __attribute__((__objc_requires_super__))
#else
# define OF_REQUIRES_SUPER
#endif

#if __has_attribute(__objc_root_class__)
# define OF_ROOT_CLASS __attribute__((__objc_root_class__))
#else
# define OF_ROOT_CLASS
#endif

#if __has_attribute(__objc_subclassing_restricted__)
# define OF_SUBCLASSING_RESTRICTED \
	__attribute__((__objc_subclassing_restricted__))
#else
# define OF_SUBCLASSING_RESTRICTED
#endif

#ifdef __GNUC__
# if defined(__x86_64__) || defined(__amd64__)
#  define OF_X86_64_ASM
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
# elif defined(__arm64__) || defined(__aarch64__)
#  define OF_ARM64_ASM
# endif
#endif

#ifdef OF_APPLE_RUNTIME
# if defined(__x86_64__) || defined(__i386__) || defined(__ARM64_ARCH_8__) || \
	defined(__arm__) || defined(__ppc__)
#  define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#  define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
# endif
#else
# if defined(__ELF__)
#  if defined(__x86_64__) || defined(__amd64__) || defined(__i386__) || \
	defined(__arm__) || defined(__ARM__) || defined(__ppc__) || \
	defined(__PPC__)
#   define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#   if __OBJFW_RUNTIME_ABI__ >= 800
#    define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
#   endif
#  endif
#  if (defined(_MIPS_SIM) && _MIPS_SIM == _ABIO32) || \
	(defined(__mips_eabi) && _MIPS_SZPTR == 32)
#   define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#   if __OBJFW_RUNTIME_ABI__ >= 800
#    define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
#   endif
#  endif
# elif defined(_WIN32)
#  if defined(__x86_64__) || defined(__i386__)
#   define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#   if __OBJFW_RUNTIME_ABI__ >= 800
#    define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
#   endif
#  endif
# endif
#endif

#define OF_RETAIN_COUNT_MAX UINT_MAX
#define OF_NOT_FOUND SIZE_MAX

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

#define OF_ENSURE(cond)							\
	do {								\
		if (!(cond)) {						\
			fprintf(stderr, "Failed to ensure condition "	\
			    "in " __FILE__ ":%d:\n" #cond "\n",		\
			    __LINE__);					\
			abort();					\
		}							\
	} while (0)

#define OF_UNRECOGNIZED_SELECTOR of_method_not_found(self, _cmd);
#define OF_INVALID_INIT_METHOD				\
	@try {						\
		[self doesNotRecognizeSelector: _cmd];	\
	} @catch (id e) {				\
		[self release];				\
		@throw e;				\
	}						\
							\
	abort();

#ifdef __cplusplus
extern "C" {
#endif
extern id objc_getProperty(id, SEL, ptrdiff_t, BOOL);
extern void objc_setProperty(id, SEL, ptrdiff_t, id, BOOL, signed char);
#ifdef __cplusplus
}
#endif

#define OF_IVAR_OFFSET(ivar) ((intptr_t)&ivar - (intptr_t)self)
#define OF_GETTER(ivar, atomic) \
	return objc_getProperty(self, _cmd, OF_IVAR_OFFSET(ivar), atomic);
#define OF_SETTER(ivar, value, atomic, copy) \
	objc_setProperty(self, _cmd, OF_IVAR_OFFSET(ivar), value, atomic, copy);

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
#if defined(OF_HAVE_BUILTIN_BSWAP16)
	return __builtin_bswap16(i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
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
#if defined(OF_HAVE_BUILTIN_BSWAP32)
	return __builtin_bswap32(i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
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
#if defined(OF_HAVE_BUILTIN_BSWAP64)
	return __builtin_bswap64(i);
#elif defined(OF_X86_64_ASM)
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

#define OF_ROL(value, bits)						  \
	(((bits) % (sizeof(value) * 8)) > 0				  \
	? ((value) << ((bits) % (sizeof(value) * 8))) |			  \
	((value) >> (sizeof(value) * 8 - ((bits) % (sizeof(value) * 8)))) \
	: (value))
#define OF_ROR(value, bits)						  \
	(((bits) % (sizeof(value) * 8)) > 0				  \
	? ((value) >> ((bits) % (sizeof(value) * 8))) |			  \
	((value) << (sizeof(value) * 8 - ((bits) % (sizeof(value) * 8)))) \
	: (value))

#define OF_ROUND_UP_POW2(pow2, value) (((value) + (pow2) - 1) & ~((pow2) - 1))

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

static OF_INLINE char*
of_strdup(const char *string)
{
	char *copy;
	size_t length = strlen(string);

	if ((copy = (char*)malloc(length + 1)) == NULL)
		return NULL;

	memcpy(copy, string, length + 1);

	return copy;
}
