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

#import "tlskey.h"

#ifdef OF_AMIGAOS
# include <exec/semaphores.h>
# include <proto/exec.h>

# import "OFMapTable.h"
# import "OFList.h"

static const of_map_table_functions_t functions = { NULL };
static OFList *allKeys = nil;
static struct SignalSemaphore semaphore;

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
	if ((*key = calloc(1, sizeof(**key))) == NULL)
		return false;

	/*
	 * We create the map table lazily, as some TLS are created in
	 * constructors, at which time OFMapTable is not available yet.
	 */

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
		[allKeys removeListObject: key->listObject];
		[key->mapTable release];
		free(key);
	} @finally {
		ReleaseSemaphore(&semaphore);
	}

	return true;
#endif
}

#ifdef OF_AMIGAOS
static void
unsafeCreateMapTable(of_tlskey_t key)
{
	key->mapTable = [[OFMapTable alloc] initWithKeyFunctions: functions
						 objectFunctions: functions];

	if (allKeys == nil)
		allKeys = [[OFList alloc] init];

	key->listObject = [allKeys appendObject: key->mapTable];
}

void *
of_tlskey_get(of_tlskey_t key)
{
	void *ret;

	ObtainSemaphore(&semaphore);
	@try {
		if (key->mapTable == NULL)
			unsafeCreateMapTable(key);

		ret = [key->mapTable objectForKey: FindTask(NULL)];
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

		if (key->mapTable == NULL)
			unsafeCreateMapTable(key);

		if (ptr == NULL)
			[key->mapTable removeObjectForKey: task];
		else
			[key->mapTable setObject: ptr
					  forKey: task];
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

		for (of_list_object_t *iter = allKeys.firstListObject;
		    iter != NULL; iter = iter->next)
			[iter->object removeObjectForKey: task];
	} @finally {
		ReleaseSemaphore(&semaphore);
	}
}
#endif
