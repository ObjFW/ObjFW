/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
# import "OFPlainMutex.h"

static struct Lock {
	id object;
	int count;
	OFPlainRecursiveMutex rmutex;
	struct Lock *next;
} *locks = NULL;

static OFPlainMutex mutex;

OF_CONSTRUCTOR()
{
	if (OFPlainMutexNew(&mutex) != 0)
		OBJC_ERROR("Failed to create mutex!");
}
#endif

int
objc_sync_enter(id object)
{
	if (object == nil)
		return 0;

#ifdef OF_HAVE_THREADS
	struct Lock *lock;

	if (OFPlainMutexLock(&mutex) != 0)
		OBJC_ERROR("Failed to lock mutex!");

	/* Look if we already have a lock */
	for (lock = locks; lock != NULL; lock = lock->next) {
		if (lock->object != object)
			continue;

		lock->count++;

		if (OFPlainMutexUnlock(&mutex) != 0)
			OBJC_ERROR("Failed to unlock mutex!");

		if (OFPlainRecursiveMutexLock(&lock->rmutex) != 0)
			OBJC_ERROR("Failed to lock mutex!");

		return 0;
	}

	/* Create a new lock */
	if ((lock = malloc(sizeof(*lock))) == NULL)
		OBJC_ERROR("Failed to allocate memory for mutex!");

	if (OFPlainRecursiveMutexNew(&lock->rmutex) != 0)
		OBJC_ERROR("Failed to create mutex!");

	lock->object = object;
	lock->count = 1;
	lock->next = locks;

	locks = lock;

	if (OFPlainMutexUnlock(&mutex) != 0)
		OBJC_ERROR("Failed to unlock mutex!");

	if (OFPlainRecursiveMutexLock(&lock->rmutex) != 0)
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
	struct Lock *lock, *last = NULL;

	if (OFPlainMutexLock(&mutex) != 0)
		OBJC_ERROR("Failed to lock mutex!");

	for (lock = locks; lock != NULL; lock = lock->next) {
		if (lock->object != object) {
			last = lock;
			continue;
		}

		if (OFPlainRecursiveMutexUnlock(&lock->rmutex) != 0)
			OBJC_ERROR("Failed to unlock mutex!");

		if (--lock->count == 0) {
			if (OFPlainRecursiveMutexFree(&lock->rmutex) != 0)
				OBJC_ERROR("Failed to destroy mutex!");

			if (last != NULL)
				last->next = lock->next;
			if (locks == lock)
				locks = lock->next;

			free(lock);
		}

		if (OFPlainMutexUnlock(&mutex) != 0)
			OBJC_ERROR("Failed to unlock mutex!");

		return 0;
	}

	OBJC_ERROR("objc_sync_exit() was called for an unlocked object!");
#else
	return 0;
#endif
}
