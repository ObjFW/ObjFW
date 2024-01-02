/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
# import "OFTLSKey.h"
#endif

#ifndef OF_OBJFW_RUNTIME
@interface DummyObject
- (void)release;
@end
#endif

#ifndef OBJC_ERROR
/* This is also used with old Apple runtimes that lack autorelease pools. */
# define OBJC_ERROR(...) abort()
#endif

#if defined(OF_HAVE_COMPILER_TLS)
static thread_local id *objects = NULL;
static thread_local uintptr_t count = 0;
static thread_local uintptr_t size = 0;
#elif defined(OF_HAVE_THREADS)
static OFTLSKey objectsKey, countKey, sizeKey;
#else
static id *objects = NULL;
static uintptr_t count = 0;
static uintptr_t size = 0;
#endif

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
OF_CONSTRUCTOR()
{
	if (OFTLSKeyNew(&objectsKey) != 0 || OFTLSKeyNew(&countKey) != 0 ||
	    OFTLSKeyNew(&sizeKey) != 0)
		OBJC_ERROR("Failed to create TLS keys!");
}
#endif

void *
objc_autoreleasePoolPush(void)
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	uintptr_t count = (uintptr_t)OFTLSKeyGet(countKey);
#endif
	return (void *)count;
}

void
objc_autoreleasePoolPop(void *pool)
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	id *objects = OFTLSKeyGet(objectsKey);
	uintptr_t count = (uintptr_t)OFTLSKeyGet(countKey);
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
		objects = OFTLSKeyGet(objectsKey);
		count = (uintptr_t)OFTLSKeyGet(countKey);
#endif
	}

	count = idx;

	if (freeMem) {
		free(objects);
		objects = NULL;
#if defined(OF_HAVE_COMPILER_TLS) || !defined(OF_HAVE_THREADS)
		size = 0;
#else
		if (OFTLSKeySet(objectsKey, objects) != 0 ||
		    OFTLSKeySet(sizeKey, (void *)0) != 0)
			OBJC_ERROR("Failed to set TLS key!");
#endif
	}

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	if (OFTLSKeySet(countKey, (void *)count) != 0)
		OBJC_ERROR("Failed to set TLS key!");
#endif
}

id
_objc_rootAutorelease(id object)
{
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	id *objects = OFTLSKeyGet(objectsKey);
	uintptr_t count = (uintptr_t)OFTLSKeyGet(countKey);
	uintptr_t size = (uintptr_t)OFTLSKeyGet(sizeKey);
#endif

	if (count >= size) {
		if (size == 0)
			size = 16;
		else
			size *= 2;

		if ((objects = realloc(objects, size * sizeof(id))) == NULL)
			OBJC_ERROR("Failed to resize autorelease pool!");

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		if (OFTLSKeySet(objectsKey, objects) != 0 ||
		    OFTLSKeySet(sizeKey, (void *)size) != 0)
			OBJC_ERROR("Failed to set TLS key!");
#endif
	}

	objects[count++] = object;

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	if (OFTLSKeySet(countKey, (void *)count) != 0)
		OBJC_ERROR("Failed to set TLS key!");
#endif

	return object;
}
