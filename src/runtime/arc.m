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

#import "runtime.h"
#import "runtime-private.h"

#ifdef OF_HAVE_THREADS
# import "threading.h"
#endif

#import "OFObject.h"
#import "OFBlock.h"

struct weak_ref {
	id **locations;
	size_t count;
};

#import "globals.h"
#define weak_refs objc_globals.weak_refs
#define weak_refs_lock objc_globals.weak_refs_lock

static uint32_t
obj_hash(const void *obj)
{
	return (uint32_t)(uintptr_t)obj;
}

static bool
obj_equal(const void *obj1, const void *obj2)
{
	return (obj1 == obj2);
}

OF_CONSTRUCTOR()
{
	weak_refs = objc_hashtable_new(obj_hash, obj_equal, 2);

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_new(&weak_refs_lock))
		OBJC_ERROR("Failed to create spinlock!")
#endif
}

id
objc_retain(id object)
{
	return [object retain];
}

id
objc_retainBlock(id block)
{
	return (id)_Block_copy(block);
}

id
objc_retainAutorelease(id object)
{
	return [[object retain] autorelease];
}

void
objc_release(id object)
{
	[object release];
}

id
objc_autorelease(id object)
{
	return [object autorelease];
}

id
objc_autoreleaseReturnValue(id object)
{
	return objc_autorelease(object);
}

id
objc_retainAutoreleaseReturnValue(id object)
{
	return objc_autoreleaseReturnValue(objc_retain(object));
}

id
objc_retainAutoreleasedReturnValue(id object)
{
	return objc_retain(object);
}

id
objc_storeStrong(id *object, id value)
{
	if (*object != value) {
		id old = *object;
		*object = objc_retain(value);
		objc_release(old);
	}

	return value;
}

id
objc_storeWeak(id *object, id value)
{
	struct weak_ref *old;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&weak_refs_lock))
		OBJC_ERROR("Failed to lock spinlock!")
#endif

	if (*object != nil &&
	    (old = objc_hashtable_get(weak_refs, *object)) != NULL) {
		for (size_t i = 0; i < old->count; i++) {
			if (old->locations[i] == object) {
				if (--old->count == 0) {
					objc_hashtable_delete(weak_refs,
					    *object);
					free(old->locations);
					free(old);
				} else {
					id **locations;

					old->locations[i] =
					    old->locations[old->count];

					/*
					 * We don't care if making it smaller
					 * fails.
					 */
					if ((locations = realloc(old->locations,
					    old->count * sizeof(id *))) != NULL)
						old->locations = locations;
				}

				break;
			}
		}
	}

	if (value != nil && class_respondsToSelector(object_getClass(value),
	    @selector(allowsWeakReference)) && [value allowsWeakReference]) {
		struct weak_ref *ref = objc_hashtable_get(weak_refs, value);

		if (ref == NULL) {
			if ((ref = calloc(1, sizeof(*ref))) == NULL)
				OBJC_ERROR("Not enough memory to allocate weak "
				    "reference!");

			objc_hashtable_set(weak_refs, value, ref);
		}

		if ((ref->locations = realloc(ref->locations,
		    (ref->count + 1) * sizeof(id *))) == NULL)
			OBJC_ERROR("Not enough memory to allocate weak "
			    "reference!")

		ref->locations[ref->count++] = object;
	} else
		value = nil;

	*object = value;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&weak_refs_lock))
		OBJC_ERROR("Failed to unlock spinlock!")
#endif

	return value;
}

id
objc_loadWeakRetained(id *object)
{
	id value = nil;
	struct weak_ref *ref;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&weak_refs_lock))
		OBJC_ERROR("Failed to lock spinlock!")
#endif

	if ((ref = objc_hashtable_get(weak_refs, *object)) != NULL)
		value = *object;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&weak_refs_lock))
		OBJC_ERROR("Failed to unlock spinlock!")
#endif

	if (class_respondsToSelector(object_getClass(value),
	    @selector(retainWeakReference)) && [value retainWeakReference])
		return value;

	return nil;
}

id
objc_initWeak(id *object, id value)
{
	*object = nil;
	return objc_storeWeak(object, value);
}

void
objc_destroyWeak(id *object)
{
	objc_storeWeak(object, nil);
}

id
objc_loadWeak(id *object)
{
	return objc_autorelease(objc_loadWeakRetained(object));
}

void
objc_copyWeak(id *dest, id *src)
{
	objc_release(objc_initWeak(dest, objc_loadWeakRetained(src)));
}

void
objc_moveWeak(id *dest, id *src)
{
	struct weak_ref *ref;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&weak_refs_lock))
		OBJC_ERROR("Failed to lock spinlock!")
#endif

	if ((ref = objc_hashtable_get(weak_refs, *src)) != NULL) {
		for (size_t i = 0; i < ref->count; i++) {
			if (ref->locations[i] == src) {
				ref->locations[i] = dest;
				break;
			}
		}
	}

	*dest = *src;
	*src = nil;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&weak_refs_lock))
		OBJC_ERROR("Failed to unlock spinlock!")
#endif
}

void
objc_zero_weak_references(id value)
{
	struct weak_ref *ref;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&weak_refs_lock))
		OBJC_ERROR("Failed to lock spinlock!")
#endif

	if ((ref = objc_hashtable_get(weak_refs, value)) != NULL) {
		for (size_t i = 0; i < ref->count; i++)
			*ref->locations[i] = nil;

		objc_hashtable_delete(weak_refs, value);
		free(ref->locations);
		free(ref);
	}

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&weak_refs_lock))
		OBJC_ERROR("Failed to unlock spinlock!")
#endif
}
