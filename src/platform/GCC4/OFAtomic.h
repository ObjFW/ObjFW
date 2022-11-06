/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

static OF_INLINE int
OFAtomicIntAdd(volatile int *_Nonnull p, int i)
{
	return __sync_add_and_fetch(p, i);
}

static OF_INLINE int32_t
OFAtomicInt32Add(volatile int32_t *_Nonnull p, int32_t i)
{
	return __sync_add_and_fetch(p, i);
}

static OF_INLINE void *_Nullable
OFAtomicPointerAdd(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __sync_add_and_fetch(p, (void *)i);
}

static OF_INLINE int
OFAtomicIntSubtract(volatile int *_Nonnull p, int i)
{
	return __sync_sub_and_fetch(p, i);
}

static OF_INLINE int32_t
OFAtomicInt32Subtract(volatile int32_t *_Nonnull p, int32_t i)
{
	return __sync_sub_and_fetch(p, i);
}

static OF_INLINE void *_Nullable
OFAtomicPointerSubtract(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __sync_sub_and_fetch(p, (void *)i);
}

static OF_INLINE int
OFAtomicIntIncrease(volatile int *_Nonnull p)
{
	return __sync_add_and_fetch(p, 1);
}

static OF_INLINE int32_t
OFAtomicInt32Increase(volatile int32_t *_Nonnull p)
{
	return __sync_add_and_fetch(p, 1);
}

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
	return __sync_sub_and_fetch(p, 1);
}

static OF_INLINE int32_t
OFAtomicInt32Decrease(volatile int32_t *_Nonnull p)
{
	return __sync_sub_and_fetch(p, 1);
}

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_or_and_fetch(p, i);
}

static OF_INLINE uint32_t
OFAtomicInt32Or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __sync_or_and_fetch(p, i);
}

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_and_and_fetch(p, i);
}

static OF_INLINE uint32_t
OFAtomicInt32And(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __sync_and_and_fetch(p, i);
}

static OF_INLINE unsigned int
OFAtomicIntXor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_xor_and_fetch(p, i);
}

static OF_INLINE uint32_t
OFAtomicInt32Xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __sync_xor_and_fetch(p, i);
}

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
{
	return __sync_bool_compare_and_swap(p, o, n);
}

static OF_INLINE bool
OFAtomicInt32CompareAndSwap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	return __sync_bool_compare_and_swap(p, o, n);
}

static OF_INLINE bool
OFAtomicPointerCompareAndSwap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
	return __sync_bool_compare_and_swap(p, o, n);
}

static OF_INLINE void
OFMemoryBarrier(void)
{
	__sync_synchronize();
}

static OF_INLINE void
OFAcquireMemoryBarrier(void)
{
	__sync_synchronize();
}

static OF_INLINE void
OFReleaseMemoryBarrier(void)
{
	__sync_synchronize();
}
