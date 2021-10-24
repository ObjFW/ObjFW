/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "OFPlainMutex.h"

int
OFPlainMutexNew(OFPlainMutex *mutex)
{
	return pthread_mutex_init(mutex, NULL);
}

int
OFPlainMutexLock(OFPlainMutex *mutex)
{
	return pthread_mutex_lock(mutex);
}

int
OFPlainMutexTryLock(OFPlainMutex *mutex)
{
	return pthread_mutex_trylock(mutex);
}

int
OFPlainMutexUnlock(OFPlainMutex *mutex)
{
	return pthread_mutex_unlock(mutex);
}

int
OFPlainMutexFree(OFPlainMutex *mutex)
{
	return pthread_mutex_destroy(mutex);
}

#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
int
OFPlainRecursiveMutexNew(OFPlainRecursiveMutex *rmutex)
{
	int error;
	pthread_mutexattr_t attr;

	if ((error = pthread_mutexattr_init(&attr)) != 0)
		return error;

	if ((error = pthread_mutexattr_settype(&attr,
	    PTHREAD_MUTEX_RECURSIVE)) != 0)
		return error;

	if ((error = pthread_mutex_init(rmutex, &attr)) != 0)
		return error;

	if ((error = pthread_mutexattr_destroy(&attr)) != 0)
		return error;

	return 0;
}

int
OFPlainRecursiveMutexLock(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexLock(rmutex);
}

int
OFPlainRecursiveMutexTryLock(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexTryLock(rmutex);
}

int
OFPlainRecursiveMutexUnlock(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexUnlock(rmutex);
}

int
OFPlainRecursiveMutexFree(OFPlainRecursiveMutex *rmutex)
{
	return OFPlainMutexFree(rmutex);
}
#else
int
OFPlainRecursiveMutexNew(OFPlainRecursiveMutex *rmutex)
{
	int error;

	if ((error = OFPlainMutexNew(&rmutex->mutex)) != 0)
		return error;

	if ((error = OFTLSKeyNew(&rmutex->count)) != 0)
		return error;

	return 0;
}

int
OFPlainRecursiveMutexLock(OFPlainRecursiveMutex *rmutex)
{
	uintptr_t count = (uintptr_t)OFTLSKeyGet(rmutex->count);
	int error;

	if (count > 0) {
		if ((error = OFTLSKeySet(rmutex->count,
		    (void *)(count + 1))) != 0)
			return error;

		return 0;
	}

	if ((error = OFPlainMutexLock(&rmutex->mutex)) != 0)
		return error;

	if ((error = OFTLSKeySet(rmutex->count, (void *)1)) != 0) {
		OFPlainMutexUnlock(&rmutex->mutex);
		return error;
	}

	return 0;
}

int
OFPlainRecursiveMutexTryLock(OFPlainRecursiveMutex *rmutex)
{
	uintptr_t count = (uintptr_t)OFTLSKeyGet(rmutex->count);
	int error;

	if (count > 0) {
		if ((error = OFTLSKeySet(rmutex->count,
		    (void *)(count + 1))) != 0)
			return error;

		return 0;
	}

	if ((error = OFPlainMutexTryLock(&rmutex->mutex)) != 0)
		return error;

	if ((error = OFTLSKeySet(rmutex->count, (void *)1)) != 0) {
		OFPlainMutexUnlock(&rmutex->mutex);
		return error;
	}

	return 0;
}

int
OFPlainRecursiveMutexUnlock(OFPlainRecursiveMutex *rmutex)
{
	uintptr_t count = (uintptr_t)OFTLSKeyGet(rmutex->count);
	int error;

	if (count > 1) {
		if ((error = OFTLSKeySet(rmutex->count,
		    (void *)(count - 1))) != 0)
			return error;

		return 0;
	}

	if ((error = OFTLSKeySet(rmutex->count, (void *)0)) != 0)
		return error;

	if ((error = OFPlainMutexUnlock(&rmutex->mutex)) != 0)
		return error;

	return 0;
}

int
OFPlainRecursiveMutexFree(OFPlainRecursiveMutex *rmutex)
{
	int error;

	if ((error = OFPlainMutexFree(&rmutex->mutex)) != 0)
		return error;

	if ((error = OFTLSKeyFree(rmutex->count)) != 0)
		return error;

	return 0;
}
#endif
