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
#endif
