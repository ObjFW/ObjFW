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

#import "macros.h"

static __thread id *objects = NULL;
static __thread id *top = NULL;
static size_t size = 0;

id
objc_autorelease(id object)
{
	return [object autorelease];
}

void*
objc_autoreleasePoolPush()
{
	ptrdiff_t offset = top - objects;

	return (void*)offset;
}

void
objc_autoreleasePoolPop(void *offset)
{
	id *pool = objects + (ptrdiff_t)offset;
	id *iter;

	for (iter = pool; iter < top; iter++)
		[*iter release];

	top = pool;
}

id
_objc_rootAutorelease(id object)
{
	if (objects == NULL) {
		if ((objects = malloc(of_pagesize)) == NULL)
			ERROR("Out of memory for autorelease pools!")

		top = objects;
	}

	if ((uintptr_t)top >= (uintptr_t)objects + size) {
		ptrdiff_t diff = top - objects;

		size += of_pagesize;
		if ((objects = realloc(objects, size)) == NULL)
			ERROR("Out of memory for autorelease pools!")

		top = objects + diff;
	}

	*top = object;
	top++;

	return object;
}
