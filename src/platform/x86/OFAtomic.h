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

static OF_INLINE int32_t
OFAtomicInt32Add(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xadd{l}	{ %0, %2 | %2, %0 }\n\t"
	    "add{l}	{ %1, %0 | %0, %1 }"
	    : "+&r" (i)
	    : "r" (i),
	      "m" (*p)
	);

	return i;
}

static OF_INLINE int
OFAtomicIntAdd(volatile int *_Nonnull p, int i)
{
	if (sizeof(int) == 4)
		return OFAtomicInt32Add(p, i);
#ifdef OF_AMD64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "lock\n\t"
		    "xadd{q}	{ %0, %2 | %2, %0 }\n\t"
		    "add{q}	{ %1, %0 | %0, %1 }"
		    : "+&r" (i)
		    : "r" (i),
		      "m" (*p)
		);
#endif
	else
		abort();

	return i;
}

static OF_INLINE void *_Nullable
OFAtomicPointerAdd(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
#if defined(OF_AMD64)
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xadd{q}	{ %0, %2 | %2, %0 }\n\t"
	    "add{q}	{ %1, %0 | %0, %1 }"
	    : "+&r" (i)
	    : "r" (i),
	      "m" (*p)
	);

	return (void *)i;
#elif defined(OF_X86)
	__asm__ __volatile__ (
	    "lock\n\t"
	    "xadd{l}	{ %0, %2 | %2, %0 }\n\t"
	    "add{l}	{ %1, %0 | %0, %1 }"
	    : "+&r" (i)
	    : "r" (i),
	      "m" (*p)
	);

	return (void *)i;
#endif
}

static OF_INLINE int32_t
OFAtomicInt32Subtract(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "neg{l}	%0\n\t"
	    "lock\n\t"
	    "xadd{l}	{ %0, %2 | %2, %0 }\n\t"
	    "sub{l}	{ %1, %0 | %0, %1 }"
	    : "+&r" (i)
	    : "r" (i),
	      "m" (*p)
	);

	return i;
}

static OF_INLINE int
OFAtomicIntSubtract(volatile int *_Nonnull p, int i)
{
	if (sizeof(int) == 4)
		return OFAtomicInt32Subtract(p, i);
#ifdef OF_AMD64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "neg{q}	%0\n\t"
		    "lock\n\t"
		    "xadd{q}	{ %0, %2 | %2, %0 }\n\t"
		    "sub{q}	{ %1, %0 | %0, %1 }"
		    : "+&r" (i)
		    : "r" (i),
		      "m" (*p)
		);
#endif
	else
		abort();

	return i;
}

static OF_INLINE void *_Nullable
OFAtomicPointerSubtract(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
#if defined(OF_AMD64)
	__asm__ __volatile__ (
	    "neg{q}	%0\n\t"
	    "lock\n\t"
	    "xadd{q}	{ %0, %2 | %2, %0 }\n\t"
	    "sub{q}	{ %1, %0 | %0, %1 }"
	    : "+&r" (i)
	    : "r" (i),
	      "m" (*p)
	);

	return (void *)i;
#elif defined(OF_X86)
	__asm__ __volatile__ (
	    "neg{l}	%0\n\t"
	    "lock\n\t"
	    "xadd{l}	{ %0, %2 | %2, %0 }\n\t"
	    "sub{l}	{ %1, %0 | %0, %1 }"
	    : "+&r" (i)
	    : "r" (i),
	      "m" (*p)
	);

	return (void *)i;
#endif
}

static OF_INLINE int32_t
OFAtomicInt32Increase(volatile int32_t *_Nonnull p)
{
	int32_t i;

	__asm__ __volatile__ (
	    "xor{l}	%0, %0\n\t"
	    "inc{l}	%0\n\t"
	    "lock\n\t"
	    "xadd{l}	{ %0, %1 | %1, %0 }\n\t"
	    "inc{l}	%0"
	    : "=&r" (i)
	    : "m" (*p)
	);

	return i;
}

static OF_INLINE int
OFAtomicIntIncrease(volatile int *_Nonnull p)
{
	int i;

	if (sizeof(int) == 4)
		return OFAtomicInt32Increase(p);
#ifdef OF_AMD64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "xor{q}	%0, %0\n\t"
		    "inc{q}	%0\n\t"
		    "lock\n\t"
		    "xadd{q}	{ %0, %1 | %1, %0 }\n\t"
		    "inc{q}	%0"
		    : "=&r" (i)
		    : "m" (*p)
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
	    "xor{l}	%0, %0\n\t"
	    "dec{l}	%0\n\t"
	    "lock\n\t"
	    "xadd{l}	{ %0, %1 | %1, %0 }\n\t"
	    "dec{l}	%0"
	    : "=&r" (i)
	    : "m" (*p)
	);

	return i;
}

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
	int i;

	if (sizeof(int) == 4)
		return OFAtomicInt32Decrease(p);
#ifdef OF_AMD64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "xor{q}	%0, %0\n\t"
		    "dec{q}	%0\n\t"
		    "lock\n\t"
		    "xadd{q}	{ %0, %1 | %1, %0 }\n\t"
		    "dec{q}	%0"
		    : "=&r" (i)
		    : "m" (*p)
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
	    "mov{l}	{ %2, %0 | %0, %2 }\n\t"
	    "mov{l}	{ %0, %%eax | eax, %0 }\n\t"
	    "or{l}	{ %1, %0 | %0, %1 }\n\t"
	    "lock\n\t"
	    "cmpxchg{l}	{ %0, %2 | %2, %0 }\n\t"
	    "jne	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "m" (*p)
	    : "eax", "cc"
	);

	return i;
}

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
	if (sizeof(int) == 4)
		return OFAtomicInt32Or(p, i);
#ifdef OF_AMD64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "mov{q}	{ %2, %0 | %0, %2 }\n\t"
		    "mov{q}	{ %0, %%rax | rax, %0 }\n\t"
		    "or{q}	{ %1, %0 | %0, %1 }\n\t"
		    "lock\n\t"
		    "cmpxchg{q}	{ %0, %2 | %2, %0 }\n\t"
		    "jne	0b"
		    : "=&r" (i)
		    : "r" (i),
		      "m" (*p)
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
	    "mov{l}	{ %2, %0 | %0, %2 }\n\t"
	    "mov{l}	{ %0, %%eax | eax, %0 }\n\t"
	    "and{l}	{ %1, %0 | %0, %1 }\n\t"
	    "lock\n\t"
	    "cmpxchg{l}	{ %0, %2 | %2, %0 }\n\t"
	    "jne	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "m" (*p)
	    : "eax", "cc"
	);

	return i;
}

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
	if (sizeof(int) == 4)
		return OFAtomicInt32And(p, i);
#ifdef OF_AMD64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "mov{q}	{ %2, %0 | %0, %2 }\n\t"
		    "mov{q}	{ %0, %%rax | rax, %0 }\n\t"
		    "and{q}	{ %1, %0 | %0, %1 }\n\t"
		    "lock\n\t"
		    "cmpxchg{q}	{ %0, %2 | %2, %0 }\n\t"
		    "jne	0b"
		    : "=&r" (i)
		    : "r" (i),
		      "m" (*p)
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
	    "mov{l}	{ %2, %0 | %0, %2 }\n\t"
	    "mov{l}	{ %0, %%eax | eax, %0 }\n\t"
	    "xor{l}	{ %1, %0 | %0, %1 }\n\t"
	    "lock\n\t"
	    "cmpxchg{l}	{ %0, %2 | %2, %0 }\n\t"
	    "jne	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "m" (*p)
	    : "eax", "cc"
	);

	return i;
}

static OF_INLINE unsigned int
OFAtomicIntXor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	if (sizeof(int) == 4)
		return OFAtomicInt32Xor(p, i);
#ifdef OF_AMD64
	else if (sizeof(int) == 8)
		__asm__ __volatile__ (
		    "0:\n\t"
		    "mov{q}	{ %2, %0 | %0, %2 }\n\t"
		    "mov{q}	{ %0, %%rax | rax, %0 }\n\t"
		    "xor{q}	{ %1, %0 | %0, %1 }\n\t"
		    "lock\n\t"
		    "cmpxchg{q}	{ %0, %2 | %2, %0 }\n\t"
		    "jne	0b"
		    : "=&r" (i)
		    : "r" (i),
		      "m" (*p)
		    : "rax", "cc"
		);
#endif
	else
		abort();

	return i;
}

static OF_INLINE bool
OFAtomicInt32CompareAndSwap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	int r;

	__asm__ __volatile__ (
	    "lock\n\t"
	    "cmpxchg{l}	{ %2, %3 | %3, %2 }\n\t"
	    "sete	%b0\n\t"
	    "movz{bl|x}	{ %b0, %0 | %0, %b0 }"
	    : "=&d" (r),	/* use d instead of r to avoid a gcc bug */
	      "+a" (o)
	    : "r" (n),
	      "m" (*p)
	    : "cc"
	);

	return r;
}

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
{
	int r;

	__asm__ __volatile__ (
	    "lock\n\t"
	    "cmpxchg	{ %2, %3 | %3, %2 }\n\t"
	    "sete	%b0\n\t"
	    "movz{bl|x}	{ %b0, %0 | %0, %b0 }"
	    : "=&d" (r),	/* use d instead of r to avoid a gcc bug */
	      "+a" (o)
	    : "r" (n),
	      "m" (*p)
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
	    "cmpxchg	{ %2, %3 | %3, %2 }\n\t"
	    "sete	%b0\n\t"
	    "movz{bl|x}	{ %b0, %0 | %0, %b0 }"
	    : "=&d" (r),	/* use d instead of r to avoid a gcc bug */
	      "+a" (o)
	    : "r" (n),
	      "m" (*p)
	    : "cc"
	);

	return r;
}

static OF_INLINE void
OFMemoryBarrier(void)
{
#ifdef OF_AMD64
	__asm__ __volatile__ (
	    "lock or{q}	{ $0, (%%rsp) | [rsp], 0 }" ::: "memory", "cc"
	);
#else
	__asm__ __volatile__ (
	    "lock or{l}	{ $0, (%%esp) | [esp], 0 }" ::: "memory", "cc"
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
