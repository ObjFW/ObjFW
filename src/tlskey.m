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
# import "OFMapTable.h"

static const of_map_table_functions_t functions = { NULL };
#endif

bool
of_tlskey_new(of_tlskey_t *key)
{
#if defined(OF_HAVE_PTHREADS)
	return (pthread_key_create(key, NULL) == 0);
#elif defined(OF_WINDOWS)
	return ((*key = TlsAlloc()) != TLS_OUT_OF_INDEXES);
#elif defined(OF_AMIGAOS)
	if ((*key = calloc(1, sizeof(*key))) == NULL)
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
	[key->mapTable release];
	free(key);

	return true;
#endif
}

#ifdef OF_AMIGAOS
void *
of_tlskey_get(of_tlskey_t key)
{
	void *ret;

	Forbid();
	@try {
		if (key->mapTable == NULL)
			key->mapTable = [[OFMapTable alloc]
			    initWithKeyFunctions: functions
				 objectFunctions: functions];

		ret = [key->mapTable objectForKey: FindTask(NULL)];
	} @finally {
		Permit();
	}

	return ret;
}

bool
of_tlskey_set(of_tlskey_t key, void *ptr)
{
	Forbid();
	@try {
		struct Task *task = FindTask(NULL);

		if (key->mapTable == NULL)
			key->mapTable = [[OFMapTable alloc]
			    initWithKeyFunctions: functions
				 objectFunctions: functions];

		if (ptr == NULL)
			[key->mapTable removeObjectForKey: task];
		else
			[key->mapTable setObject: ptr
					  forKey: task];
	} @catch (id e) {
		return false;
	} @finally {
		Permit();
	}

	return true;
}
#endif
