/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Add(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE void *_Nullable
OFAtomicPointerAdd(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "add	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return (void *)i;
}

static OF_INLINE int
OFAtomicIntSubtract(volatile int *_Nonnull p, int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Subtract(volatile int32_t *_Nonnull p, int32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE void *_Nullable
OFAtomicPointerSubtract(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "sub	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return (void *)i;
}

static OF_INLINE int
OFAtomicIntIncrease(volatile int *_Nonnull p)
{
	int i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "addi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Increase(volatile int32_t *_Nonnull p)
{
	int32_t i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "addi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
	int i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "subi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE int32_t
OFAtomicInt32Decrease(volatile int32_t *_Nonnull p)
{
	int32_t i;

	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %1\n\t"
	    "subi	%0, %0, 1\n\t"
	    "stwcx.	%0, 0, %1\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "or		%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE uint32_t
OFAtomicInt32Or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "or		%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "and	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE uint32_t
OFAtomicInt32And(volatile uint32_t *_Nonnull p, uint32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "and	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE unsigned int
OFAtomicIntXor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "xor	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE uint32_t
OFAtomicInt32Xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	__asm__ __volatile__ (
	    "0:\n\t"
	    "lwarx	%0, 0, %2\n\t"
	    "xor	%0, %0, %1\n\t"
	    "stwcx.	%0, 0, %2\n\t"
	    "bne-	0b"
	    : "=&r" (i)
	    : "r" (i),
	      "r" (p)
	    : "cc", "memory"
	);

	return i;
}

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
{
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
	    : "=&r" (r)
	    : "r" (o),
	      "r" (n),
	      "r" (p)
	    : "cc", "memory"
	);

	return r;
}

static OF_INLINE bool
OFAtomicInt32CompareAndSwap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
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
	    : "=&r" (r)
	    : "r" (o),
	      "r" (n),
	      "r" (p)
	    : "cc", "memory"
	);

	return r;
}

static OF_INLINE bool
OFAtomicPointerCompareAndSwap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
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
	    : "=&r" (r)
	    : "r" (o),
	      "r" (n),
	      "r" (p)
	    : "cc", "memory"
	);

	return r;
}

static OF_INLINE void
OFMemoryBarrier(void)
{
	__asm__ __volatile__ (
	    ".long 0x7C0004AC /* sync */" ::: "memory"
	);
}

static OF_INLINE void
OFAcquireMemoryBarrier(void)
{
	__asm__ __volatile__ (
	    ".long 0x7C2004AC /* lwsync */" ::: "memory"
	);
}

static OF_INLINE void
OFReleaseMemoryBarrier(void)
{
	__asm__ __volatile__ (
	    ".long 0x7C2004AC /* lwsync */" ::: "memory"
	);
}
