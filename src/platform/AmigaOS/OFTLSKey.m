/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFTLSKey.h"

#define Class IntuitionClass
#include <exec/semaphores.h>
#include <proto/exec.h>
#undef Class

/*
 * As we use this file in both the runtime and ObjFW, and since AmigaOS always
 * has the runtime, use the hashtable from the runtime.
 */
#import "runtime/private.h"

static OFTLSKey firstKey = NULL, lastKey = NULL;
static struct SignalSemaphore semaphore;
static bool semaphoreInitialized = false;

static uint32_t
hashFunc(const void *ptr)
{
	return (uint32_t)(uintptr_t)ptr;
}

static bool
equalFunc(const void *ptr1, const void *ptr2)
{
	return (ptr1 == ptr2);
}

OF_CONSTRUCTOR()
{
	if (!semaphoreInitialized) {
		InitSemaphore(&semaphore);
		semaphoreInitialized = true;
	}
}

int
OFTLSKeyNew(OFTLSKey *key)
{
	if (!semaphoreInitialized) {
		/*
		 * We might be called from another constructor, while ours has
		 * not run yet. This is safe, as the constructor is definitely
		 * run before a thread is spawned.
		 */
		InitSemaphore(&semaphore);
		semaphoreInitialized = true;
	}

	if ((*key = malloc(sizeof(**key))) == NULL)
		return ENOMEM;

	(*key)->table = NULL;

	ObtainSemaphore(&semaphore);
	@try {
		(*key)->next = NULL;
		(*key)->previous = lastKey;

		if (lastKey != NULL)
			lastKey->next = *key;

		lastKey = *key;

		if (firstKey == NULL)
			firstKey = *key;
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	/* We create the hash table lazily. */
	return 0;
}

int
OFTLSKeyFree(OFTLSKey key)
{
	ObtainSemaphore(&semaphore);
	@try {
		if (key->previous != NULL)
			key->previous->next = key->next;
		if (key->next != NULL)
			key->next->previous = key->previous;

		if (firstKey == key)
			firstKey = key->next;
		if (lastKey == key)
			lastKey = key->previous;

		_objc_hashtable_free(key->table);
		free(key);
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	return 0;
}

void *
OFTLSKeyGet(OFTLSKey key)
{
	void *ret;

	ObtainSemaphore(&semaphore);
	@try {
		if (key->table == NULL)
			return NULL;

		ret = _objc_hashtable_get(key->table, FindTask(NULL));
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	return ret;
}

int
OFTLSKeySet(OFTLSKey key, void *ptr)
{
	ObtainSemaphore(&semaphore);
	@try {
		struct Task *task = FindTask(NULL);

		if (key->table == NULL)
			key->table = _objc_hashtable_new(hashFunc, equalFunc,
			    2);

		if (ptr == NULL)
			_objc_hashtable_delete(key->table, task);
		else
			_objc_hashtable_set(key->table, task, ptr);
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	return 0;
}

void
OFTLSKeyThreadExited(void)
{
	ObtainSemaphore(&semaphore);
	@try {
		struct Task *task = FindTask(NULL);

		for (OFTLSKey iter = firstKey; iter != NULL; iter = iter->next)
			if (iter->table != NULL)
				_objc_hashtable_delete(iter->table, task);
	} @finally {
		ReleaseSemaphore(&semaphore);
	}
}
