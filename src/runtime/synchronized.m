/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
		_OBJC_ERROR("Failed to create mutex!");
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
		_OBJC_ERROR("Failed to lock mutex!");

	/* Look if we already have a lock */
	for (lock = locks; lock != NULL; lock = lock->next) {
		if (lock->object != object)
			continue;

		lock->count++;

		if (OFPlainMutexUnlock(&mutex) != 0)
			_OBJC_ERROR("Failed to unlock mutex!");

		if (OFPlainRecursiveMutexLock(&lock->rmutex) != 0)
			_OBJC_ERROR("Failed to lock mutex!");

		return 0;
	}

	/* Create a new lock */
	if ((lock = malloc(sizeof(*lock))) == NULL)
		_OBJC_ERROR("Failed to allocate memory for mutex!");

	if (OFPlainRecursiveMutexNew(&lock->rmutex) != 0)
		_OBJC_ERROR("Failed to create mutex!");

	lock->object = object;
	lock->count = 1;
	lock->next = locks;

	locks = lock;

	if (OFPlainMutexUnlock(&mutex) != 0)
		_OBJC_ERROR("Failed to unlock mutex!");

	if (OFPlainRecursiveMutexLock(&lock->rmutex) != 0)
		_OBJC_ERROR("Failed to lock mutex!");
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
		_OBJC_ERROR("Failed to lock mutex!");

	for (lock = locks; lock != NULL; lock = lock->next) {
		if (lock->object != object) {
			last = lock;
			continue;
		}

		if (OFPlainRecursiveMutexUnlock(&lock->rmutex) != 0)
			_OBJC_ERROR("Failed to unlock mutex!");

		if (--lock->count == 0) {
			if (OFPlainRecursiveMutexFree(&lock->rmutex) != 0)
				_OBJC_ERROR("Failed to destroy mutex!");

			if (last != NULL)
				last->next = lock->next;
			if (locks == lock)
				locks = lock->next;

			free(lock);
		}

		if (OFPlainMutexUnlock(&mutex) != 0)
			_OBJC_ERROR("Failed to unlock mutex!");

		return 0;
	}

	_OBJC_ERROR("objc_sync_exit() was called for an unlocked object!");
#else
	return 0;
#endif
}
