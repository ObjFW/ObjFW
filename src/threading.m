/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "threading.h"

#if defined(OF_HAVE_PTHREADS)
# include "threading_pthread.m"
#elif defined(_WIN32)
# include "threading_winapi.m"
#else
# error No threads available!
#endif

bool
of_rmutex_new(of_rmutex_t *rmutex)
{
#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
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
#else
	if (!of_mutex_new(&rmutex->mutex))
		return false;

	if (!of_tlskey_new(&rmutex->count))
		return false;

	return true;
#endif
}

bool
of_rmutex_lock(of_rmutex_t *rmutex)
{
#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
	return of_mutex_lock(rmutex);
#else
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);

	if (count > 0) {
		if (!of_tlskey_set(rmutex->count, (void*)(count + 1)))
			return false;

		return true;
	}

	if (!of_mutex_lock(&rmutex->mutex))
		return false;

	if (!of_tlskey_set(rmutex->count, (void*)1)) {
		of_mutex_unlock(&rmutex->mutex);
		return false;
	}

	return true;
#endif
}

bool
of_rmutex_trylock(of_rmutex_t *rmutex)
{
#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
	return of_mutex_trylock(rmutex);
#else
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);

	if (count > 0) {
		if (!of_tlskey_set(rmutex->count, (void*)(count + 1)))
			return false;

		return true;
	}

	if (!of_mutex_trylock(&rmutex->mutex))
		return false;

	if (!of_tlskey_set(rmutex->count, (void*)1)) {
		of_mutex_unlock(&rmutex->mutex);
		return false;
	}

	return true;
#endif
}

bool
of_rmutex_unlock(of_rmutex_t *rmutex)
{
#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
	return of_mutex_unlock(rmutex);
#else
	uintptr_t count = (uintptr_t)of_tlskey_get(rmutex->count);

	if (count > 1) {
		if (!of_tlskey_set(rmutex->count, (void*)(count - 1)))
			return false;

		return true;
	}

	if (!of_tlskey_set(rmutex->count, (void*)0))
		return false;

	if (!of_mutex_unlock(&rmutex->mutex))
		return false;

	return true;
#endif
}

bool
of_rmutex_free(of_rmutex_t *rmutex)
{
#ifdef OF_HAVE_RECURSIVE_PTHREAD_MUTEXES
	return of_mutex_free(rmutex);
#else
	if (!of_mutex_free(&rmutex->mutex))
		return false;

	if (!of_tlskey_free(rmutex->count))
		return false;

	return true;
#endif
}
