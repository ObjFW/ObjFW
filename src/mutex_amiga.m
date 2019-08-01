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

#include <proto/exec.h>

bool
of_mutex_new(of_mutex_t *mutex)
{
	InitSemaphore(mutex);

	return true;
}

bool
of_mutex_lock(of_mutex_t *mutex)
{
	ObtainSemaphore(mutex);

	return true;
}

bool
of_mutex_trylock(of_mutex_t *mutex)
{
	return AttemptSemaphore(mutex);
}

bool
of_mutex_unlock(of_mutex_t *mutex)
{
	ReleaseSemaphore(mutex);

	return true;
}

bool
of_mutex_free(of_mutex_t *mutex)
{
	return true;
}

bool
of_rmutex_new(of_rmutex_t *rmutex)
{
	return of_mutex_new(rmutex);
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
