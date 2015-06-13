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

#ifndef OF_HAVE_ATOMIC_OPS
# error No atomic operations available!
#endif

#include <stdlib.h>

#import "macros.h"

#ifdef OF_HAVE_OSATOMIC
# include <libkern/OSAtomic.h>
#endif

OF_ASSUME_NONNULL_BEGIN

static OF_INLINE int
of_atomic_int_add(volatile __nonnull int *p, int i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p += i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "lock\n\t"
		    "xaddl	%0, %2\n\t"
		    "addl	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
# ifdef OF_X86_64_ASM
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "lock\n\t"
		    "xaddq	%0, %2\n\t"
		    "addq	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
# endif
	else
		abort();

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAdd32Barrier(i, p);
#else
# error of_atomic_int_add not implemented!
#endif
}

static OF_INLINE int32_t
of_atomic_int32_add(volatile __nonnull int32_t *p, int32_t i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p += i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "addl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAdd32Barrier(i, p);
#else
# error of_atomic_int32_add not implemented!
#endif
}

static OF_INLINE void*
of_atomic_ptr_add(__nullable void *volatile *__nonnull p, intptr_t i)
{
#if !defined(OF_HAVE_THREADS)
	return (*(char* volatile*)p += i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, (void*)i);
#elif defined(OF_X86_64_ASM)
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xaddq	%0, %2\n\t"
	    "addq	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void*)i;
#elif defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "addl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void*)i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return (void*)i;
#elif defined(OF_HAVE_OSATOMIC)
# ifdef __LP64__
	return (void*)OSAtomicAdd64Barrier(i, (int64_t*)p);
# else
	return (void*)OSAtomicAdd32Barrier(i, (int32_t*)p);
# endif
#else
# error of_atomic_ptr_add not implemented!
#endif
}

static OF_INLINE int
of_atomic_int_sub(volatile __nonnull int *p, int i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p -= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "negl	%0\n\t"
		    "lock\n\t"
		    "xaddl	%0, %2\n\t"
		    "subl	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
# ifdef OF_X86_64_ASM
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "negq	%0\n\t"
		    "lock\n\t"
		    "xaddq	%0, %2\n\t"
		    "subq	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
# endif
	else
		abort();

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAdd32Barrier(-i, p);
#else
# error of_atomic_int_sub not implemented!
#endif
}

static OF_INLINE int32_t
of_atomic_int32_sub(volatile __nonnull int32_t *p, int32_t i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p -= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "negl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "subl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAdd32Barrier(-i, p);
#else
# error of_atomic_int32_sub not implemented!
#endif
}

static OF_INLINE void*
of_atomic_ptr_sub(__nullable void *volatile *__nonnull p, intptr_t i)
{
#if !defined(OF_HAVE_THREADS)
	return (*(char* volatile*)p -= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, (void*)i);
#elif defined(OF_X86_64_ASM)
	__asm__ __volatile__ (
	    "negq	%0\n\t"
	    "lock\n\t"
	    "xaddq	%0, %2\n\t"
	    "subq	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void*)i;
#elif defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "negl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "subl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void*)i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return (void*)i;
#elif defined(OF_HAVE_OSATOMIC)
# ifdef __LP64__
	return (void*)OSAtomicAdd64Barrier(-i, (int64_t*)p);
# else
	return (void*)OSAtomicAdd32Barrier(-i, (int32_t*)p);
# endif
#else
# error of_atomic_ptr_sub not implemented!
#endif
}

static OF_INLINE int
of_atomic_int_inc(volatile __nonnull int *p)
{
#if !defined(OF_HAVE_THREADS)
	return ++*p;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, 1);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	int i;

	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "xorl	%0, %0\n\t"
		    "incl	%0\n\t"
		    "lock\n\t"
		    "xaddl	%0, %1\n\t"
		    "incl	%0"
		    : "=&r"(i)
		    : "m"(*p)
		);
# ifdef OF_X86_64_ASM
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "xorq	%0, %0\n\t"
		    "incq	%0\n\t"
		    "lock\n\t"
		    "xaddq	%0, %1\n\t"
		    "incq	%0"
		    : "=&r"(i)
		    : "m"(*p)
		);
# endif
	else
		abort();

	return i;
#elif defined(OF_PPC_ASM)
	int i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "addi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicIncrement32Barrier(p);
#else
# error of_atomic_int_inc not implemented!
#endif
}

static OF_INLINE int32_t
of_atomic_int32_inc(volatile __nonnull int32_t *p)
{
#if !defined(OF_HAVE_THREADS)
	return ++*p;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, 1);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	int32_t i;

	__asm__ __volatile__ (
	    "xorl	%0, %0\n\t"
	    "incl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %1\n\t"
	    "incl	%0"
	    : "=&r"(i)
	    : "m"(*p)
	);

	return i;
#elif defined(OF_PPC_ASM)
	int32_t i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "addi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicIncrement32Barrier(p);
#else
# error of_atomic_int32_inc not implemented!
#endif
}

static OF_INLINE int
of_atomic_int_dec(volatile __nonnull int *p)
{
#if !defined(OF_HAVE_THREADS)
	return --*p;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, 1);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	int i;

	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "xorl	%0, %0\n\t"
		    "decl	%0\n\t"
		    "lock\n\t"
		    "xaddl	%0, %1\n\t"
		    "decl	%0"
		    : "=&r"(i)
		    : "m"(*p)
		);
# ifdef OF_X86_64_ASM
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "xorq	%0, %0\n\t"
		    "decq	%0\n\t"
		    "lock\n\t"
		    "xaddq	%0, %1\n\t"
		    "decq	%0"
		    : "=&r"(i)
		    : "m"(*p)
		);
# endif
	else
		abort();

	return i;
#elif defined(OF_PPC_ASM)
	int i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "subi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicDecrement32Barrier(p);
#else
# error of_atomic_int_dec not implemented!
#endif
}

static OF_INLINE int32_t
of_atomic_int32_dec(volatile __nonnull int32_t *p)
{
#if !defined(OF_HAVE_THREADS)
	return --*p;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, 1);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	int32_t i;

	__asm__ __volatile__ (
	    "xorl	%0, %0\n\t"
	    "decl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %1\n\t"
	    "decl	%0"
	    : "=&r"(i)
	    : "m"(*p)
	);

	return i;
#elif defined(OF_PPC_ASM)
	int32_t i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "subi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicDecrement32Barrier(p);
#else
# error of_atomic_int32_dec not implemented!
#endif
}

static OF_INLINE unsigned int
of_atomic_int_or(volatile __nonnull unsigned int *p, unsigned int i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p |= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_or_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "movl	%2, %0\n\t"
		    "movl	%0, %%eax\n\t"
		    "orl	%1, %0\n\t"
		    "lock\n\t"
		    "cmpxchg	%0, %2\n\t"
		    "jne	0b"
		    : "=&r"(i)
		    : "r"(i), "m"(*p)
		    : "eax", "cc"
		);
# ifdef OF_X86_64_ASM
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "movq	%2, %0\n\t"
		    "movq	%0, %%rax\n\t"
		    "orq	%1, %0\n\t"
		    "lock\n\t"
		    "cmpxchg	%0, %2\n\t"
		    "jne	0b"
		    : "=&r"(i)
		    : "r"(i), "m"(*p)
		    : "rax", "cc"
		);
# endif
	else
		abort();

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "or		%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicOr32Barrier(i, p);
#else
# error of_atomic_int_or not implemented!
#endif
}

static OF_INLINE uint32_t
of_atomic_int32_or(volatile __nonnull uint32_t *p, uint32_t i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p |= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_or_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%0, %%eax\n\t"
	    "orl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchg	%0, %2\n\t"
	    "jne	0b"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax", "cc"
	);

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "or		%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicOr32Barrier(i, p);
#else
# error of_atomic_int32_or not implemented!
#endif
}

static OF_INLINE unsigned int
of_atomic_int_and(volatile __nonnull unsigned int *p, unsigned int i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p &= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_and_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "movl	%2, %0\n\t"
		    "movl	%0, %%eax\n\t"
		    "andl	%1, %0\n\t"
		    "lock\n\t"
		    "cmpxchg	%0, %2\n\t"
		    "jne	0b"
		    : "=&r"(i)
		    : "r"(i), "m"(*p)
		    : "eax", "cc"
		);
# ifdef OF_X86_64_ASM
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "movq	%2, %0\n\t"
		    "movq	%0, %%rax\n\t"
		    "andq	%1, %0\n\t"
		    "lock\n\t"
		    "cmpxchg	%0, %2\n\t"
		    "jne	0b"
		    : "=&r"(i)
		    : "r"(i), "m"(*p)
		    : "rax", "cc"
		);
# endif
	else
		abort();

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "and	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAnd32Barrier(i, p);
#else
# error of_atomic_int_and not implemented!
#endif
}

static OF_INLINE uint32_t
of_atomic_int32_and(volatile __nonnull uint32_t *p, uint32_t i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p &= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_and_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%0, %%eax\n\t"
	    "andl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchg	%0, %2\n\t"
	    "jne	0b"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax", "cc"
	);

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "and	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAnd32Barrier(i, p);
#else
# error of_atomic_int32_and not implemented!
#endif
}

static OF_INLINE unsigned int
of_atomic_int_xor(volatile __nonnull unsigned int *p, unsigned int i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p ^= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_xor_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "movl	%2, %0\n\t"
		    "movl	%0, %%eax\n\t"
		    "xorl	%1, %0\n\t"
		    "lock\n\t"
		    "cmpxchg	%0, %2\n\t"
		    "jne	0b"
		    : "=&r"(i)
		    : "r"(i), "m"(*p)
		    : "eax", "cc"
		);
# ifdef OF_X86_64_ASM
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "movq	%2, %0\n\t"
		    "movq	%0, %%rax\n\t"
		    "xorq	%1, %0\n\t"
		    "lock\n\t"
		    "cmpxchg	%0, %2\n\t"
		    "jne	0b"
		    : "=&r"(i)
		    : "r"(i), "m"(*p)
		    : "rax", "cc"
		);
# endif
	else
		abort();

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "xor	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicXor32Barrier(i, p);
#else
# error of_atomic_int_xor not implemented!
#endif
}

static OF_INLINE uint32_t
of_atomic_int32_xor(volatile __nonnull uint32_t *p, uint32_t i)
{
#if !defined(OF_HAVE_THREADS)
	return (*p ^= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_xor_and_fetch(p, i);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%0, %%eax\n\t"
	    "xorl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchgl	%0, %2\n\t"
	    "jne	0b"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax", "cc"
	);

	return i;
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "xor	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r"(i)
	    : "r"(i), "r"(p)
	);

	return i;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicXor32Barrier(i, p);
#else
# error of_atomic_int32_xor not implemented!
#endif
}

static OF_INLINE bool
of_atomic_int_cmpswap(volatile __nonnull int *p, int o, int n)
{
#if !defined(OF_HAVE_THREADS)
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	int r;

	__asm__ __volatile__ (
	    "lock\n\t"
	    "cmpxchg	%2, %3\n\t"
	    "sete	%b0\n\t"
	    "movzbl	%b0, %0"
	    : "=&d"(r), "+a"(o)	/* use d instead of r to avoid a gcc bug */
	    : "r"(n), "m"(*p)
	    : "cc"
	);

	return r;
#elif defined(OF_PPC_ASM)
	int r;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %3\n\t"
	    "cmpw	%0, %1\n\t"
	    "bne	1f\n\t"
	    "stwcx.	%2, 0, %3\n\t"
	    "bne-	0b\n\t"
	    "li		%0, 1\n\t"
	    "b		2f\n\t"
	    "1:\n\t"
	    "stwcx.	%0, 0, %3\n\t"
	    "li		%0, 0\n\t"
	    "2:"
	    : "=&r"(r)
	    : "r"(o), "r"(n), "r"(p)
	    : "cc"
	);

	return r;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicCompareAndSwapIntBarrier(o, n, p);
#else
# error of_atomic_int_cmpswap not implemented!
#endif
}

static OF_INLINE bool
of_atomic_int32_cmpswap(volatile __nonnull int32_t *p, int32_t o, int32_t n)
{
#if !defined(OF_HAVE_THREADS)
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	int r;

	__asm__ __volatile__ (
	    "lock\n\t"
	    "cmpxchg	%2, %3\n\t"
	    "sete	%b0\n\t"
	    "movzbl	%b0, %0"
	    : "=&d"(r), "+a"(o)	/* use d instead of r to avoid a gcc bug */
	    : "r"(n), "m"(*p)
	    : "cc"
	);

	return r;
#elif defined(OF_PPC_ASM)
	int r;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %3\n\t"
	    "cmpw	%0, %1\n\t"
	    "bne	1f\n\t"
	    "stwcx.	%2, 0, %3\n\t"
	    "bne-	0b\n\t"
	    "li		%0, 1\n\t"
	    "b		2f\n\t"
	    "1:\n\t"
	    "stwcx.	%0, 0, %3\n\t"
	    "li		%0, 0\n\t"
	    "2:"
	    : "=&r"(r)
	    : "r"(o), "r"(n), "r"(p)
	    : "cc"
	);

	return r;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicCompareAndSwap32Barrier(o, n, p);
#else
# error of_atomic_int32_cmpswap not implemented!
#endif
}

static OF_INLINE bool
of_atomic_ptr_cmpswap(__nullable void *volatile *__nonnull p,
    __nullable void *o, __nullable void *n)
{
#if !defined(OF_HAVE_THREADS)
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	int r;

	__asm__ __volatile__ (
	    "lock\n\t"
	    "cmpxchg	%2, %3\n\t"
	    "sete	%b0\n\t"
	    "movzbl	%b0, %0"
	    : "=&d"(r), "+a"(o)	/* use d instead of r to avoid a gcc bug */
	    : "r"(n), "m"(*p)
	    : "cc"
	);

	return r;
#elif defined(OF_PPC_ASM)
	int r;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %3\n\t"
	    "cmpw	%0, %1\n\t"
	    "bne	1f\n\t"
	    "stwcx.	%2, 0, %3\n\t"
	    "bne-	0b\n\t"
	    "li		%0, 1\n\t"
	    "b		2f\n\t"
	    "1:\n\t"
	    "stwcx.	%0, 0, %3\n\t"
	    "li		%0, 0\n\t"
	    "2:"
	    : "=&r"(r)
	    : "r"(o), "r"(n), "r"(p)
	    : "cc"
	);

	return r;
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicCompareAndSwapPtrBarrier(o, n, p);
#else
# error of_atomic_ptr_cmpswap not implemented!
#endif
}

static OF_INLINE void
of_memory_barrier(void)
{
#if !defined(OF_HAVE_THREADS)
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "mfence"
	);
#elif defined(OF_PPC_ASM)
	__asm__ __volatile__ (
	    "sync"
	);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	__sync_synchronize();
#elif defined(OF_HAVE_OSATOMIC)
	OSMemoryBarrier();
#else
# error of_memory_barrier not implemented!
#endif
}

static OF_INLINE void
of_memory_read_barrier(void)
{
#if !defined(OF_HAVE_THREADS)
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "lfence"
	);
#else
	of_memory_barrier();
#endif
}

static OF_INLINE void
of_memory_write_barrier(void)
{
#if !defined(OF_HAVE_THREADS)
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
	__asm__ __volatile__ (
	    "sfence"
	);
#else
	of_memory_barrier();
#endif
}

OF_ASSUME_NONNULL_END
