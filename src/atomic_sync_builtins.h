/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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
of_atomic_int_add(volatile int *_Nonnull p, int i)
{
	return __sync_add_and_fetch(p, i);
}

static OF_INLINE int32_t
of_atomic_int32_add(volatile int32_t *_Nonnull p, int32_t i)
{
	return __sync_add_and_fetch(p, i);
}

static OF_INLINE void *_Nullable
of_atomic_ptr_add(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __sync_add_and_fetch(p, (void*)i);
}

static OF_INLINE int
of_atomic_int_sub(volatile int *_Nonnull p, int i)
{
	return __sync_sub_and_fetch(p, i);
}

static OF_INLINE int32_t
of_atomic_int32_sub(volatile int32_t *_Nonnull p, int32_t i)
{
	return __sync_sub_and_fetch(p, i);
}

static OF_INLINE void *_Nullable
of_atomic_ptr_sub(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __sync_sub_and_fetch(p, (void*)i);
}

static OF_INLINE int
of_atomic_int_inc(volatile int *_Nonnull p)
{
	return __sync_add_and_fetch(p, 1);
}

static OF_INLINE int32_t
of_atomic_int32_inc(volatile int32_t *_Nonnull p)
{
	return __sync_add_and_fetch(p, 1);
}

static OF_INLINE int
of_atomic_int_dec(volatile int *_Nonnull p)
{
	return __sync_sub_and_fetch(p, 1);
}

static OF_INLINE int32_t
of_atomic_int32_dec(volatile int32_t *_Nonnull p)
{
	return __sync_sub_and_fetch(p, 1);
}

static OF_INLINE unsigned int
of_atomic_int_or(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_or_and_fetch(p, i);
}

static OF_INLINE uint32_t
of_atomic_int32_or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __sync_or_and_fetch(p, i);
}

static OF_INLINE unsigned int
of_atomic_int_and(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_and_and_fetch(p, i);
}

static OF_INLINE uint32_t
of_atomic_int32_and(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __sync_and_and_fetch(p, i);
}

static OF_INLINE unsigned int
of_atomic_int_xor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __sync_xor_and_fetch(p, i);
}

static OF_INLINE uint32_t
of_atomic_int32_xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __sync_xor_and_fetch(p, i);
}

static OF_INLINE bool
of_atomic_int_cmpswap(volatile int *_Nonnull p, int o, int n)
{
	return __sync_bool_compare_and_swap(p, o, n);
}

static OF_INLINE bool
of_atomic_int32_cmpswap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	return __sync_bool_compare_and_swap(p, o, n);
}

static OF_INLINE bool
of_atomic_ptr_cmpswap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
	return __sync_bool_compare_and_swap(p, o, n);
}

static OF_INLINE void
of_memory_barrier(void)
{
	__sync_synchronize();
}

static OF_INLINE void
of_memory_barrier_acquire(void)
{
	__sync_synchronize();
}

static OF_INLINE void
of_memory_barrier_release(void)
{
	__sync_synchronize();
}
