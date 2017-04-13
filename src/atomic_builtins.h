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
	return __atomic_add_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
of_atomic_int32_add(volatile int32_t *_Nonnull p, int32_t i)
{
	return __atomic_add_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE void*
of_atomic_ptr_add(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __atomic_add_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int
of_atomic_int_sub(volatile int *_Nonnull p, int i)
{
	return __atomic_sub_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
of_atomic_int32_sub(volatile int32_t *_Nonnull p, int32_t i)
{
	return __atomic_sub_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE void*
of_atomic_ptr_sub(void *volatile _Nullable *_Nonnull p, intptr_t i)
{
	return __atomic_sub_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE int
of_atomic_int_inc(volatile int *_Nonnull p)
{
	return __atomic_add_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
of_atomic_int32_inc(volatile int32_t *_Nonnull p)
{
	return __atomic_add_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE int
of_atomic_int_dec(volatile int *_Nonnull p)
{
	return __atomic_sub_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE int32_t
of_atomic_int32_dec(volatile int32_t *_Nonnull p)
{
	return __atomic_sub_fetch(p, 1, __ATOMIC_RELAXED);
}

static OF_INLINE unsigned int
of_atomic_int_or(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __atomic_or_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE uint32_t
of_atomic_int32_or(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __atomic_or_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE unsigned int
of_atomic_int_and(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __atomic_and_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE uint32_t
of_atomic_int32_and(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __atomic_and_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE unsigned int
of_atomic_int_xor(volatile unsigned int *_Nonnull p, unsigned int i)
{
	return __atomic_xor_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE uint32_t
of_atomic_int32_xor(volatile uint32_t *_Nonnull p, uint32_t i)
{
	return __atomic_xor_fetch(p, i, __ATOMIC_RELAXED);
}

static OF_INLINE bool
of_atomic_int_cmpswap(volatile int *_Nonnull p, int o, int n)
{
	return __atomic_compare_exchange(p, &o, &n, false,
	    __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}

static OF_INLINE bool
of_atomic_int32_cmpswap(volatile int32_t *_Nonnull p, int32_t o, int32_t n)
{
	return __atomic_compare_exchange(p, &o, &n, false,
	    __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}

static OF_INLINE bool
of_atomic_ptr_cmpswap(void *volatile _Nullable *_Nonnull p,
    void *_Nullable o, void *_Nullable n)
{
	return __atomic_compare_exchange(p, &o, &n, false,
	    __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}

static OF_INLINE void
of_memory_barrier_full(void)
{
	__atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static OF_INLINE void
of_memory_barrier_acquire(void)
{
	__atomic_thread_fence(__ATOMIC_ACQUIRE);
}

static OF_INLINE void
of_memory_barrier_release(void)
{
	__atomic_thread_fence(__ATOMIC_RELEASE);
}
