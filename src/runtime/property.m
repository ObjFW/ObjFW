/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "runtime.h"
#import "runtime-private.h"

#import "OFObject.h"

#import "globals.h"
#define property_locks objc_globals.property_locks

#ifdef OF_HAVE_THREADS
# import "threading.h"
# define SPINLOCK_HASH(p) \
    ((unsigned)((uintptr_t)p >> 4) & (NUM_PROPERTY_LOCKS - 1))

OF_CONSTRUCTOR()
{
	for (size_t i = 0; i < NUM_PROPERTY_LOCKS; i++)
		if (!of_spinlock_new(&property_locks[i]))
			OBJC_ERROR("Failed to initialize spinlocks!")
}
#endif

id
objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic)
{
	if (atomic) {
		id *ptr = (id *)(void *)((char *)self + offset);
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(ptr);

		OF_ENSURE(of_spinlock_lock(&property_locks[hash]));
		@try {
			return [[*ptr retain] autorelease];
		} @finally {
			OF_ENSURE(of_spinlock_unlock(&property_locks[hash]));
		}
#else
		return [[*ptr retain] autorelease];
#endif
	}

	return *(id *)(void *)((char *)self + offset);
}

void
objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value, BOOL atomic,
    signed char copy)
{
	if (atomic) {
		id *ptr = (id *)(void *)((char *)self + offset);
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(ptr);

		OF_ENSURE(of_spinlock_lock(&property_locks[hash]));
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
			OF_ENSURE(of_spinlock_unlock(&property_locks[hash]));
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
objc_getPropertyStruct(void *dest, const void *src, ptrdiff_t size, BOOL atomic,
    BOOL strong)
{
	if (atomic) {
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(src);

		OF_ENSURE(of_spinlock_lock(&property_locks[hash]));
#endif
		memcpy(dest, src, size);
#ifdef OF_HAVE_THREADS
		OF_ENSURE(of_spinlock_unlock(&property_locks[hash]));
#endif

		return;
	}

	memcpy(dest, src, size);
}

void
objc_setPropertyStruct(void *dest, const void *src, ptrdiff_t size, BOOL atomic,
    BOOL strong)
{
	if (atomic) {
#ifdef OF_HAVE_THREADS
		unsigned hash = SPINLOCK_HASH(src);

		OF_ENSURE(of_spinlock_lock(&property_locks[hash]));
#endif
		memcpy(dest, src, size);
#ifdef OF_HAVE_THREADS
		OF_ENSURE(of_spinlock_unlock(&property_locks[hash]));
#endif

		return;
	}

	memcpy(dest, src, size);
}
