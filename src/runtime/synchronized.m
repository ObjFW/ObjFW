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

#include <stdio.h>
#include <stdlib.h>

#import "ObjFWRT.h"
#import "private.h"

#ifdef OF_HAVE_THREADS
# import "mutex.h"

static struct lock_s {
	id	      object;
	int	      count;
	of_rmutex_t   rmutex;
	struct lock_s *next;
} *locks = NULL;

static of_mutex_t mutex;

OF_CONSTRUCTOR()
{
	if (!of_mutex_new(&mutex))
		OBJC_ERROR("Failed to create mutex!")
}
#endif

int
objc_sync_enter(id object)
{
	if (object == nil)
		return 0;

#ifdef OF_HAVE_THREADS
	struct lock_s *lock;

	if (!of_mutex_lock(&mutex))
		OBJC_ERROR("Failed to lock mutex!");

	/* Look if we already have a lock */
	for (lock = locks; lock != NULL; lock = lock->next) {
		if (lock->object != object)
			continue;

		lock->count++;

		if (!of_mutex_unlock(&mutex))
			OBJC_ERROR("Failed to unlock mutex!");

		if (!of_rmutex_lock(&lock->rmutex))
			OBJC_ERROR("Failed to lock mutex!");

		return 0;
	}

	/* Create a new lock */
	if ((lock = malloc(sizeof(*lock))) == NULL)
		OBJC_ERROR("Failed to allocate memory for mutex!");

	if (!of_rmutex_new(&lock->rmutex))
		OBJC_ERROR("Failed to create mutex!");

	lock->object = object;
	lock->count = 1;
	lock->next = locks;

	locks = lock;

	if (!of_mutex_unlock(&mutex))
		OBJC_ERROR("Failed to unlock mutex!");

	if (!of_rmutex_lock(&lock->rmutex))
		OBJC_ERROR("Failed to lock mutex!");
#endif

	return 0;
}

int
objc_sync_exit(id object)
{
	if (object == nil)
		return 0;

#ifdef OF_HAVE_THREADS
	struct lock_s *lock, *last = NULL;

	if (!of_mutex_lock(&mutex))
		OBJC_ERROR("Failed to lock mutex!");

	for (lock = locks; lock != NULL; lock = lock->next) {
		if (lock->object != object) {
			last = lock;
			continue;
		}

		if (!of_rmutex_unlock(&lock->rmutex))
			OBJC_ERROR("Failed to unlock mutex!");

		if (--lock->count == 0) {
			if (!of_rmutex_free(&lock->rmutex))
				OBJC_ERROR("Failed to destroy mutex!");

			if (last != NULL)
				last->next = lock->next;
			if (locks == lock)
				locks = lock->next;

			free(lock);
		}

		if (!of_mutex_unlock(&mutex))
			OBJC_ERROR("Failed to unlock mutex!");

		return 0;
	}

	OBJC_ERROR("objc_sync_exit() was called for an object not locked!");
#else
	return 0;
#endif
}
