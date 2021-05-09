/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include <stdlib.h>

#import "macros.h"

#ifndef OF_HAVE_ATOMIC_OPS
# error No atomic operations available!
#endif

#if !defined(OF_HAVE_THREADS)
static OF_INLINE int
OFAtomicIntAdd(volatile int *_Nonnull p, int i)
{
	return (*p += i);
}

static OF_INLINE int32_t
OFAtomicInt32Add(volatile int32_t *_Nonnull p, int32_t i)
{
	return (*p += i);
}

static OF_INLINE void *_Nullable
OFAtomicPointerAdd(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return (*(char *volatile *)p += i);
}

static OF_INLINE int
OFAtomicIntSubtract(volatile int *_Nonnull p, int i)
{
	return (*p -= i);
}

static OF_INLINE int32_t
OFAtomicInt32Subtract(volatile int32_t *_Nonnull p, int32_t i)
{
	return (*p -= i);
}

static OF_INLINE void *_Nullable
OFAtomicPointerSubtract(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return (*(char *volatile *)p -= i);
}

static OF_INLINE int
OFAtomicIntIncrease(volatile int *_Nonnull p)
{
	return ++*p;
}

static OF_INLINE int32_t
OFAtomicInt32Increase(volatile int32_t *_Nonnull p)
{
	return ++*p;
}

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
	return --*p;
}

static OF_INLINE int32_t
OFAtomicInt32Decrease(volatile int32_t *_Nonnull p)
{
	return --*p;
}

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return (*p |= i);
}

static OF_INLINE uint32_t
OFAtomicInt32Or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return (*p |= i);
}

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return (*p &= i);
}

static OF_INLINE uint32_t
OFAtomicInt32And(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return (*p &= i);
}

static OF_INLINE unsigned int
OFAtomicIntXor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return (*p ^= i);
}

static OF_INLINE uint32_t
OFAtomicInt32Xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return (*p ^= i);
}

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
{
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
}

static OF_INLINE bool
OFAtomicInt32CompareAndSwap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
}

static OF_INLINE bool
OFAtomicPointerCompareAndSwap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
	if (*p == o) {
		*p = n;
		return true;
	}

	return false;
}

static OF_INLINE void
OFMemoryBarrier(void)
{
	/* nop */
}

static OF_INLINE void
OFAcquireMemoryBarrier(void)
{
	/* nop */
}

static OF_INLINE void
OFReleaseMemoryBarrier(void)
{
	/* nop */
}
#elif (defined(OF_X86_64) || defined(OF_X86)) && defined(__GNUC__)
# import "platform/x86/OFAtomic.h"
#elif defined(OF_POWERPC) && defined(__GNUC__) && !defined(__APPLE_CC__) && \
    !defined(OF_AIX)
# import "platform/PowerPC/OFAtomic.h"
#elif defined(OF_HAVE_ATOMIC_BUILTINS)
# import "platform/GCC4.7/OFAtomic.h"
#elif defined(OF_HAVE_SYNC_BUILTINS)
# import "platform/GCC4/OFAtomic.h"
#elif defined(OF_HAVE_OSATOMIC)
# import "platform/macOS/OFAtomic.h"
#else
# error No atomic operations available!
#endif
