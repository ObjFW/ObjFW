/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import <objc/objc.h>

#import "OFExceptions.h"

#import "atomic.h"

#define NUM_SPINLOCKS 8	/* needs to be a power of 2 */
#define SPINLOCK_HASH(p) ((uintptr_t)p >> 4) & (NUM_SPINLOCKS - 1)
static of_spinlock_t spinlocks[NUM_SPINLOCKS] = {};

id
objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic)
{
	if (atomic) {
		id *ptr = (id*)((char*)self + offset);
		unsigned hash = SPINLOCK_HASH(ptr);

		of_spinlock_lock(spinlocks[hash]);

		@try {
			return [[*ptr retain] autorelease];
		} @finally {
			of_spinlock_unlock(spinlocks[hash]);
		}
	}

	return *(id*)((char*)self + offset);
}

void
objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value, BOOL atomic,
    BOOL copy)
{
	if (atomic) {
		id *ptr = (id*)((char*)self + offset);
		unsigned hash = SPINLOCK_HASH(ptr);

		of_spinlock_lock(spinlocks[hash]);

		@try {
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
		} @finally {
			of_spinlock_unlock(spinlocks[hash]);
		}

		return;
	}

	id *ptr = (id*)((char*)self + offset);
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
