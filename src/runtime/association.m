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

struct Association {
	id object;
	objc_associationPolicy policy;
};

#ifdef OF_OBJFW_RUNTIME
typedef struct objc_hashtable _objc_hashtable;
#else
typedef OFMapTable _objc_hashtable;
static const OFMapTableFunctions defaultFunctions = { NULL };

static OF_INLINE _objc_hashtable *
_objc_hashtable_new(uint32_t (*hash)(const void *key),
    bool (*equal)(const void *key1, const void *key2), uint32_t size)
{
	return [[OFMapTable alloc] initWithKeyFunctions: defaultFunctions
					objectFunctions: defaultFunctions];
}

static OF_INLINE void
_objc_hashtable_set(_objc_hashtable *hashtable, const void *key,
    const void *object)
{
	return [hashtable setObject: (void *)object forKey: (void *)key];
}

static OF_INLINE void *
_objc_hashtable_get(_objc_hashtable *hashtable, const void *key)
{
	return [hashtable objectForKey: (void *)key];
}

static OF_INLINE void
_objc_hashtable_delete(_objc_hashtable *hashtable, const void *key)
{
	[hashtable removeObjectForKey: (void *)key];
}

static OF_INLINE void
_objc_hashtable_free(_objc_hashtable *hashtable)
{
	objc_release(hashtable);
}

# define _OBJC_ERROR(...) abort()
#endif

#ifdef OF_HAVE_THREADS
# define numSlots 16	/* needs to be a power of 2 */
# import "OFPlainMutex.h"
static OFSpinlock spinlocks[numSlots];
#else
# define numSlots 1
#endif
static _objc_hashtable *hashtables[numSlots];

static OF_INLINE size_t
slotForObject(id object)
{
	return ((size_t)((uintptr_t)object >> 4) & (numSlots - 1));
}

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
	for (size_t i = 0; i < numSlots; i++) {
		hashtables[i] = _objc_hashtable_new(hash, equal, 2);
#ifdef OF_HAVE_THREADS
		if (OFSpinlockNew(&spinlocks[i]) != 0)
			_OBJC_ERROR("Failed to create spinlocks!");
#endif
	}
}

void
objc_setAssociatedObject(id object, const void *key, id value,
    objc_associationPolicy policy)
{
	size_t slot;

	switch (policy) {
	case OBJC_ASSOCIATION_ASSIGN:
		break;
	case OBJC_ASSOCIATION_RETAIN:
	case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
		value = objc_retain(value);
		break;
	case OBJC_ASSOCIATION_COPY:
	case OBJC_ASSOCIATION_COPY_NONATOMIC:
		value = [value copy];
		break;
	default:
		/* Don't know what to do, so do nothing. */
		return;
	}

#if defined(OF_HAVE_ATOMIC_OPS) && \
    (defined(OF_OBJFW_RUNTIME) || defined(OF_DECLARE_CONSTRUCT_INSTANCE))
	OFAtomicIntOr(&_OBJC_PRE_IVARS(object)->info,
	    _OBJC_OBJECT_INFO_ASSOCIATIONS);
#endif

	slot = slotForObject(object);

#ifdef OF_HAVE_THREADS
	if (OFSpinlockLock(&spinlocks[slot]) != 0)
		_OBJC_ERROR("Failed to lock spinlock!");

	@try {
#endif
		_objc_hashtable *objectHashtable;
		struct Association *association;

		objectHashtable = _objc_hashtable_get(hashtables[slot], object);
		if (objectHashtable == NULL) {
			objectHashtable = _objc_hashtable_new(hash, equal, 2);
			_objc_hashtable_set(hashtables[slot], object,
			    objectHashtable);
		}

		association = _objc_hashtable_get(objectHashtable, key);
		if (association != NULL) {
			switch (association->policy) {
			case OBJC_ASSOCIATION_RETAIN:
			case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
			case OBJC_ASSOCIATION_COPY:
			case OBJC_ASSOCIATION_COPY_NONATOMIC:
				objc_release(association->object);
				break;
			default:
				break;
			}
		} else {
			association = malloc(sizeof(*association));
			if (association == NULL)
				_OBJC_ERROR("Failed to allocate association!");

			_objc_hashtable_set(objectHashtable, key, association);
		}

		association->policy = policy;
		association->object = value;
#ifdef OF_HAVE_THREADS
	} @finally {
		if (OFSpinlockUnlock(&spinlocks[slot]) != 0)
			_OBJC_ERROR("Failed to unlock spinlock!");
	}
#endif
}

id
objc_getAssociatedObject(id object, const void *key)
{
	size_t slot = slotForObject(object);
	id ret = nil;

#ifdef OF_HAVE_THREADS
	if (OFSpinlockLock(&spinlocks[slot]) != 0)
		_OBJC_ERROR("Failed to lock spinlock!");

	@try {
#endif
		_objc_hashtable *objectHashtable;
		struct Association *association;

		objectHashtable = _objc_hashtable_get(hashtables[slot], object);
		if (objectHashtable == NULL)
			return nil;

		association = _objc_hashtable_get(objectHashtable, key);
		if (association == NULL)
			return nil;

		switch (association->policy) {
		case OBJC_ASSOCIATION_RETAIN:
		case OBJC_ASSOCIATION_COPY:
			ret = objc_autoreleaseReturnValue(
			    objc_retain(association->object));
			break;
		default:
			ret = association->object;
			break;
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		if (OFSpinlockUnlock(&spinlocks[slot]) != 0)
			_OBJC_ERROR("Failed to unlock spinlock!");
	}
#endif

	return ret;
}

void
objc_removeAssociatedObjects(id object)
{
	size_t slot;

#if defined(OF_HAVE_ATOMIC_OPS) && \
    (defined(OF_OBJFW_RUNTIME) || defined(OF_DECLARE_CONSTRUCT_INSTANCE))
	OFReleaseMemoryBarrier();

	if (!(_OBJC_PRE_IVARS(object)->info & _OBJC_OBJECT_INFO_ASSOCIATIONS))
		return;
#endif

	slot = slotForObject(object);

#ifdef OF_HAVE_THREADS
	if (OFSpinlockLock(&spinlocks[slot]) != 0)
		_OBJC_ERROR("Failed to lock spinlock!");

	@try {
#endif
		_objc_hashtable *objectHashtable;

		objectHashtable = _objc_hashtable_get(hashtables[slot], object);
		if (objectHashtable == NULL)
			return;

#ifdef OF_OBJFW_RUNTIME
		for (uint32_t i = 0; i < objectHashtable->size; i++) {
			struct Association *association;

			if (objectHashtable->data[i] == NULL ||
			    objectHashtable->data[i] == &_objc_deletedBucket)
				continue;

			association = (struct Association *)
			    objectHashtable->data[i]->object;
#else
		OFMapTableEnumerator *enumerator =
		    [objectHashtable objectEnumerator];
		void **iter;
		while ((iter = [enumerator nextObject]) != NULL) {
			struct Association *association = *iter;
#endif

			switch (association->policy) {
			case OBJC_ASSOCIATION_RETAIN:
			case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
			case OBJC_ASSOCIATION_COPY:
			case OBJC_ASSOCIATION_COPY_NONATOMIC:
				objc_release(association->object);
				break;
			default:
				break;
			}

			free(association);
		}

		_objc_hashtable_delete(hashtables[slot], object);
		_objc_hashtable_free(objectHashtable);
#ifdef OF_HAVE_THREADS
	} @finally {
		if (OFSpinlockUnlock(&spinlocks[slot]) != 0)
			_OBJC_ERROR("Failed to unlock spinlock!");
	}
#endif
}
