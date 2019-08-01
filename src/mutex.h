/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include "objfw-defs.h"

#include "platform.h"

#if !defined(OF_HAVE_THREADS) || \
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS))
# error No mutexes available!
#endif

#import "macros.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_mutex_t of_mutex_t;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef CRITICAL_SECTION of_mutex_t;
#elif defined(OF_AMIGAOS)
# include <exec/semaphores.h>
typedef struct SignalSemaphore of_mutex_t;
#endif

#if defined(OF_HAVE_ATOMIC_OPS)
# import "atomic.h"
typedef volatile int of_spinlock_t;
# define OF_SPINCOUNT 10
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
typedef pthread_spinlock_t of_spinlock_t;
#else
typedef of_mutex_t of_spinlock_t;
#endif

#ifdef OF_HAVE_SCHED_YIELD
# include <sched.h>
#endif

#if defined(OF_HAVE_RECURSIVE_PTHREAD_MUTEXES) || defined(OF_WINDOWS) || \
    defined(OF_AMIGAOS)
# define of_rmutex_t of_mutex_t
#else
# import "tlskey.h"
typedef struct {
	of_mutex_t mutex;
	of_tlskey_t count;
} of_rmutex_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern bool of_mutex_new(of_mutex_t *mutex);
extern bool of_mutex_lock(of_mutex_t *mutex);
extern bool of_mutex_trylock(of_mutex_t *mutex);
extern bool of_mutex_unlock(of_mutex_t *mutex);
extern bool of_mutex_free(of_mutex_t *mutex);
extern bool of_rmutex_new(of_rmutex_t *rmutex);
extern bool of_rmutex_lock(of_rmutex_t *rmutex);
extern bool of_rmutex_trylock(of_rmutex_t *rmutex);
extern bool of_rmutex_unlock(of_rmutex_t *rmutex);
extern bool of_rmutex_free(of_rmutex_t *rmutex);
#ifdef __cplusplus
}
#endif

/* Spinlocks are inlined for performance. */

static OF_INLINE void
of_thread_yield(void)
{
#if defined(OF_HAVE_SCHED_YIELD)
	sched_yield();
#elif defined(OF_WINDOWS)
	Sleep(0);
#endif
}

static OF_INLINE bool
of_spinlock_new(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	*spinlock = 0;
	return true;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return (pthread_spin_init(spinlock, 0) == 0);
#else
	return of_mutex_new(spinlock);
#endif
}

static OF_INLINE bool
of_spinlock_trylock(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	if (of_atomic_int_cmpswap(spinlock, 0, 1)) {
		of_memory_barrier_acquire();
		return true;
	}

	return false;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return (pthread_spin_trylock(spinlock) == 0);
#else
	return of_mutex_trylock(spinlock);
#endif
}

static OF_INLINE bool
of_spinlock_lock(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	size_t i;

	for (i = 0; i < OF_SPINCOUNT; i++)
		if (of_spinlock_trylock(spinlock))
			return true;

	while (!of_spinlock_trylock(spinlock))
		of_thread_yield();

	return true;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return (pthread_spin_lock(spinlock) == 0);
#else
	return of_mutex_lock(spinlock);
#endif
}

static OF_INLINE bool
of_spinlock_unlock(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	bool ret = of_atomic_int_cmpswap(spinlock, 1, 0);

	of_memory_barrier_release();

	return ret;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return (pthread_spin_unlock(spinlock) == 0);
#else
	return of_mutex_unlock(spinlock);
#endif
}

static OF_INLINE bool
of_spinlock_free(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	return true;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return (pthread_spin_destroy(spinlock) == 0);
#else
	return of_mutex_free(spinlock);
#endif
}
