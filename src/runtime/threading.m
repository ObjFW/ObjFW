/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include "config.h"

#include <stdio.h>
#include <stdlib.h>

#import "runtime.h"
#import "runtime-private.h"

static objc_mutex_t global_mutex;
static BOOL global_mutex_init = NO;

BOOL
objc_mutex_new(objc_mutex_t *mutex)
{
	if (!of_mutex_new(&mutex->mutex ))
		return NO;

	mutex->count = 0;

	return YES;
}

BOOL
objc_mutex_lock(objc_mutex_t *mutex)
{
	if (mutex->count > 0 && of_thread_is_current(mutex->owner)) {
		mutex->count++;
		return YES;
	}

	if (!of_mutex_lock(&mutex->mutex))
		return NO;

	mutex->owner = of_thread_current();
	mutex->count++;

	return YES;
}

BOOL
objc_mutex_unlock(objc_mutex_t *mutex)
{
	if (--mutex->count == 0)
		return of_mutex_unlock(&mutex->mutex);

	return YES;
}

BOOL
objc_mutex_free(objc_mutex_t *mutex)
{
	return of_mutex_free(&mutex->mutex);
}

static void
objc_global_mutex_new(void)
{
	if (!objc_mutex_new(&global_mutex))
		OBJC_ERROR("Failed to create global mutex!");

	global_mutex_init = YES;
}

void
objc_global_mutex_lock(void)
{
	if (!global_mutex_init)
		objc_global_mutex_new();

	if (!objc_mutex_lock(&global_mutex))
		OBJC_ERROR("Failed to lock global mutex!");
}

void
objc_global_mutex_unlock(void)
{
	if (!objc_mutex_unlock(&global_mutex))
		OBJC_ERROR("Failed to unlock global mutex!");
}

void
objc_global_mutex_free(void)
{
	if (!objc_mutex_free(&global_mutex))
		OBJC_ERROR("Failed to free global mutex!");
}
