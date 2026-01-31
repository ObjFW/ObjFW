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
	return __atomic_add_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
OFAtomicInt32Add(volatile int32_t *_Nonnull p, int32_t i)
{
	return __atomic_add_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE void *_Nullable
OFAtomicPointerAdd(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __atomic_add_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int
OFAtomicIntSubtract(volatile int *_Nonnull p, int i)
{
	return __atomic_sub_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
OFAtomicInt32Subtract(volatile int32_t *_Nonnull p, int32_t i)
{
	return __atomic_sub_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE void *_Nullable
OFAtomicPointerSubtract(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __atomic_sub_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int
OFAtomicIntIncrease(volatile int *_Nonnull p)
{
	return __atomic_add_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
OFAtomicInt32Increase(volatile int32_t *_Nonnull p)
{
	return __atomic_add_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
	return __atomic_sub_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
OFAtomicInt32Decrease(volatile int32_t *_Nonnull p)
{
	return __atomic_sub_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __atomic_or_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE uint32_t
OFAtomicInt32Or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __atomic_or_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __atomic_and_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE uint32_t
OFAtomicInt32And(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __atomic_and_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE unsigned int
OFAtomicIntXor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __atomic_xor_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE uint32_t
OFAtomicInt32Xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __atomic_xor_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
{
	return __atomic_compare_exchange(p, &o, &n, false,
	    __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}

static OF_INLINE bool
OFAtomicInt32CompareAndSwap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	return __atomic_compare_exchange(p, &o, &n, false,
	    __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}

static OF_INLINE bool
OFAtomicPointerCompareAndSwap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
	return __atomic_compare_exchange(p, &o, &n, false,
	    __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}

static OF_INLINE void
OFMemoryBarrier(void)
{
	__atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static OF_INLINE void
OFAcquireMemoryBarrier(void)
{
	__atomic_thread_fence(__ATOMIC_ACQUIRE);
}

static OF_INLINE void
OFReleaseMemoryBarrier(void)
{
	__atomic_thread_fence(__ATOMIC_RELEASE);
}
