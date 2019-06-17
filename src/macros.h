/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include "objfw-defs.h"

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/time.h>

#include "platform.h"

#ifdef OF_OBJFW_RUNTIME
# ifdef OF_COMPILING_OBJFW
#  import "ObjFWRT.h"
# else
#  import <ObjFWRT/ObjFWRT.h>
# endif
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
#  ifdef OF_AIX
/* AIX has a bug where thread_local is defined to "Thread_local;". */
#   undef thread_local
#   define thread_local _Thread_local
#  endif
# else
#  define thread_local _Thread_local
# endif
#elif defined(OF_HAVE___THREAD)
# define OF_HAVE_COMPILER_TLS
# define thread_local __thread
#endif

/*
 * Do not use compiler TLS when targeting the iOS simulator, as the iOS 9
 * simulator does not support it (fails at runtime).
 */
#if defined(OF_HAVE_COMPILER_TLS) && defined(OF_IOS) && defined(OF_X86)
# undef OF_HAVE_COMPILER_TLS
#endif

#ifdef __GNUC__
# define OF_INLINE inline __attribute__((__always_inline__))
# define OF_LIKELY(cond) (__builtin_expect(!!(cond), 1))
# define OF_UNLIKELY(cond) (__builtin_expect(!!(cond), 0))
# define OF_CONST_FUNC __attribute__((__const__))
# define OF_NO_RETURN_FUNC __attribute__((__noreturn__))
# define OF_WEAK_REF(sym) __attribute__((__weakref__(sym)))
#else
# define OF_INLINE inline
# define OF_LIKELY(cond) (cond)
# define OF_UNLIKELY(cond) (cond)
# define OF_CONST_FUNC
# define OF_NO_RETURN_FUNC
# define OF_WEAK_REF(sym)
#endif

#ifdef OF_BIG_ENDIAN
# define OF_BYTE_ORDER_NATIVE OF_BYTE_ORDER_BIG_ENDIAN
#else
# define OF_BYTE_ORDER_NATIVE OF_BYTE_ORDER_LITTLE_ENDIAN
#endif

#if __STDC_VERSION__ >= 201112L
# define OF_ALIGNOF(type) _Alignof(type)
# define OF_ALIGNAS(type) _Alignas(type)
#else
# define OF_ALIGNOF(type) __alignof__(type)
# define OF_ALIGNAS(type) __attribute__((__aligned__(__alignof__(type))))
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
# define OF_GCC_VERSION (__GNUC__ * 100 + __GNUC_MINOR__)
#else
# define OF_GCC_VERSION 0
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
/*
 * undef them first, as new Clang versions have these as built-in defines even
 * when ARC is disabled.
 */
# undef __unsafe_unretained
# undef __bridge
# undef __autoreleasing
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
# define OF_NULLABLE_PROPERTY(...) (__VA_ARGS__, nullable)
# define OF_NULL_RESETTABLE_PROPERTY(...) (__VA_ARGS__, null_resettable)
#else
# define OF_ASSUME_NONNULL_BEGIN
# define OF_ASSUME_NONNULL_END
# define _Nonnull
# define _Nullable
# define _Null_unspecified
# define OF_NULLABLE_PROPERTY
# define OF_NULL_RESETTABLE_PROPERTY
# define nonnull
# define nullable
# define null_unspecified
#endif

#if __has_feature(objc_kindof)
# define OF_KINDOF(class_) __kindof class_
#else
# define OF_KINDOF(class_) id
#endif

#if __has_feature(objc_class_property)
# define OF_HAVE_CLASS_PROPERTIES
#endif

#if defined(__clang__) || OF_GCC_VERSION >= 405
# define OF_UNREACHABLE __builtin_unreachable();
#else
# define OF_UNREACHABLE abort();
#endif

#if defined(__clang__) || OF_GCC_VERSION >= 406
# define OF_SENTINEL __attribute__((__sentinel__))
# define OF_NO_RETURN __attribute__((__noreturn__))
#else
# define OF_SENTINEL
# define OF_NO_RETURN
#endif

#ifdef __clang__
# define OF_WARN_UNUSED_RESULT __attribute__((__warn_unused_result__))
#else
# define OF_WARN_UNUSED_RESULT
#endif

#if __has_attribute(__unavailable__)
# define OF_UNAVAILABLE __attribute__((__unavailable__))
# define OF_HAVE_UNAVAILABLE
#else
# define OF_UNAVAILABLE
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

#if __has_attribute(__objc_method_family__)
# define OF_METHOD_FAMILY(f) __attribute__((__objc_method_family__(f)))
#else
# define OF_METHOD_FAMILY(f)
#endif

#if __has_attribute(__objc_designated_initializer__)
# define OF_DESIGNATED_INITIALIZER \
    __attribute__((__objc_designated_initializer__))
#else
# define OF_DESIGNATED_INITIALIZER
#endif

#if __has_attribute(__objc_boxable__)
# define OF_BOXABLE __attribute__((__objc_boxable__))
#else
# define OF_BOXABLE
#endif

#if __has_attribute(__swift_name__)
# define OF_SWIFT_NAME(name) __attribute__((__swift_name__(name)))
#else
# define OF_SWIFT_NAME(name)
#endif

#ifdef __GNUC__
# ifdef OF_X86_64
#  define OF_X86_64_ASM
# endif
# ifdef OF_X86
#  define OF_X86_ASM
# endif
# ifdef OF_POWERPC
#  define OF_POWERPC_ASM
# endif
# ifdef OF_ARM64
#  define OF_ARM64_ASM
# endif
# ifdef OF_ARM
#  define OF_ARM_ASM
# endif
# ifdef OF_ARMV7
#  define OF_ARMV7_ASM
# endif
# ifdef OF_ARMV6
#  define OF_ARMV6_ASM
# endif
# ifdef OF_MIPS64
#  define OF_MIPS64_ASM
# endif
# ifdef OF_MIPS
#  define OF_MIPS_ASM
# endif
# ifdef OF_PA_RISC
#  define OF_PA_RISC_ASM
# endif
# ifdef OF_ITANIUM
#  define OF_ITANIUM_ASM
# endif
#endif

#ifdef OF_APPLE_RUNTIME
# if defined(OF_X86_64) || defined(OF_X86) || defined(OF_ARM64) || \
    defined(OF_ARM) || defined(OF_POWERPC)
#  define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#  define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
# endif
#else
# if defined(OF_ELF)
#  if defined(OF_X86_64) || defined(OF_X86) || \
    defined(OF_ARM64) || defined(OF_ARM) || defined(OF_POWERPC) || \
    defined(OF_MIPS) || defined(OF_SPARC64)
#   define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#   if __OBJFW_RUNTIME_ABI__ >= 800
#    define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
#   endif
#  endif
# elif defined(OF_MACH_O)
#  if defined(OF_X86_64)
#   define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#   if __OBJFW_RUNTIME_ABI__ >= 800
#    define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
#   endif
#  endif
# elif defined(OF_WINDOWS)
#  if defined(OF_X86_64) || defined(OF_X86)
#   define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR
#   if __OBJFW_RUNTIME_ABI__ >= 800
#    define OF_HAVE_FORWARDING_TARGET_FOR_SELECTOR_STRET
#   endif
#  endif
# endif
#endif

#define OF_RETAIN_COUNT_MAX UINT_MAX
#define OF_NOT_FOUND SIZE_MAX

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
#if __has_feature(objc_arc)
# define OF_INVALID_INIT_METHOD of_method_not_found(self, _cmd);
#else
# define OF_INVALID_INIT_METHOD				\
	@try {						\
		of_method_not_found(self, _cmd);	\
	} @catch (id e) {				\
		[self release];				\
		@throw e;				\
	}						\
							\
	abort();
#endif
#ifdef __clang__
# define OF_DEALLOC_UNSUPPORTED						\
	[self doesNotRecognizeSelector: _cmd];				\
									\
	abort();							\
									\
	_Pragma("clang diagnostic push ignore \"-Wunreachable-code\"");	\
	[super dealloc];	/* Get rid of a stupid warning */	\
	_Pragma("clang diagnostic pop");
#else
# define OF_DEALLOC_UNSUPPORTED						\
	[self doesNotRecognizeSelector: _cmd];				\
									\
	abort();							\
									\
	[super dealloc];	/* Get rid of a stupid warning */
#endif

#define OF_PREPROCESSOR_CONCAT2(a, b) a##b
#define OF_PREPROCESSOR_CONCAT(a, b) OF_PREPROCESSOR_CONCAT2(a, b)
#define OF_CONSTRUCTOR(prio)					\
	static void __attribute__((__constructor__(prio)))	\
	OF_PREPROCESSOR_CONCAT(constructor, __LINE__)(void)
#define OF_DESTRUCTOR(prio)					\
	static void __attribute__((__destructor__(prio)))	\
	OF_PREPROCESSOR_CONCAT(destructor, __LINE__)(void)

static OF_INLINE uint16_t OF_CONST_FUNC
OF_BSWAP16_CONST(uint16_t i)
{
	return (i & 0xFF00) >> 8 | (i & 0x00FF) << 8;
}

static OF_INLINE uint32_t OF_CONST_FUNC
OF_BSWAP32_CONST(uint32_t i)
{
	return (i & 0xFF000000) >> 24 | (i & 0x00FF0000) >> 8 |
	    (i & 0x0000FF00) << 8 | (i & 0x000000FF) << 24;
}

static OF_INLINE uint64_t OF_CONST_FUNC
OF_BSWAP64_CONST(uint64_t i)
{
	return (i & 0xFF00000000000000) >> 56 | (i & 0x00FF000000000000) >> 40 |
	    (i & 0x0000FF0000000000) >> 24 | (i & 0x000000FF00000000) >> 8 |
	    (i & 0x00000000FF000000) << 8 | (i & 0x0000000000FF0000) << 24 |
	    (i & 0x000000000000FF00) << 40 | (i & 0x00000000000000FF) << 56;
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
#elif defined(OF_POWERPC_ASM)
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
#elif defined(OF_POWERPC_ASM)
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

static OF_INLINE uint16_t
of_be16_ptr_read(void *_Nonnull ptr)
{
	uint16_t value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP16_IF_LE(value);
}

static OF_INLINE uint32_t
of_be32_ptr_read(void *_Nonnull ptr)
{
	uint32_t value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP32_IF_LE(value);
}

static OF_INLINE uint64_t
of_be64_ptr_read(void *_Nonnull ptr)
{
	uint64_t value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP64_IF_LE(value);
}

static OF_INLINE float
of_be_float_ptr_read(void *_Nonnull ptr)
{
	float value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP_FLOAT_IF_LE(value);
}

static OF_INLINE double
of_be_double_ptr_read(void *_Nonnull ptr)
{
	double value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP_DOUBLE_IF_LE(value);
}

static OF_INLINE uint16_t
of_le16_ptr_read(void *_Nonnull ptr)
{
	uint16_t value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP16_IF_BE(value);
}

static OF_INLINE uint32_t
of_le32_ptr_read(void *_Nonnull ptr)
{
	uint32_t value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP32_IF_BE(value);
}

static OF_INLINE uint64_t
of_le64_ptr_read(void *_Nonnull ptr)
{
	uint64_t value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP64_IF_BE(value);
}

static OF_INLINE float
of_le_float_ptr_read(void *_Nonnull ptr)
{
	float value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP_FLOAT_IF_BE(value);
}

static OF_INLINE double
of_le_double_ptr_read(void *_Nonnull ptr)
{
	double value;
	memcpy(&value, ptr, sizeof(value));
	return OF_BSWAP_DOUBLE_IF_BE(value);
}

static OF_INLINE void
of_be16_ptr_write(void *_Nonnull ptr, uint16_t value)
{
	value = OF_BSWAP16_IF_LE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_be32_ptr_write(void *_Nonnull ptr, uint32_t value)
{
	value = OF_BSWAP32_IF_LE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_be64_ptr_write(void *_Nonnull ptr, uint64_t value)
{
	value = OF_BSWAP64_IF_LE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_be_float_ptr_write(void *_Nonnull ptr, float value)
{
	value = OF_BSWAP_FLOAT_IF_LE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_be_double_ptr_write(void *_Nonnull ptr, double value)
{
	value = OF_BSWAP_DOUBLE_IF_LE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_le16_ptr_write(void *_Nonnull ptr, uint16_t value)
{
	value = OF_BSWAP16_IF_BE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_le32_ptr_write(void *_Nonnull ptr, uint32_t value)
{
	value = OF_BSWAP32_IF_BE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_le64_ptr_write(void *_Nonnull ptr, uint64_t value)
{
	value = OF_BSWAP64_IF_BE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_le_float_ptr_write(void *_Nonnull ptr, float value)
{
	value = OF_BSWAP_FLOAT_IF_BE(value);
	memcpy(ptr, &value, sizeof(value));
}

static OF_INLINE void
of_le_double_ptr_write(void *_Nonnull ptr, double value)
{
	value = OF_BSWAP_DOUBLE_IF_BE(value);
	memcpy(ptr, &value, sizeof(value));
}

#define OF_ROL(value, bits)						\
    (((bits) % (sizeof(value) * 8)) > 0					\
    ? ((value) << ((bits) % (sizeof(value) * 8))) |			\
    ((value) >> (sizeof(value) * 8 - ((bits) % (sizeof(value) * 8))))	\
    : (value))
#define OF_ROR(value, bits)						\
    (((bits) % (sizeof(value) * 8)) > 0					\
    ? ((value) >> ((bits) % (sizeof(value) * 8))) |			\
    ((value) << (sizeof(value) * 8 - ((bits) % (sizeof(value) * 8))))	\
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

static OF_INLINE bool
of_bitset_isset(unsigned char *_Nonnull storage, size_t idx)
{
	return storage[idx / 8] & (1 << (idx % 8));
}

static OF_INLINE void
of_bitset_set(unsigned char *_Nonnull storage, size_t idx)
{
	storage[idx / 8] |= (1 << (idx % 8));
}

static OF_INLINE void
of_bitset_clear(unsigned char *_Nonnull storage, size_t idx)
{
	storage[idx / 8] &= ~(1 << (idx % 8));
}

static OF_INLINE char *_Nullable
of_strdup(const char *_Nonnull string)
{
	char *copy;
	size_t length = strlen(string);

	if ((copy = (char *)malloc(length + 1)) == NULL)
		return NULL;

	memcpy(copy, string, length + 1);

	return copy;
}

static OF_INLINE void
of_explicit_memset(void *_Nonnull buffer_, int character, size_t length)
{
	volatile unsigned char *buffer = (volatile unsigned char *)buffer_;

	while (buffer < (unsigned char *)buffer_ + length)
		*buffer++ = character;
}

static OF_INLINE bool
of_ascii_isalpha(char c)
{
	return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}

static OF_INLINE bool
of_ascii_isdigit(char c)
{
	return (c >= '0' && c <= '9');
}

static OF_INLINE bool
of_ascii_isalnum(char c)
{
	return (of_ascii_isalpha(c) || of_ascii_isdigit(c));
}

static OF_INLINE bool
of_ascii_isspace(char c)
{
	return (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
	    c == '\v');
}

static OF_INLINE char
of_ascii_toupper(char c)
{
	return (c >= 'a' && c <= 'z' ? 'A' + (c - 'a') : c);
}

static OF_INLINE char
of_ascii_tolower(char c)
{
	return (c >= 'A' && c <= 'Z' ? 'a' + (c - 'A') : c);
}

/* This does *NOT* provide cryptographically secure randomness! */
static OF_INLINE uint32_t
of_random(void) {
#if defined(OF_HAVE_ARC4RANDOM)
	return arc4random();
#elif defined(OF_HAVE_RANDOM)
	struct timeval tv;

	gettimeofday(&tv, NULL);
	srandom((unsigned)(tv.tv_sec ^ tv.tv_usec));
	return (((uint32_t)(random()) << 16) | ((uint32_t)(random()) & 0xFFFF));
#else
	struct timeval tv;

	gettimeofday(&tv, NULL);
	srand((unsigned)(tv.tv_sec ^ tv.tv_usec));
	return (((uint32_t)(rand()) << 16) | ((uint32_t)(rand()) & 0xFFFF));
#endif
}
