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
extern int OFPlainMutexNew(OFPlainMutex *mutex);
extern int OFPlainMutexLock(OFPlainMutex *mutex);
extern int OFPlainMutexTryLock(OFPlainMutex *mutex);
extern int OFPlainMutexUnlock(OFPlainMutex *mutex);
extern int OFPlainMutexFree(OFPlainMutex *mutex);
extern int OFPlainRecursiveMutexNew(OFPlainRecursiveMutex *rmutex);
extern int OFPlainRecursiveMutexLock(OFPlainRecursiveMutex *rmutex);
extern int OFPlainRecursiveMutexTryLock(OFPlainRecursiveMutex *rmutex);
extern int OFPlainRecursiveMutexUnlock(OFPlainRecursiveMutex *rmutex);
extern int OFPlainRecursiveMutexFree(OFPlainRecursiveMutex *rmutex);
#ifdef __cplusplus
}
#endif

/* Spinlocks are inlined for performance. */

static OF_INLINE void
OFYieldThread(void)
{
#if defined(OF_HAVE_SCHED_YIELD)
	sched_yield();
#elif defined(OF_WINDOWS)
	Sleep(0);
#endif
}

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
