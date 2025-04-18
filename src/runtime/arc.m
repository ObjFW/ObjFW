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

#ifdef OF_OBJFW_RUNTIME
# import "ObjFWRT.h"
# import "private.h"
#else
# import "OFObject.h"
# import "OFMapTable.h"
#endif

#import "pre_ivar.h"

#ifdef OF_HAVE_ATOMIC_OPS
# import "OFAtomic.h"
#endif

struct WeakRef {
	id **locations;
	size_t count;
};

#ifdef OF_OBJFW_RUNTIME
typedef struct objc_hashtable objc_hashtable;

/* Inlined for performance. */
static OF_INLINE bool
object_isTaggedPointer_fast(id object)
{
	uintptr_t pointer = (uintptr_t)object;

	return pointer & 1;
}

/* Inlined and unncessary checks dropped for performance. */
static OF_INLINE Class
object_getClass_fast(id object_)
{
	struct objc_object *object = (struct objc_object *)object_;

	return object->isa;
}
#else
typedef OFMapTable objc_hashtable;
static const OFMapTableFunctions defaultFunctions = { NULL };

static OF_INLINE objc_hashtable *
objc_hashtable_new(uint32_t (*hash)(const void *key),
    bool (*equal)(const void *key1, const void *key2), uint32_t size)
{
	return [[OFMapTable alloc] initWithKeyFunctions: defaultFunctions
					objectFunctions: defaultFunctions];
}

static OF_INLINE void
objc_hashtable_set(objc_hashtable *hashtable, const void *key,
    const void *object)
{
	return [hashtable setObject: (void *)object forKey: (void *)key];
}

static OF_INLINE void *
objc_hashtable_get(objc_hashtable *hashtable, const void *key)
{
	return [hashtable objectForKey: (void *)key];
}

static OF_INLINE void
objc_hashtable_delete(objc_hashtable *hashtable, const void *key)
{
	[hashtable removeObjectForKey: (void *)key];
}

# define OBJC_ERROR(...) abort()
# define object_isTaggedPointer(obj) 0
#endif

#ifdef OF_HAVE_THREADS
# import "OFPlainMutex.h"
static OFSpinlock spinlock;
#endif
static objc_hashtable *hashtable;

static uint32_t
hash(const void *object)
{
	return (uint32_t)(uintptr_t)object;
}

static bool
equal(const void *object1, const void *object2)
{
	return (object1 == object2);
}

OF_CONSTRUCTOR()
{
	hashtable = objc_hashtable_new(hash, equal, 2);

#ifdef OF_HAVE_THREADS
	if (OFSpinlockNew(&spinlock) != 0)
		OBJC_ERROR("Failed to create spinlock!");
#endif
}

id
objc_retain(id object)
{
#ifdef OF_OBJFW_RUNTIME
	if (object_isTaggedPointer_fast(object) || object == nil)
		return object;

	if (object_getClass_fast(object)->info & OBJC_CLASS_INFO_RUNTIME_RR)
		return _objc_rootRetain(object);
#endif

	return [object retain];
}

id
objc_retainBlock(id block)
{
	return [block copy];
}

id
objc_retainAutorelease(id object)
{
#ifdef OF_OBJFW_RUNTIME
	if (object_isTaggedPointer_fast(object) || object == nil)
		return object;

	if (object_getClass_fast(object)->info & OBJC_CLASS_INFO_RUNTIME_RR)
		return _objc_rootAutorelease(_objc_rootRetain(object));
#endif

	return [[object retain] autorelease];
}

void
objc_release(id object)
{
#ifdef OF_OBJFW_RUNTIME
	if (object_isTaggedPointer_fast(object) || object == nil)
		return;

	if (object_getClass_fast(object)->info & OBJC_CLASS_INFO_RUNTIME_RR) {
		_objc_rootRelease(object);
		return;
	}
#endif

	[object release];
}

id
objc_autorelease(id object)
{
#ifdef OF_OBJFW_RUNTIME
	if (object_isTaggedPointer_fast(object) || object == nil)
		return object;

	if (object_getClass_fast(object)->info & OBJC_CLASS_INFO_RUNTIME_RR)
		return _objc_rootAutorelease(object);
#endif

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
	struct WeakRef *old;

#ifdef OF_HAVE_THREADS
	if (OFSpinlockLock(&spinlock) != 0)
		OBJC_ERROR("Failed to lock spinlock!");
#endif

	if (*object != nil &&
	    (old = objc_hashtable_get(hashtable, *object)) != NULL) {
		for (size_t i = 0; i < old->count; i++) {
			if (old->locations[i] == object) {
				if (--old->count == 0) {
					objc_hashtable_delete(hashtable,
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
		struct WeakRef *ref;

#if defined(OF_HAVE_ATOMIC_OPS) && \
    (defined(OF_OBJFW_RUNTIME) || defined(OF_DECLARE_CONSTRUCT_INSTANCE))
		OFAtomicIntOr(&OBJC_PRE_IVARS(value)->info,
		    OBJC_OBJECT_INFO_WEAK_REFERENCES);
#endif

		ref = objc_hashtable_get(hashtable, value);

		if (ref == NULL) {
			if ((ref = calloc(1, sizeof(*ref))) == NULL)
				OBJC_ERROR("Not enough memory to allocate weak "
				    "reference!");

			objc_hashtable_set(hashtable, value, ref);
		}

		if ((ref->locations = realloc(ref->locations,
		    (ref->count + 1) * sizeof(id *))) == NULL)
			OBJC_ERROR("Not enough memory to allocate weak "
			    "reference!");

		ref->locations[ref->count++] = object;
	} else
		value = nil;

	*object = value;

#ifdef OF_HAVE_THREADS
	if (OFSpinlockUnlock(&spinlock) != 0)
		OBJC_ERROR("Failed to unlock spinlock!");
#endif

	return value;
}

id
objc_loadWeakRetained(id *object)
{
	id value = nil;

#ifdef OF_HAVE_THREADS
	if (OFSpinlockLock(&spinlock) != 0)
		OBJC_ERROR("Failed to lock spinlock!");
#endif

	if (*object != nil && objc_hashtable_get(hashtable, *object) != NULL)
		value = *object;

#ifdef OF_HAVE_THREADS
	if (OFSpinlockUnlock(&spinlock) != 0)
		OBJC_ERROR("Failed to unlock spinlock!");
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
	struct WeakRef *ref;

#ifdef OF_HAVE_THREADS
	if (OFSpinlockLock(&spinlock) != 0)
		OBJC_ERROR("Failed to lock spinlock!");
#endif

	if (*src != nil &&
	    (ref = objc_hashtable_get(hashtable, *src)) != NULL) {
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
	if (OFSpinlockUnlock(&spinlock) != 0)
		OBJC_ERROR("Failed to unlock spinlock!");
#endif
}

void
objc_zeroWeakReferences(id value)
{
	struct WeakRef *ref;

#if defined(OF_HAVE_ATOMIC_OPS) && \
    (defined(OF_OBJFW_RUNTIME) || defined(OF_DECLARE_CONSTRUCT_INSTANCE))
	OFReleaseMemoryBarrier();

	if (value != nil && !object_isTaggedPointer(value) &&
	    !(OBJC_PRE_IVARS(value)->info & OBJC_OBJECT_INFO_WEAK_REFERENCES))
		return;
#endif

#ifdef OF_HAVE_THREADS
	if (OFSpinlockLock(&spinlock) != 0)
		OBJC_ERROR("Failed to lock spinlock!");
#endif

	if ((ref = objc_hashtable_get(hashtable, value)) != NULL) {
		for (size_t i = 0; i < ref->count; i++)
			*ref->locations[i] = nil;

		objc_hashtable_delete(hashtable, value);
		free(ref->locations);
		free(ref);
	}

#ifdef OF_HAVE_THREADS
	if (OFSpinlockUnlock(&spinlock) != 0)
		OBJC_ERROR("Failed to unlock spinlock!");
#endif
}
