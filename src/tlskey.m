/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "tlskey.h"

#ifdef OF_AMIGAOS
# include <exec/semaphores.h>
# include <proto/exec.h>

/*
 * As we use this file in both the runtime and ObjFW, and since AmigaOS always
 * has the runtime, use the hashtable from the runtime.
 */
# import "runtime/private.h"

static of_tlskey_t firstKey = NULL, lastKey = NULL;
static struct SignalSemaphore semaphore;

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
	InitSemaphore(&semaphore);
}
#endif

bool
of_tlskey_new(of_tlskey_t *key)
{
#if defined(OF_HAVE_PTHREADS)
	return (pthread_key_create(key, NULL) == 0);
#elif defined(OF_WINDOWS)
	return ((*key = TlsAlloc()) != TLS_OUT_OF_INDEXES);
#elif defined(OF_AMIGAOS)
	if ((*key = malloc(sizeof(**key))) == NULL)
		return false;

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
	return true;
#endif
}

bool
of_tlskey_free(of_tlskey_t key)
{
#if defined(OF_HAVE_PTHREADS)
	return (pthread_key_delete(key) == 0);
#elif defined(OF_WINDOWS)
	return TlsFree(key);
#elif defined(OF_AMIGAOS)
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

		objc_hashtable_free(key->table);
		free(key);
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	return true;
#endif
}

#ifdef OF_AMIGAOS
void *
of_tlskey_get(of_tlskey_t key)
{
	void *ret;

	ObtainSemaphore(&semaphore);
	@try {
		if (key->table == NULL)
			return NULL;

		ret = objc_hashtable_get(key->table, FindTask(NULL));
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	return ret;
}

bool
of_tlskey_set(of_tlskey_t key, void *ptr)
{
	ObtainSemaphore(&semaphore);
	@try {
		struct Task *task = FindTask(NULL);

		if (key->table == NULL)
			key->table = objc_hashtable_new(hashFunc, equalFunc, 2);

		if (ptr == NULL)
			objc_hashtable_delete(key->table, task);
		else
			objc_hashtable_set(key->table, task, ptr);
	} @catch (id e) {
		return false;
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	return true;
}

void
of_tlskey_thread_exited(void)
{
	ObtainSemaphore(&semaphore);
	@try {
		struct Task *task = FindTask(NULL);

		for (of_tlskey_t iter = firstKey; iter != NULL;
		    iter = iter->next)
			if (iter->table != NULL)
				objc_hashtable_delete(iter->table, task);
	} @finally {
		ReleaseSemaphore(&semaphore);
	}
}
#endif
