/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "objfw-defs.h"

#if !defined(OF_THREADS)
# define of_atomic_inc32(p) ++(*p)
# define of_atomic_dec32(p) --(*p)
# define of_atomic_cmpswap32(p, o, n) (*p == o ? ((*p = n) ? 1 : 1) : 0)
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
# define of_atomic_inc32(p) __sync_add_and_fetch(p, 1)
# define of_atomic_dec32(p) __sync_sub_and_fetch(p, 1)
# define of_atomic_cmpswap32(p, o, n) __sync_bool_compare_and_swap(p, o, n)
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
# include <libkern/OSAtomic.h>
# define of_atomic_inc32(p) OSAtomicIncrement32Barrier((int32_t*)(p))
# define of_atomic_dec32(p) OSAtomicDecrement32Barrier((int32_t*)(p))
# define of_atomic_cmpswap32(p, o, n) \
	OSAtomicCompareAndSwap32Barrier(o, n, (int32_t*)p)
#else
# error No atomic operations available!
#endif

typedef int32_t of_spinlock_t;
#ifdef OF_THREADS
# define of_spinlock_lock(s) while (!of_atomic_cmpswap32(&s, 0, 1));
# define of_spinlock_unlock(s) s = 0
#else
# define of_spinlock_lock(s)
# define of_spinlock_unlock(s)
#endif
