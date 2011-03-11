/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#include <assert.h>

#import "OFObject.h"

#ifdef OF_THREADS
# import "threading.h"
# define NUM_SPINLOCKS 8	/* needs to be a power of 2 */
# define SPINLOCK_HASH(p) ((uintptr_t)p >> 4) & (NUM_SPINLOCKS - 1)
static of_spinlock_t spinlocks[NUM_SPINLOCKS];
#endif

BOOL
objc_properties_init()
{
#ifdef OF_THREADS
	size_t i;

	for (i = 0; i < NUM_SPINLOCKS; i++)
		if (!of_spinlock_new(&spinlocks[i]))
			return NO;
#endif

	return YES;
}

id
objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic)
{
	if (atomic) {
		id *ptr = (id*)(void*)((char*)self + offset);
#ifdef OF_THREADS
		unsigned hash = SPINLOCK_HASH(ptr);

		assert(of_spinlock_lock(&spinlocks[hash]));

		@try {
			return [[*ptr retain] autorelease];
		} @finally {
			assert(of_spinlock_unlock(&spinlocks[hash]));
		}
#else
		return [[*ptr retain] autorelease];
#endif
	}

	return *(id*)(void*)((char*)self + offset);
}

void
objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value, BOOL atomic,
    BOOL copy)
{
	if (atomic) {
		id *ptr = (id*)(void*)((char*)self + offset);
#ifdef OF_THREADS
		unsigned hash = SPINLOCK_HASH(ptr);

		assert(of_spinlock_lock(&spinlocks[hash]));

		@try {
#endif
			id old = *ptr;

			switch (copy) {
			case 0:
				*ptr = [value retain];
				break;
			case 2:
				/*
				 * Apple uses this to indicate that the copy
				 * should be mutable. Please hit them for
				 * abusing a poor BOOL!
				 */
				*ptr = [value mutableCopy];
				break;
			default:
				*ptr = [value copy];
			}

			[old release];
#ifdef OF_THREADS
		} @finally {
			assert(of_spinlock_unlock(&spinlocks[hash]));
		}
#endif

		return;
	}

	id *ptr = (id*)(void*)((char*)self + offset);
	id old = *ptr;

	switch (copy) {
	case 0:
		*ptr = [value retain];
		break;
	case 2:
		/*
		 * Apple uses this to indicate that the copy should be mutable.
		 * Please hit them for abusing a poor BOOL!
		 */
		*ptr = [value mutableCopy];
		break;
	default:
		*ptr = [value copy];
	}

	[old release];
}
