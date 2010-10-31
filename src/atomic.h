/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <stdlib.h>

#import "macros.h"

#if defined(OF_THREADS) && !defined(OF_X86_ASM) && !defined(OF_AMD64_ASM) && \
    !defined(OF_HAVE_GCC_ATOMIC_OPS) && !defined(OF_HAVE_OSATOMIC)
# error No atomic operations available!
#endif

#ifdef OF_HAVE_OSATOMIC
# include <libkern/OSAtomic.h>
#endif

static OF_INLINE int
of_atomic_add_int(volatile int *p, int i)
{
#if !defined(OF_THREADS)
	return (*p += i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "addl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(int) == 4)
		return OSAtomicAdd32Barrier(i, p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(int) == 8)
		return OSAtomicAdd64Barrier(i, p);
# endif
	else
		abort();
#endif
}

static OF_INLINE int32_t
of_atomic_add_32(volatile int32_t *p, int32_t i)
{
#if !defined(OF_THREADS)
	return (*p += i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "addl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAdd32Barrier(i, p);
#endif
}

static OF_INLINE void*
of_atomic_add_ptr(volatile void **p, intptr_t i)
{
#if !defined(OF_THREADS)
	return (*p += i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "addl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void*)i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(void*) == 4)
		return (void*)OSAtomicAdd32Barrier(i, (int32_t*)p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(void*) == 8)
		return (void*)OSAtomicAdd64Barrier(i, (int64_t*)p);
# endif
	else
		abort();
#endif
}

static OF_INLINE int
of_atomic_sub_int(volatile int *p, int i)
{
#if !defined(OF_THREADS)
	return (*p -= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "negl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "subl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(int) == 4)
		return OSAtomicAdd32Barrier(-i, p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(int) == 8)
		return OSAtomicAdd64Barrier(-i, p);
# endif
	else
		abort();
#endif
}

static OF_INLINE int32_t
of_atomic_sub_32(volatile int32_t *p, int32_t i)
{
#if !defined(OF_THREADS)
	return (*p -= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "negl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "subl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAdd32Barrier(-i, p);
#endif
}

static OF_INLINE void*
of_atomic_sub_ptr(volatile void **p, intptr_t i)
{
#if !defined(OF_THREADS)
	return (*p -= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "negl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "subl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void*)i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(void*) == 4)
		return (void*)OSAtomicAdd32Barrier(-i, (int32_t*)p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(void*) == 8)
		return (void*)OSAtomicAdd64Barrier(-i, (int64_t*)p);
# endif
	else
		abort();
#endif
}

static OF_INLINE int
of_atomic_inc_int(volatile int *p)
{
#if !defined(OF_THREADS)
	return ++*p;
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	uint32_t i;

	__asm__ (
	    "xorl	%0, %0\n\t"
	    "incl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %1\n\t"
	    "incl	%0"
	    : "=&r"(i)
	    : "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, 1);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(int) == 4)
		return OSAtomicIncrement32Barrier(p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(int) == 8)
		return OSAtomicDecrement64Barrier(p);
# endif
	else
		abort();
#endif
}
static OF_INLINE int32_t
of_atomic_inc_32(volatile int32_t *p)
{
#if !defined(OF_THREADS)
	return ++*p;
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	uint32_t i;

	__asm__ (
	    "xorl	%0, %0\n\t"
	    "incl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %1\n\t"
	    "incl	%0"
	    : "=&r"(i)
	    : "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, 1);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicIncrement32Barrier(p);
#endif
}

static OF_INLINE int
of_atomic_dec_int(volatile int *p)
{
#if !defined(OF_THREADS)
	return --*p;
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	uint32_t i;

	__asm__ (
	    "xorl	%0, %0\n\t"
	    "decl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %1\n\t"
	    "decl	%0"
	    : "=&r"(i)
	    : "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, 1);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(int) == 4)
		return OSAtomicDecrement32Barrier(p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(int) == 8)
		return OSAtomicDecrement64Barrier(p);
# endif
	else
		abort();
#endif
}

static OF_INLINE int32_t
of_atomic_dec_32(volatile int32_t *p)
{
#if !defined(OF_THREADS)
	return --*p;
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	uint32_t i;

	__asm__ (
	    "xorl	%0, %0\n\t"
	    "decl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %1\n\t"
	    "decl	%0"
	    : "=&r"(i)
	    : "m"(*p)
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, 1);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicDecrement32Barrier(p);
#endif
}

static OF_INLINE unsigned int
of_atomic_or_int(volatile unsigned int *p, unsigned int i)
{
#if !defined(OF_THREADS)
	return (*p |= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%2, %%eax\n\t"
	    "orl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchg	%0, %2\n\t"
	    "jne	0\n\t"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax"
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_or_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(int) == 4)
		return OSAtomicOr32Barrier(i, p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(int) == 8)
		return OSAtomicOr64Barrier(i, p);
# endif
	else
		abort();
#endif
}

static OF_INLINE uint32_t
of_atomic_or_32(volatile uint32_t *p, uint32_t i)
{
#if !defined(OF_THREADS)
	return (*p |= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%2, %%eax\n\t"
	    "orl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchg	%0, %2\n\t"
	    "jne	0\n\t"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax"
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_or_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicOr32Barrier(i, p);
#endif
}

static OF_INLINE unsigned int
of_atomic_and_int(volatile unsigned int *p, unsigned int i)
{
#if !defined(OF_THREADS)
	return (*p &= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%2, %%eax\n\t"
	    "andl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchg	%0, %2\n\t"
	    "jne	0\n\t"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax"
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_and_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(int) == 4)
		return OSAtomicAnd32Barrier(i, p);
# ifdef OF_HAVE_OSATOMIC_64
	else if (sizeof(int) == 8)
		return OSAtomicAnd64Barrier(i, p);
# endif
	else
		abort();
#endif
}

static OF_INLINE uint32_t
of_atomic_and_32(volatile uint32_t *p, uint32_t i)
{
#if !defined(OF_THREADS)
	return (*p &= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%2, %%eax\n\t"
	    "andl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchg	%0, %2\n\t"
	    "jne	0\n\t"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax"
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_and_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicAnd32Barrier(i, p);
#endif
}

static OF_INLINE unsigned int
of_atomic_xor_int(volatile unsigned int *p, unsigned int i)
{
#if !defined(OF_THREADS)
	return (*p ^= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%2, %%eax\n\t"
	    "xorl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchgl	%0, %2\n\t"
	    "jne	0\n\t"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax"
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_xor_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	if (sizeof(int) == 4)
		return OSAtomicXor32Barrier(i, p);
# ifdef OF_HAVE_OSATOMIC_64
	else (sizeof(int) == 8)
		return OSAtomicXor64Barrier(i, p);
# endif
	else
		abort();
#endif
}

static OF_INLINE uint32_t
of_atomic_xor_32(volatile uint32_t *p, uint32_t i)
{
#if !defined(OF_THREADS)
	return (*p ^= i);
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	__asm__ (
	    "0:\n\t"
	    "movl	%2, %0\n\t"
	    "movl	%2, %%eax\n\t"
	    "xorl	%1, %0\n\t"
	    "lock\n\t"
	    "cmpxchgl	%0, %2\n\t"
	    "jne	0\n\t"
	    : "=&r"(i)
	    : "r"(i), "m"(*p)
	    : "eax"
	);

	return i;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_xor_and_fetch(p, i);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicXor32Barrier(i, p);
#endif
}

static OF_INLINE BOOL
of_atomic_cmpswap_int(volatile int *p, int o, int n)
{
#if !defined(OF_THREADS)
	if (*p == o) {
		*p = n;
		return YES;
	}

	return NO;
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	int r;

	__asm__ (
	    "lock\n\t"
	    "cmpxchg	%2, %3\n\t"
	    "lahf\n\t"
	    "andb	$64, %%ah\n\t"
	    "shrb	$6, %%ah\n\t"
	    "movzx	%%ah, %0\n\t"
	    : "=a"(r)
	    : "a"(o), "r"(n), "m"(*p)
	);

	return r;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicCompareAndSwapIntBarrier(o, n, p);
#endif
}

static OF_INLINE BOOL
of_atomic_cmpswap_32(volatile int32_t *p, int32_t o, int32_t n)
{
#if !defined(OF_THREADS)
	if (*p == o) {
		*p = n;
		return YES;
	}

	return NO;
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	uint32_t r;

	__asm__ (
	    "lock\n\t"
	    "cmpxchg	%2, %3\n\t"
	    "lahf\n\t"
	    "andb	$64, %%ah\n\t"
	    "shrb	$6, %%ah\n\t"
	    "movzx	%%ah, %0\n\t"
	    : "=a"(r)
	    : "a"(o), "r"(n), "m"(*p)
	);

	return r;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicCompareAndSwap32Barrier(o, n, p);
#endif
}

static OF_INLINE BOOL
of_atomic_cmpswap_ptr(void* volatile *p, void *o, void *n)
{
#if !defined(OF_THREADS)
	if (*p == o) {
		*p = n;
		return YES;
	}

	return NO;
#elif defined(OF_X86_ASM) || defined(OF_AMD64_ASM)
	uint32_t r;

	__asm__ (
	    "lock\n\t"
	    "cmpxchg	%2, %3\n\t"
	    "lahf\n\t"
	    "andb	$64, %%ah\n\t"
	    "shrb	$6, %%ah\n\t"
	    "movzx	%%ah, %0\n\t"
	    : "=a"(r)
	    : "a"(o), "q"(n), "m"(*p)
	);

	return r;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_HAVE_OSATOMIC)
	return OSAtomicCompareAndSwapPtrBarrier(o, n, p);
#endif
}
