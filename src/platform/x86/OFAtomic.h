/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

OF_ASSUME_NONNULL_BEGIN

static OF_INLINE int
OFAtomicIntAdd(volatile int *_Nonnull p, int i)
{
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "lock\n\t"
		    "xaddl	%0, %2\n\t"
		    "addl	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
#ifdef OF_X86_64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "lock\n\t"
		    "xaddq	%0, %2\n\t"
		    "addq	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
#endif
	else
		abort();

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Add(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "addl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
}

static OF_INLINE void *_Nullable
OFAtomicPointerAdd(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
#if defined(OF_X86_64)
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xaddq	%0, %2\n\t"
	    "addq	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void *)i;
#elif defined(OF_X86)
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "addl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void *)i;
#endif
}

static OF_INLINE int
OFAtomicIntSubtract(volatile int *_Nonnull p, int i)
{
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "negl	%0\n\t"
		    "lock\n\t"
		    "xaddl	%0, %2\n\t"
		    "subl	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
#ifdef OF_X86_64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "negq	%0\n\t"
		    "lock\n\t"
		    "xaddq	%0, %2\n\t"
		    "subq	%1, %0"
		    : "+&r"(i)
		    : "r"(i), "m"(*p)
		);
#endif
	else
		abort();

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Subtract(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "negl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "subl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return i;
}

static OF_INLINE void *_Nullable
OFAtomicPointerSubtract(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
#if defined(OF_X86_64)
	__asm__ __volatile__ (
	    "negq	%0\n\t"
	    "lock\n\t"
	    "xaddq	%0, %2\n\t"
	    "subq	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void *)i;
#elif defined(OF_X86)
	__asm__ __volatile__ (
	    "negl	%0\n\t"
	    "lock\n\t"
	    "xaddl	%0, %2\n\t"
	    "subl	%1, %0"
	    : "+&r"(i)
	    : "r"(i), "m"(*p)
	);

	return (void *)i;
#endif
}

static OF_INLINE int
OFAtomicIntIncrease(volatile int *_Nonnull p)
{
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
#ifdef OF_X86_64
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
#endif
	else
		abort();

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Increase(volatile int32_t *_Nonnull p)
{
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
}

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
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
#ifdef OF_X86_64
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
#endif
	else
		abort();

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Decrease(volatile int32_t *_Nonnull p)
{
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
}

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
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
#ifdef OF_X86_64
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
#endif
	else
		abort();

	return i;
}

static OF_INLINE uint32_t
OFAtomicInt32Or(volatile uint32_t *_Nonnull p, uint32_t i)
{
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
}

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
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
#ifdef OF_X86_64
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
#endif
	else
		abort();

	return i;
}

static OF_INLINE uint32_t
OFAtomicInt32And(volatile uint32_t *_Nonnull p, uint32_t i)
{
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
}

static OF_INLINE unsigned int
OFAtomicIntXor(volatile unsigned int *_Nonnull p, unsigned int i)
{
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
#ifdef OF_X86_64
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
#endif
	else
		abort();

	return i;
}

static OF_INLINE uint32_t
OFAtomicInt32Xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
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
}

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
{
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
}

static OF_INLINE bool
OFAtomicInt32CompareAndSwap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
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
}

static OF_INLINE bool
OFAtomicPointerCompareAndSwap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
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
}

static OF_INLINE void
OFMemoryBarrier(void)
{
#ifdef OF_X86_64
	__asm__ __volatile__ (
	    "lock orq	$0, (%%rsp)" ::: "memory", "cc"
	);
#else
	__asm__ __volatile__ (
	    "lock orl	$0, (%%esp)" ::: "memory", "cc"
	);
#endif
}

static OF_INLINE void
OFAcquireMemoryBarrier(void)
{
	__asm__ __volatile__ ("" ::: "memory");
}

static OF_INLINE void
OFReleaseMemoryBarrier(void)
{
	__asm__ __volatile__ ("" ::: "memory");
}

OF_ASSUME_NONNULL_END
