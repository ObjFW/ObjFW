/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

static OF_INLINE int
OFAtomicIntAdd(volatile int *_Nonnull p, int i)
{
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "lock\n\t"
		    "xadd{l}	{ %0, %2 | %2, %0 }\n\t"
		    "add{l}	{ %1, %0 | %0, %1 }"
		    : "+&r" (i)
		    : "r" (i),
		      "m" (*p)
		);
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

static OF_INLINE int
OFAtomicIntSubtract(volatile int *_Nonnull p, int i)
{
	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "neg{l}	%0\n\t"
		    "lock\n\t"
		    "xadd{l}	{ %0, %2 | %2, %0 }\n\t"
		    "sub{l}	{ %1, %0 | %0, %1 }"
		    : "+&r" (i)
		    : "r" (i),
		      "m" (*p)
		);
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

static OF_INLINE int
OFAtomicIntIncrease(volatile int *_Nonnull p)
{
	int i;

	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "xor{l}	%0, %0\n\t"
		    "inc{l}	%0\n\t"
		    "lock\n\t"
		    "xadd{l}	{ %0, %1 | %1, %0 }\n\t"
		    "inc{l}	%0"
		    : "=&r" (i)
		    : "m" (*p)
		);
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

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
	int i;

	if (sizeof(int) == 4)
		__asm__ __volatile__ (
		    "xor{l}	%0, %0\n\t"
		    "dec{l}	%0\n\t"
		    "lock\n\t"
		    "xadd{l}	{ %0, %1 | %1, %0 }\n\t"
		    "dec{l}	%0"
		    : "=&r" (i)
		    : "m" (*p)
		);
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

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
	if (sizeof(int) == 4)
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

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
	if (sizeof(int) == 4)
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

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
{
	int r;

	__asm__ __volatile__ (
	    "lock\n\t"
	    "cmpxchg	{ %2, %3 | %3, %2 }\n\t"
	    "sete	%b0\n\t"
	    "movz{bl|x}	{ %b0, %0 | %0, %b0 }"
	    : "=&d" (r),	/* use d instead of r to avoid a GCC bug */
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
	    : "=&d" (r),	/* use d instead of r to avoid a GCC bug */
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
