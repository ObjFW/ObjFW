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

#import "mutex.h"

int
of_mutex_new(of_mutex_t *mutex)
{
	return pthread_mutex_init(mutex, NULL);
}

int
of_mutex_lock(of_mutex_t *mutex)
{
	return pthread_mutex_lock(mutex);
}

int
of_mutex_trylock(of_mutex_t *mutex)
{
	return pthread_mutex_trylock(mutex);
}

int
of_mutex_unlock(of_mutex_t *mutex)
{
	return pthread_mutex_unlock(mutex);
}

int
of_mutex_free(of_mutex_t *mutex)
{
	return pthread_mutex_destroy(mutex);
}

#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
int
of_rmutex_new(of_rmutex_t *rmutex)
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
of_rmutex_lock(of_rmutex_t *rmutex)
{
	return of_mutex_lock(rmutex);
}

int
of_rmutex_trylock(of_rmutex_t *rmutex)
{
	return of_mutex_trylock(rmutex);
}

int
of_rmutex_unlock(of_rmutex_t *rmutex)
{
	return of_mutex_unlock(rmutex);
}

int
of_rmutex_free(of_rmutex_t *rmutex)
{
	return of_mutex_free(rmutex);
}
#else
int
of_rmutex_new(of_rmutex_t *rmutex)
{
	int error;

	if ((error = of_mutex_new(&rmutex->mutex)) != 0)
		return error;

	if ((error = of_tlskey_new(&rmutex->count)) != 0)
		return error;

	return 0;
}

int
of_rmutex_lock(of_rmutex_t *rmutex)
{
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);
	int error;

	if (count > 0) {
		if ((error = of_tlskey_set(rmutex->count,
		    (void *)(count + 1))) != 0)
			return error;

		return 0;
	}

	if ((error = of_mutex_lock(&rmutex->mutex)) != 0)
		return error;

	if ((error = of_tlskey_set(rmutex->count, (void *)1)) != 0) {
		of_mutex_unlock(&rmutex->mutex);
		return error;
	}

	return 0;
}

int
of_rmutex_trylock(of_rmutex_t *rmutex)
{
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);
	int error;

	if (count > 0) {
		if ((error = of_tlskey_set(rmutex->count,
		    (void *)(count + 1))) != 0)
			return error;

		return 0;
	}

	if ((error = of_mutex_trylock(&rmutex->mutex)) != 0)
		return error;

	if ((error = of_tlskey_set(rmutex->count, (void *)1)) != 0) {
		of_mutex_unlock(&rmutex->mutex);
		return error;
	}

	return 0;
}

int
of_rmutex_unlock(of_rmutex_t *rmutex)
{
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);
	int error;

	if (count > 1) {
		if ((error = of_tlskey_set(rmutex->count,
		    (void *)(count - 1))) != 0)
			return error;

		return 0;
	}

	if ((error = of_tlskey_set(rmutex->count, (void *)0)) != 0)
		return error;

	if ((error = of_mutex_unlock(&rmutex->mutex)) != 0)
		return error;

	return 0;
}

int
of_rmutex_free(of_rmutex_t *rmutex)
{
	int error;

	if ((error = of_mutex_free(&rmutex->mutex)) != 0)
		return error;

	if ((error = of_tlskey_free(rmutex->count)) != 0)
		return error;

	return 0;
}
#endif
