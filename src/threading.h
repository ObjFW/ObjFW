/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS))
# error No threads available!
#endif

#include <math.h>

#import "OFObject.h"

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
# include <sched.h>
typedef pthread_t of_thread_t;
typedef pthread_key_t of_tlskey_t;
typedef pthread_mutex_t of_mutex_t;
typedef pthread_cond_t of_condition_t;
typedef pthread_once_t of_once_t;
# define OF_ONCE_INIT PTHREAD_ONCE_INIT
#elif defined(OF_WINDOWS)
/*
 * winsock2.h needs to be included before windows.h. Not including it here
 * would make it impossible to use sockets after threading.h has been
 * imported.
 */
# ifdef OF_HAVE_SOCKETS
#  include <winsock2.h>
# endif
# include <windows.h>
typedef HANDLE of_thread_t;
typedef DWORD of_tlskey_t;
typedef CRITICAL_SECTION of_mutex_t;
typedef struct {
	HANDLE event;
	int count;
} of_condition_t;
typedef volatile int of_once_t;
# define OF_ONCE_INIT 0
#else
# error No threads available!
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

#if defined(OF_HAVE_RECURSIVE_PTHREAD_MUTEXES) || defined(OF_WINDOWS)
# define of_rmutex_t of_mutex_t
#else
typedef struct {
	of_mutex_t mutex;
	of_tlskey_t count;
} of_rmutex_t;
#endif

typedef struct of_thread_attr_t {
	float priority;
	size_t stackSize;
} of_thread_attr_t;

#if defined(OF_HAVE_PTHREADS)
# define of_thread_is_current(t) pthread_equal(t, pthread_self())
# define of_thread_current pthread_self
#elif defined(OF_WINDOWS)
# define of_thread_is_current(t) (t == GetCurrentThread())
# define of_thread_current GetCurrentThread
#else
# error of_thread_is_current not implemented!
# error of_thread_current not implemented!
#endif

extern bool of_thread_attr_init(of_thread_attr_t *attr);
extern bool of_thread_new(of_thread_t *thread, void (*function)(id), id object,
    const of_thread_attr_t *attr);
extern void of_thread_set_name(of_thread_t thread, const char *name);
extern bool of_thread_join(of_thread_t thread);
extern bool of_thread_detach(of_thread_t thread);
extern void OF_NO_RETURN_FUNC of_thread_exit(void);
extern void of_once(of_once_t *control, void (*func)(void));
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
extern bool of_condition_new(of_condition_t *condition);
extern bool of_condition_signal(of_condition_t *condition);
extern bool of_condition_broadcast(of_condition_t *condition);
extern bool of_condition_wait(of_condition_t *condition, of_mutex_t *mutex);
extern bool of_condition_timed_wait(of_condition_t *condition,
    of_mutex_t *mutex, of_time_interval_t timeout);
extern bool of_condition_free(of_condition_t *condition);

/* TLS keys and spinlocks are inlined for performance. */

static OF_INLINE bool
of_tlskey_new(of_tlskey_t *key)
{
#if defined(OF_HAVE_PTHREADS)
	return !pthread_key_create(key, NULL);
#elif defined(OF_WINDOWS)
	return ((*key = TlsAlloc()) != TLS_OUT_OF_INDEXES);
#else
# error of_tlskey_new not implemented!
#endif
}

static OF_INLINE void*
of_tlskey_get(of_tlskey_t key)
{
#if defined(OF_HAVE_PTHREADS)
	return pthread_getspecific(key);
#elif defined(OF_WINDOWS)
	return TlsGetValue(key);
#else
# error of_tlskey_get not implemented!
#endif
}

static OF_INLINE bool
of_tlskey_set(of_tlskey_t key, void *ptr)
{
#if defined(OF_HAVE_PTHREADS)
	return !pthread_setspecific(key, ptr);
#elif defined(OF_WINDOWS)
	return TlsSetValue(key, ptr);
#else
# error of_tlskey_set not implemented!
#endif
}

static OF_INLINE bool
of_tlskey_free(of_tlskey_t key)
{
#if defined(OF_HAVE_PTHREADS)
	return !pthread_key_delete(key);
#elif defined(OF_WINDOWS)
	return TlsFree(key);
#else
# error of_tlskey_free not implemented!
#endif
}

static OF_INLINE bool
of_spinlock_new(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	*spinlock = 0;
	return true;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return !pthread_spin_init(spinlock, 0);
#else
	return of_mutex_new(spinlock);
#endif
}

static OF_INLINE bool
of_spinlock_trylock(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	return of_atomic_int_cmpswap(spinlock, 0, 1);
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return !pthread_spin_trylock(spinlock);
#else
	return of_mutex_trylock(spinlock);
#endif
}

static OF_INLINE bool
of_spinlock_lock(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
# if defined(OF_HAVE_SCHED_YIELD) || defined(OF_WINDOWS)
	size_t i;

	for (i = 0; i < OF_SPINCOUNT; i++)
		if (of_spinlock_trylock(spinlock))
			return true;

	while (!of_spinlock_trylock(spinlock))
#  ifndef OF_WINDOWS
		sched_yield();
#  else
		Sleep(0);
#  endif
# else
	while (!of_spinlock_trylock(spinlock));
# endif

	return true;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return !pthread_spin_lock(spinlock);
#else
	return of_mutex_lock(spinlock);
#endif
}

static OF_INLINE bool
of_spinlock_unlock(of_spinlock_t *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	return of_atomic_int_cmpswap(spinlock, 1, 0);
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return !pthread_spin_unlock(spinlock);
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
	return !pthread_spin_destroy(spinlock);
#else
	return of_mutex_free(spinlock);
#endif
}
