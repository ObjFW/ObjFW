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

#include <errno.h>

#import "mutex.h"

#include <proto/exec.h>

int
of_mutex_new(of_mutex_t *mutex)
{
	InitSemaphore(mutex);

	return 0;
}

int
of_mutex_lock(of_mutex_t *mutex)
{
	ObtainSemaphore(mutex);

	return 0;
}

int
of_mutex_trylock(of_mutex_t *mutex)
{
	if (!AttemptSemaphore(mutex))
		return EBUSY;

	return 0;
}

int
of_mutex_unlock(of_mutex_t *mutex)
{
	ReleaseSemaphore(mutex);

	return 0;
}

int
of_mutex_free(of_mutex_t *mutex)
{
	return 0;
}

int
of_rmutex_new(of_rmutex_t *rmutex)
{
	return of_mutex_new(rmutex);
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
