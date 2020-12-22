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

#include <stdio.h>
#include <stdlib.h>

#ifdef OF_OBJFW_RUNTIME
# import "ObjFWRT.h"
# import "private.h"
#else
# import <objc/runtime.h>
#endif

#import "macros.h"
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
# import "tlskey.h"
#endif

#ifndef OF_OBJFW_RUNTIME
@interface DummyObject
- (void)release;
@end
#endif

#if defined(OF_HAVE_COMPILER_TLS)
static thread_local id *objects = NULL;
static thread_local uintptr_t count = 0;
static thread_local uintptr_t size = 0;
#elif defined(OF_HAVE_THREADS)
static of_tlskey_t objectsKey, countKey, sizeKey;
#else
static id *objects = NULL;
static uintptr_t count = 0;
static uintptr_t size = 0;
#endif

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
OF_CONSTRUCTOR()
{
	OF_ENSURE(of_tlskey_new(&objectsKey) == 0);
	OF_ENSURE(of_tlskey_new(&countKey) == 0);
	OF_ENSURE(of_tlskey_new(&sizeKey) == 0);
}
#endif

void *
objc_autoreleasePoolPush()
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	uintptr_t count = (uintptr_t)of_tlskey_get(countKey);
#endif
	return (void *)count;
}

void
objc_autoreleasePoolPop(void *pool)
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	id *objects = of_tlskey_get(objectsKey);
	uintptr_t count = (uintptr_t)of_tlskey_get(countKey);
#endif
	uintptr_t idx = (uintptr_t)pool;
	bool freeMem = false;

	if (idx == (uintptr_t)-1) {
		idx++;
		freeMem = true;
	}

	for (uintptr_t i = idx; i < count; i++) {
		[objects[i] release];

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		objects = of_tlskey_get(objectsKey);
		count = (uintptr_t)of_tlskey_get(countKey);
#endif
	}

	count = idx;

	if (freeMem) {
		free(objects);
		objects = NULL;
#if defined(OF_HAVE_COMPILER_TLS) || !defined(OF_HAVE_THREADS)
		size = 0;
#else
		OF_ENSURE(of_tlskey_set(objectsKey, objects) == 0);
		OF_ENSURE(of_tlskey_set(sizeKey, (void *)0) == 0);
#endif
	}

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OF_ENSURE(of_tlskey_set(countKey, (void *)count) == 0);
#endif
}

id
_objc_rootAutorelease(id object)
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	id *objects = of_tlskey_get(objectsKey);
	uintptr_t count = (uintptr_t)of_tlskey_get(countKey);
	uintptr_t size = (uintptr_t)of_tlskey_get(sizeKey);
#endif

	if (count >= size) {
		if (size == 0)
			size = 16;
		else
			size *= 2;

		OF_ENSURE((objects =
		    realloc(objects, size * sizeof(id))) != NULL);

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		OF_ENSURE(of_tlskey_set(objectsKey, objects) == 0);
		OF_ENSURE(of_tlskey_set(sizeKey, (void *)size) == 0);
#endif
	}

	objects[count++] = object;

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OF_ENSURE(of_tlskey_set(countKey, (void *)count) == 0);
#endif

	return object;
}
