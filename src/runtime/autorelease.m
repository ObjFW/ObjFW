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

#import "OFObject.h"

#ifndef OF_COMPILER_TLS
# import "threading.h"
#endif
#import "macros.h"

#ifdef OF_COMPILER_TLS
static __thread id *objects = NULL;
static __thread id *top = NULL;
static __thread size_t size = 0;
#else
static of_tlskey_t objectsKey, topKey, sizeKey;

static void __attribute__((constructor))
init(void)
{
	if (!of_tlskey_new(&objectsKey) || !of_tlskey_new(&sizeKey) ||
	    !of_tlskey_new(&topKey))
		ERROR("Unable to create TLS key for autorelease pools!")
}
#endif

id
objc_autorelease(id object)
{
	return [object autorelease];
}

void*
objc_autoreleasePoolPush()
{
#ifndef OF_COMPILER_TLS
	id *top = of_tlskey_get(topKey);
	id *objects = of_tlskey_get(objectsKey);
#endif
	ptrdiff_t offset = top - objects;

	return (void*)offset;
}

void
objc_autoreleasePoolPop(void *offset)
{
#ifndef OF_COMPILER_TLS
	id *top = of_tlskey_get(topKey);
	id *objects = of_tlskey_get(objectsKey);
#endif
	id *pool = objects + (ptrdiff_t)offset;
	id *iter;

	for (iter = pool; iter < top; iter++)
		[*iter release];

#ifdef OF_COMPILER_TLS
	top = pool;
#else
	if (!of_tlskey_set(topKey, pool))
		ERROR("Failed to set TLS key!")
#endif
}

id
_objc_rootAutorelease(id object)
{
#ifndef OF_COMPILER_TLS
	id *top = of_tlskey_get(topKey);
	id *objects = of_tlskey_get(objectsKey);
	size_t size = (size_t)(uintptr_t)of_tlskey_get(sizeKey);
#endif

	if (objects == NULL) {
		if ((objects = malloc(of_pagesize)) == NULL)
			ERROR("Out of memory for autorelease pools!")

#ifndef OF_COMPILER_TLS
		if (!of_tlskey_set(objectsKey, objects))
			ERROR("Failed to set TLS key!")
		if (!of_tlskey_set(sizeKey, (void*)(uintptr_t)of_pagesize))
			ERROR("Failed to set TLS key!")
#endif

		top = objects;
		size = of_pagesize;
	}

	if ((uintptr_t)top >= (uintptr_t)objects + size) {
		ptrdiff_t diff = top - objects;

		size += of_pagesize;
		if ((objects = realloc(objects, size)) == NULL)
			ERROR("Out of memory for autorelease pools!")

#ifndef OF_COMPILER_TLS
		if (!of_tlskey_set(objectsKey, objects))
			ERROR("Failed to set TLS key!")
		if (!of_tlskey_set(sizeKey, (void*)(uintptr_t)size))
			ERROR("Failed to set TLS key!")
#endif

		top = objects + diff;
	}

	*top = object;
	top++;

#ifndef OF_COMPILER_TLS
	if (!of_tlskey_set(topKey, objects))
		ERROR("Failed to set TLS key!")
#endif

	return object;
}
