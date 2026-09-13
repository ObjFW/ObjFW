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

static OF_INLINE int
OFAtomicIntDecrease(volatile int *_Nonnull p)
{
	return __sync_sub_and_fetch(p, 1);
}

static OF_INLINE unsigned int
OFAtomicIntOr(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_or_and_fetch(p, i);
}

static OF_INLINE unsigned int
OFAtomicIntAnd(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_and_and_fetch(p, i);
}

static OF_INLINE bool
OFAtomicIntCompareAndSwap(volatile int *_Nonnull p, int o, int n)
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
