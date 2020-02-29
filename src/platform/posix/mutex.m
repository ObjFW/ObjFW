/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

bool
of_mutex_new(of_mutex_t *mutex)
{
	return (pthread_mutex_init(mutex, NULL) == 0);
}

bool
of_mutex_lock(of_mutex_t *mutex)
{
	return (pthread_mutex_lock(mutex) == 0);
}

bool
of_mutex_trylock(of_mutex_t *mutex)
{
	return (pthread_mutex_trylock(mutex) == 0);
}

bool
of_mutex_unlock(of_mutex_t *mutex)
{
	return (pthread_mutex_unlock(mutex) == 0);
}

bool
of_mutex_free(of_mutex_t *mutex)
{
	return (pthread_mutex_destroy(mutex) == 0);
}

#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
bool
of_rmutex_new(of_rmutex_t *rmutex)
{
	pthread_mutexattr_t attr;

	if (pthread_mutexattr_init(&attr) != 0)
		return false;

	if (pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE) != 0)
		return false;

	if (pthread_mutex_init(rmutex, &attr) != 0)
		return false;

	if (pthread_mutexattr_destroy(&attr) != 0)
		return false;

	return true;
}

bool
of_rmutex_lock(of_rmutex_t *rmutex)
{
	return of_mutex_lock(rmutex);
}

bool
of_rmutex_trylock(of_rmutex_t *rmutex)
{
	return of_mutex_trylock(rmutex);
}

bool
of_rmutex_unlock(of_rmutex_t *rmutex)
{
	return of_mutex_unlock(rmutex);
}

bool
of_rmutex_free(of_rmutex_t *rmutex)
{
	return of_mutex_free(rmutex);
}
#else
bool
of_rmutex_new(of_rmutex_t *rmutex)
{
	if (!of_mutex_new(&rmutex->mutex))
		return false;

	if (!of_tlskey_new(&rmutex->count))
		return false;

	return true;
}

bool
of_rmutex_lock(of_rmutex_t *rmutex)
{
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);

	if (count > 0) {
		if (!of_tlskey_set(rmutex->count, (void *)(count + 1)))
			return false;

		return true;
	}

	if (!of_mutex_lock(&rmutex->mutex))
		return false;

	if (!of_tlskey_set(rmutex->count, (void *)1)) {
		of_mutex_unlock(&rmutex->mutex);
		return false;
	}

	return true;
}

bool
of_rmutex_trylock(of_rmutex_t *rmutex)
{
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);

	if (count > 0) {
		if (!of_tlskey_set(rmutex->count, (void *)(count + 1)))
			return false;

		return true;
	}

	if (!of_mutex_trylock(&rmutex->mutex))
		return false;

	if (!of_tlskey_set(rmutex->count, (void *)1)) {
		of_mutex_unlock(&rmutex->mutex);
		return false;
	}

	return true;
}

bool
of_rmutex_unlock(of_rmutex_t *rmutex)
{
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);

	if (count > 1) {
		if (!of_tlskey_set(rmutex->count, (void *)(count - 1)))
			return false;

		return true;
	}

	if (!of_tlskey_set(rmutex->count, (void *)0))
		return false;

	if (!of_mutex_unlock(&rmutex->mutex))
		return false;

	return true;
}

bool
of_rmutex_free(of_rmutex_t *rmutex)
{
	if (!of_mutex_free(&rmutex->mutex))
		return false;

	if (!of_tlskey_free(rmutex->count))
		return false;

	return true;
}
#endif
