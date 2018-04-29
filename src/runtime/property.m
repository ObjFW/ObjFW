/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include <string.h>

#import "ObjFW_RT.h"
#import "private.h"

#import "OFObject.h"

#ifdef OF_HAVE_THREADS
# import "threading.h"
# define NUM_SPINLOCKS 8	/* needs to be a power of 2 */
# define SPINLOCK_HASH(p) ((unsigned)((uintptr_t)p >> 4) & (NUM_SPINLOCKS - 1))
static of_spinlock_t spinlocks[NUM_SPINLOCKS];
#endif

#ifdef OF_HAVE_THREADS
OF_CONSTRUCTOR()
{
	for (size_t i = 0; i < NUM_SPINLOCKS; i++)
		if (!of_spinlock_new(&spinlocks[i]))
			OBJC_ERROR("Failed to initialize spinlocks!")
}
#endif

id
OBJC_GLUE(objc_getProperty, id self OBJC_GLUE_M68K_REG("a0"),
    SEL _cmd OBJC_GLUE_M68K_REG("a1"),
    ptrdiff_t offset OBJC_GLUE_M68K_REG("d0"),
    bool atomic OBJC_GLUE_M68K_REG("d1"))
{
	if (atomic) {
		id *ptr = (id *)(void *)((char *)self + offset);
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(ptr);

		OF_ENSURE(of_spinlock_lock(&spinlocks[hash]));
		@try {
			return [[*ptr retain] autorelease];
		} @finally {
			OF_ENSURE(of_spinlock_unlock(&spinlocks[hash]));
		}
#else
		return [[*ptr retain] autorelease];
#endif
	}

	return *(id *)(void *)((char *)self + offset);
}

void
OBJC_GLUE(objc_setProperty, id self OBJC_GLUE_M68K_REG("a0"),
    SEL _cmd OBJC_GLUE_M68K_REG("a1"),
    ptrdiff_t offset OBJC_GLUE_M68K_REG("d0"),
    id value OBJC_GLUE_M68K_REG("a2"), bool atomic OBJC_GLUE_M68K_REG("d1"),
    signed char copy OBJC_GLUE_M68K_REG("d2"))
{
	if (atomic) {
		id *ptr = (id *)(void *)((char *)self + offset);
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(ptr);

		OF_ENSURE(of_spinlock_lock(&spinlocks[hash]));
		@try {
#endif
			id old = *ptr;

			switch (copy) {
			case 0:
				*ptr = [value retain];
				break;
			case 2:
				*ptr = [value mutableCopy];
				break;
			default:
				*ptr = [value copy];
			}

			[old release];
#ifdef OF_HAVE_THREADS
		} @finally {
			OF_ENSURE(of_spinlock_unlock(&spinlocks[hash]));
		}
#endif

		return;
	}

	id *ptr = (id *)(void *)((char *)self + offset);
	id old = *ptr;

	switch (copy) {
	case 0:
		*ptr = [value retain];
		break;
	case 2:
		*ptr = [value mutableCopy];
		break;
	default:
		*ptr = [value copy];
	}

	[old release];
}

/* The following methods are only required for GCC >= 4.6 */
void
OBJC_GLUE(objc_getPropertyStruct, void *dest OBJC_GLUE_M68K_REG("a0"),
    const void *src OBJC_GLUE_M68K_REG("a1"),
    ptrdiff_t size OBJC_GLUE_M68K_REG("d0"),
    bool atomic OBJC_GLUE_M68K_REG("d1"), bool strong OBJC_GLUE_M68K_REG("d2"))
{
	if (atomic) {
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(src);

		OF_ENSURE(of_spinlock_lock(&spinlocks[hash]));
#endif
		memcpy(dest, src, size);
#ifdef OF_HAVE_THREADS
		OF_ENSURE(of_spinlock_unlock(&spinlocks[hash]));
#endif

		return;
	}

	memcpy(dest, src, size);
}

void
OBJC_GLUE(objc_setPropertyStruct, void *dest OBJC_GLUE_M68K_REG("a0"),
    const void *src OBJC_GLUE_M68K_REG("a1"),
    ptrdiff_t size OBJC_GLUE_M68K_REG("d0"),
    bool atomic OBJC_GLUE_M68K_REG("d1"), bool strong OBJC_GLUE_M68K_REG("d2"))
{
	if (atomic) {
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(src);

		OF_ENSURE(of_spinlock_lock(&spinlocks[hash]));
#endif
		memcpy(dest, src, size);
#ifdef OF_HAVE_THREADS
		OF_ENSURE(of_spinlock_unlock(&spinlocks[hash]));
#endif

		return;
	}

	memcpy(dest, src, size);
}
