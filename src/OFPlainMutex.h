/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include "objfw-defs.h"

#include <errno.h>

#include "platform.h"

#if !defined(OF_HAVE_THREADS) || \
    (!defined(OF_HAVE_PTHREADS) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS))
# error No mutexes available!
#endif

#import "macros.h"

/** @file */

#if defined(OF_HAVE_PTHREADS)
# include <pthread.h>
typedef pthread_mutex_t OFPlainMutex;
#elif defined(OF_WINDOWS)
# include <windows.h>
typedef CRITICAL_SECTION OFPlainMutex;
#elif defined(OF_AMIGAOS)
# include <exec/semaphores.h>
typedef struct SignalSemaphore OFPlainMutex;
#endif

#if defined(OF_HAVE_ATOMIC_OPS)
# import "OFAtomic.h"
typedef volatile int OFSpinlock;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
typedef pthread_spinlock_t OFSpinlock;
#else
typedef OFPlainMutex OFSpinlock;
#endif

#ifdef OF_HAVE_SCHED_YIELD
# include <sched.h>
#endif

#if defined(OF_HAVE_RECURSIVE_PTHREAD_MUTEXES) || defined(OF_WINDOWS) || \
    defined(OF_AMIGAOS)
# define OFPlainRecursiveMutex OFPlainMutex
#else
# import "OFTLSKey.h"
typedef struct {
	OFPlainMutex mutex;
	OFTLSKey count;
} OFPlainRecursiveMutex;
#endif

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Creates a new plain mutex.
 *
 * A plain mutex is similar to an @ref OFMutex, but does not use exceptions and
 * is just a lightweight wrapper around the system's mutex implementation.
 *
 * @param mutex A pointer to the mutex to create
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainMutexNew(OFPlainMutex *mutex);

/**
 * @brief Locks the specified mutex.
 *
 * @param mutex A pointer to the mutex to lock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainMutexLock(OFPlainMutex *mutex);

/**
 * @brief Tries to lock the specified mutex without blocking.
 *
 * @param mutex A pointer to the mutex to try to lock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainMutexTryLock(OFPlainMutex *mutex);

/**
 * @brief Unlocks the specified mutex.
 *
 * @param mutex A pointer to the mutex to unlock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainMutexUnlock(OFPlainMutex *mutex);

/**
 * @brief Destroys the specified mutex
 *
 * @param mutex A pointer to the mutex to destruct
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainMutexFree(OFPlainMutex *mutex);

/**
 * @brief Creates a new plain recursive mutex.
 *
 * A plain recursive mutex is similar to an @ref OFRecursiveMutex, but does not
 * use exceptions and is just a lightweight wrapper around the system's
 * recursive mutex implementation (or lacking that, a simple implementation of
 * recursive mutexes via regular mutexes).
 *
 * @param rmutex A pointer to the recursive mutex to create
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainRecursiveMutexNew(OFPlainRecursiveMutex *rmutex);

/**
 * @brief Locks the specified recursive mutex.
 *
 * @param rmutex A pointer to the recursive mutex to lock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainRecursiveMutexLock(OFPlainRecursiveMutex *rmutex);

/**
 * @brief Tries to lock the specified recursive mutex without blocking.
 *
 * @param rmutex A pointer to the recursive mutex to try to lock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainRecursiveMutexTryLock(OFPlainRecursiveMutex *rmutex);

/**
 * @brief Unlocks the specified recursive mutex.
 *
 * @param rmutex A pointer to the recursive mutex to unlock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainRecursiveMutexUnlock(OFPlainRecursiveMutex *rmutex);

/**
 * @brief Destroys the specified recursive mutex
 *
 * @param rmutex A pointer to the recursive mutex to destruct
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
extern int OFPlainRecursiveMutexFree(OFPlainRecursiveMutex *rmutex);
#ifdef __cplusplus
}
#endif

/* Spinlocks are inlined for performance. */

/**
 * @brief Yield the current thread, indicating to the OS that another thread
 *	  should execute instead.
 */
static OF_INLINE void
OFYieldThread(void)
{
#if defined(OF_HAVE_SCHED_YIELD)
	sched_yield();
#elif defined(OF_WINDOWS)
	Sleep(0);
#endif
}

/**
 * @brief Creates a new spinlock.
 *
 * @param spinlock A pointer to the spinlock to create
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
static OF_INLINE int
OFSpinlockNew(OFSpinlock *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	*spinlock = 0;
	return 0;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return pthread_spin_init(spinlock, 0);
#else
	return OFPlainMutexNew(spinlock);
#endif
}

/**
 * @brief Tries to lock a spinlock.
 *
 * @param spinlock A pointer to the spinlock to try to lock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
static OF_INLINE int
OFSpinlockTryLock(OFSpinlock *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	if (OFAtomicIntCompareAndSwap(spinlock, 0, 1)) {
		OFAcquireMemoryBarrier();
		return 0;
	}

	return EBUSY;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return pthread_spin_trylock(spinlock);
#else
	return OFPlainMutexTryLock(spinlock);
#endif
}

/**
 * @brief Locks a spinlock.
 *
 * @param spinlock A pointer to the spinlock to lock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
static OF_INLINE int
OFSpinlockLock(OFSpinlock *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	size_t i;

	for (i = 0; i < 10; i++)
		if (OFSpinlockTryLock(spinlock) == 0)
			return 0;

	while (OFSpinlockTryLock(spinlock) == EBUSY)
		OFYieldThread();

	return 0;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return pthread_spin_lock(spinlock);
#else
	return OFPlainMutexLock(spinlock);
#endif
}

/**
 * @brief Unlocks a spinlock.
 *
 * @param spinlock A pointer to the spinlock to unlock
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
static OF_INLINE int
OFSpinlockUnlock(OFSpinlock *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	bool ret = OFAtomicIntCompareAndSwap(spinlock, 1, 0);

	OFReleaseMemoryBarrier();

	return (ret ? 0 : EINVAL);
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return pthread_spin_unlock(spinlock);
#else
	return OFPlainMutexUnlock(spinlock);
#endif
}

/**
 * @brief Destroys a spinlock.
 *
 * @param spinlock A pointer to the spinlock to destroy
 * @return 0 on success, or an error number from `<errno.h>` on error
 */
static OF_INLINE int
OFSpinlockFree(OFSpinlock *spinlock)
{
#if defined(OF_HAVE_ATOMIC_OPS)
	return 0;
#elif defined(OF_HAVE_PTHREAD_SPINLOCKS)
	return pthread_spin_destroy(spinlock);
#else
	return OFPlainMutexFree(spinlock);
#endif
}
