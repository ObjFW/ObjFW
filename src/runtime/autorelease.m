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

#import "macros.h"
#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
# import "OFTLSKey.h"
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
		_OBJC_ERROR("Failed to create TLS keys!");
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
		objc_release(objects[i]);

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
			_OBJC_ERROR("Failed to set TLS key!");
#endif
	}

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	if (OFTLSKeySet(countKey, (void *)count) != 0)
		_OBJC_ERROR("Failed to set TLS key!");
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
			_OBJC_ERROR("Failed to resize autorelease pool!");

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
		if (OFTLSKeySet(objectsKey, objects) != 0 ||
		    OFTLSKeySet(sizeKey, (void *)size) != 0)
			_OBJC_ERROR("Failed to set TLS key!");
#endif
	}

	objects[count++] = object;

#if !defined(OF_HAVE_COMPILER_TLS) && defined(OF_HAVE_THREADS)
	if (OFTLSKeySet(countKey, (void *)count) != 0)
		_OBJC_ERROR("Failed to set TLS key!");
#endif

	return object;
}
