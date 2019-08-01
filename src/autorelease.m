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

#import "OFObject.h"
#import "OFSystemInfo.h"

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
# import "tlskey.h"
#endif

#if defined(OF_HAVE_COMPILER_TLS)
static thread_local id *objects = NULL;
static thread_local id *top = NULL;
static thread_local size_t size = 0;
#elif defined(OF_HAVE_THREADS)
static of_tlskey_t objectsKey, topKey, sizeKey;
#else
static id *objects = NULL;
static id *top = NULL;
static size_t size = 0;
#endif

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
OF_CONSTRUCTOR()
{
	OF_ENSURE(of_tlskey_new(&objectsKey));
	OF_ENSURE(of_tlskey_new(&topKey));
	OF_ENSURE(of_tlskey_new(&sizeKey));
}
#endif

void *
objc_autoreleasePoolPush()
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	id *top = of_tlskey_get(topKey);
	id *objects = of_tlskey_get(objectsKey);
#endif
	ptrdiff_t offset = top - objects;

	return (void *)offset;
}

void
objc_autoreleasePoolPop(void *offset)
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	id *top = of_tlskey_get(topKey);
	id *objects = of_tlskey_get(objectsKey);
#endif
	id *pool = objects + (ptrdiff_t)offset;
	id *iter;

	for (iter = pool; iter < top; iter++)
		[*iter release];

	top = pool;

	if (top == objects) {
		free(objects);

		objects = NULL;
		top = NULL;
	}

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OF_ENSURE(of_tlskey_set(topKey, top));
	OF_ENSURE(of_tlskey_set(objectsKey, objects));
#endif
}

id
_objc_rootAutorelease(id object)
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	id *top = of_tlskey_get(topKey);
	id *objects = of_tlskey_get(objectsKey);
	size_t size = (size_t)(uintptr_t)of_tlskey_get(sizeKey);
#endif

	if (objects == NULL) {
		size = [OFSystemInfo pageSize];

		OF_ENSURE((objects = malloc(size)) != NULL);

		top = objects;

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		OF_ENSURE(of_tlskey_set(objectsKey, objects));
		OF_ENSURE(of_tlskey_set(sizeKey, (void *)(uintptr_t)size));
#endif
	}

	if ((uintptr_t)top >= (uintptr_t)objects + size) {
		ptrdiff_t diff = top - objects;

		size += [OFSystemInfo pageSize];
		OF_ENSURE((objects = realloc(objects, size)) != NULL);

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		OF_ENSURE(of_tlskey_set(objectsKey, objects));
		OF_ENSURE(of_tlskey_set(sizeKey, (void *)(uintptr_t)size));
#endif

		top = objects + diff;
	}

	*top = object;
	top++;

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	OF_ENSURE(of_tlskey_set(topKey, top));
#endif

	return object;
}
