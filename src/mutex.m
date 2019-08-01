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

#include "config.h"

#import "mutex.h"

#if defined(OF_HAVE_PTHREADS)
# include "mutex_pthread.m"
#elif defined(OF_WINDOWS)
# include "mutex_winapi.m"
#elif defined(OF_AMIGAOS)
# include "mutex_amiga.m"
#endif

#if !defined(OF_HAVE_RECURSIVE_PTHREAD_MUTEXES) && !defined(OF_WINDOWS) && \
    !defined(OF_AMIGAOS)
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
