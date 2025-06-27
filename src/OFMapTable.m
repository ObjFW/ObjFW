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

#define OF_MAP_TABLE_M

#include "config.h"

#include <stdlib.h>
#include <string.h>

#import "OFMapTable.h"
#import "OFMapTable+Private.h"
#import "OFEnumerator.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

extern unsigned long OFHashSeed;

static const uint32_t minCapacity = 16;

struct OFMapTableBucket {
	void *key, *object;
	uint32_t hash;
};
static struct OFMapTableBucket deletedBucket = { 0 };

static void *
defaultRetain(void *object)
{
	return object;
}

static void
defaultRelease(void *object)
{
}

static unsigned long
defaultHash(void *object)
{
	return (unsigned long)(uintptr_t)object;
}

static bool
defaultEqual(void *object1, void *object2)
{
	return (object1 == object2);
}

OF_DIRECT_MEMBERS
@interface OFMapTableEnumerator ()
- (instancetype)of_initWithMapTable: (OFMapTable *)mapTable
			    buckets: (struct OFMapTableBucket **)buckets
			   capacity: (uint32_t)capacity
		   mutationsPointer: (unsigned long *)mutationsPtr
    OF_METHOD_FAMILY(init);
@end

@interface OFMapTableKeyEnumerator: OFMapTableEnumerator
@end

@interface OFMapTableObjectEnumerator: OFMapTableEnumerator
@end

@implementation OFMapTable
@synthesize keyFunctions = _keyFunctions, objectFunctions = _objectFunctions;

+ (instancetype)mapTableWithKeyFunctions: (OFMapTableFunctions)keyFunctions
			 objectFunctions: (OFMapTableFunctions)objectFunctions
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithKeyFunctions: keyFunctions
			       objectFunctions: objectFunctions]);
}

+ (instancetype)mapTableWithKeyFunctions: (OFMapTableFunctions)keyFunctions
			 objectFunctions: (OFMapTableFunctions)objectFunctions
				capacity: (size_t)capacity
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithKeyFunctions: keyFunctions
			       objectFunctions: objectFunctions
				      capacity: capacity]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithKeyFunctions: (OFMapTableFunctions)keyFunctions
		     objectFunctions: (OFMapTableFunctions)objectFunctions
{
	return [self initWithKeyFunctions: keyFunctions
			  objectFunctions: objectFunctions
				 capacity: 0];
}

- (instancetype)initWithKeyFunctions: (OFMapTableFunctions)keyFunctions
		     objectFunctions: (OFMapTableFunctions)objectFunctions
			    capacity: (size_t)capacity
{
	self = [super init];

	@try {
		_keyFunctions = keyFunctions;
		_objectFunctions = objectFunctions;

#define SET_DEFAULT(var, value) \
	if (var == NULL)	\
		var = value;

		SET_DEFAULT(_keyFunctions.retain, defaultRetain);
		SET_DEFAULT(_keyFunctions.release, defaultRelease);
		SET_DEFAULT(_keyFunctions.hash, defaultHash);
		SET_DEFAULT(_keyFunctions.equal, defaultEqual);

		SET_DEFAULT(_objectFunctions.retain, defaultRetain);
		SET_DEFAULT(_objectFunctions.release, defaultRelease);
		SET_DEFAULT(_objectFunctions.hash, defaultHash);
		SET_DEFAULT(_objectFunctions.equal, defaultEqual);

#undef SET_DEFAULT

		if (capacity > UINT32_MAX / sizeof(*_buckets) ||
		    capacity > UINT32_MAX / 8)
			@throw [OFOutOfRangeException exception];

		for (_capacity = 1; _capacity < capacity;) {
			if (_capacity > UINT32_MAX / 2)
				@throw [OFOutOfRangeException exception];

			_capacity *= 2;
		}

		if (capacity * 8 / _capacity >= 6)
			if (_capacity <= UINT32_MAX / 2)
				_capacity *= 2;

		if (_capacity < minCapacity)
			_capacity = minCapacity;

		_buckets = OFAllocZeroedMemory(_capacity, sizeof(*_buckets));

		if (OFHashSeed != 0)
			_rotation = OFRandom16() & 31;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	for (uint32_t i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deletedBucket) {
			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);

			OFFreeMemory(_buckets[i]);
		}
	}

	OFFreeMemory(_buckets);

	[super dealloc];
}

static void
resizeForCount(OFMapTable *self, uint32_t count)
{
	uint32_t fullness, capacity;
	struct OFMapTableBucket **buckets;
	unsigned char newRotation;

	if (count > UINT32_MAX / sizeof(*self->_buckets) ||
	    count > UINT32_MAX / 8)
		@throw [OFOutOfRangeException exception];

	fullness = count * 8 / self->_capacity;

	if (fullness >= 6) {
		if (self->_capacity > UINT32_MAX / 2)
			return;

		capacity = self->_capacity * 2;
	} else if (fullness <= 1)
		capacity = self->_capacity / 2;
	else
		return;

	/*
	 * Don't downsize if we have an initial capacity or if we would fall
	 * below the minimum capacity.
	 */
	if ((capacity < self->_capacity && count > self->_count) ||
	    capacity < minCapacity)
		return;

	buckets = OFAllocZeroedMemory(capacity, sizeof(*buckets));
	newRotation = (OFHashSeed != 0 ? OFRandom16() & 31 : 0);

	for (uint32_t i = 0; i < self->_capacity; i++) {
		if (self->_buckets[i] != NULL &&
		    self->_buckets[i] != &deletedBucket) {
			uint32_t rotatedHash, j, last;

			rotatedHash = OFRotateLeft(self->_buckets[i]->hash,
			    newRotation);
			last = capacity;

			for (j = rotatedHash & (capacity - 1);
			    j < last && buckets[j] != NULL; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = rotatedHash & (capacity - 1);

				for (j = 0; j < last &&
				    buckets[j] != NULL; j++);
			}

			if (j >= last)
				@throw [OFOutOfRangeException exception];

			buckets[j] = self->_buckets[i];
		}
	}

	OFFreeMemory(self->_buckets);
	self->_buckets = buckets;
	self->_capacity = capacity;
	self->_rotation = newRotation;
}

static void
setObject(OFMapTable *restrict self, void *key, void *object, uint32_t hash)
{
	uint32_t rotatedHash, i, last;
	void *old;

	if (key == NULL || object == NULL)
		@throw [OFInvalidArgumentException exception];

	rotatedHash = OFRotateLeft(hash, self->_rotation);
	last = self->_capacity;

	for (i = rotatedHash & (self->_capacity - 1);
	    i < last && self->_buckets[i] != NULL; i++) {
		if (self->_buckets[i] == &deletedBucket)
			continue;

		if (self->_keyFunctions.equal(self->_buckets[i]->key, key))
			break;
	}

	/* In case the last bucket is already used */
	if (i >= last) {
		last = rotatedHash & (self->_capacity - 1);

		for (i = 0; i < last && self->_buckets[i] != NULL; i++) {
			if (self->_buckets[i] == &deletedBucket)
				continue;

			if (self->_keyFunctions.equal(
			    self->_buckets[i]->key, key))
				break;
		}
	}

	/* Key not in map table */
	if (i >= last || self->_buckets[i] == NULL ||
	    self->_buckets[i] == &deletedBucket ||
	    !self->_keyFunctions.equal(self->_buckets[i]->key, key)) {
		struct OFMapTableBucket *bucket;

		resizeForCount(self, self->_count + 1);
		/* Resizing can change the rotation */
		rotatedHash = OFRotateLeft(hash, self->_rotation);

		self->_mutations++;
		last = self->_capacity;

		for (i = rotatedHash & (self->_capacity - 1); i < last &&
		    self->_buckets[i] != NULL &&
		    self->_buckets[i] != &deletedBucket; i++);

		/* In case the last bucket is already used */
		if (i >= last) {
			last = rotatedHash & (self->_capacity - 1);

			for (i = 0; i < last && self->_buckets[i] != NULL &&
			    self->_buckets[i] != &deletedBucket; i++);
		}

		if (i >= last)
			@throw [OFOutOfRangeException exception];

		bucket = OFAllocMemory(1, sizeof(*bucket));

		@try {
			bucket->key = self->_keyFunctions.retain(key);
		} @catch (id e) {
			OFFreeMemory(bucket);
			@throw e;
		}

		@try {
			bucket->object = self->_objectFunctions.retain(object);
		} @catch (id e) {
			self->_keyFunctions.release(bucket->key);
			OFFreeMemory(bucket);
			@throw e;
		}

		bucket->hash = hash;

		self->_buckets[i] = bucket;
		self->_count++;

		return;
	}

	old = self->_buckets[i]->object;
	self->_buckets[i]->object = self->_objectFunctions.retain(object);
	self->_objectFunctions.release(old);
}

- (bool)isEqual: (id)object
{
	OFMapTable *mapTable;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFMapTable class]])
		return false;

	mapTable = object;

	if (mapTable->_count != _count ||
	    mapTable->_keyFunctions.equal != _keyFunctions.equal ||
	    mapTable->_objectFunctions.equal != _objectFunctions.equal)
		return false;

	for (uint32_t i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deletedBucket) {
			void *objectIter =
			    [mapTable objectForKey: _buckets[i]->key];

			if (!_objectFunctions.equal(objectIter,
			    _buckets[i]->object))
				return false;
		}
	}

	return true;
}

- (unsigned long)hash
{
	unsigned long hash = 0;

	for (unsigned long i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deletedBucket) {
			hash ^= _buckets[i]->hash;
			hash ^= _objectFunctions.hash(_buckets[i]->object);
		}
	}

	return hash;
}

- (id)copy
{
	OFMapTable *copy = [[OFMapTable alloc]
	    initWithKeyFunctions: _keyFunctions
		 objectFunctions: _objectFunctions
			capacity: _capacity];

	@try {
		for (uint32_t i = 0; i < _capacity; i++)
			if (_buckets[i] != NULL &&
			    _buckets[i] != &deletedBucket)
				setObject(copy, _buckets[i]->key,
				    _buckets[i]->object, _buckets[i]->hash);
	} @catch (id e) {
		objc_release(copy);
		@throw e;
	}

	return copy;
}

- (size_t)count
{
	return _count;
}

- (void *)objectForKey: (void *)key
{
	uint32_t i, rotatedHash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException exception];

	rotatedHash = OFRotateLeft((uint32_t)_keyFunctions.hash(key),
	    _rotation);
	last = _capacity;

	for (i = rotatedHash & (_capacity - 1);
	    i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deletedBucket)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key))
			return _buckets[i]->object;
	}

	if (i < last)
		return nil;

	/* In case the last bucket is already used */
	last = rotatedHash & (_capacity - 1);

	for (i = 0; i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deletedBucket)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key))
			return _buckets[i]->object;
	}

	return NULL;
}

- (void)setObject: (void *)object forKey: (void *)key
{
	setObject(self, key, object, (uint32_t)_keyFunctions.hash(key));
}

- (void)removeObjectForKey: (void *)key
{
	uint32_t i, rotatedHash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException exception];

	rotatedHash = OFRotateLeft((uint32_t)_keyFunctions.hash(key),
	    _rotation);
	last = _capacity;

	for (i = rotatedHash & (_capacity - 1);
	    i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deletedBucket)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key)) {
			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);

			OFFreeMemory(_buckets[i]);
			_buckets[i] = &deletedBucket;

			_count--;
			_mutations++;
			resizeForCount(self, _count);

			return;
		}
	}

	if (i < last)
		return;

	/* In case the last bucket is already used */
	last = rotatedHash & (_capacity - 1);

	for (i = 0; i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deletedBucket)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key)) {
			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);

			OFFreeMemory(_buckets[i]);
			_buckets[i] = &deletedBucket;

			_count--;
			_mutations++;
			resizeForCount(self, _count);

			return;
		}
	}
}

- (void)removeAllObjects
{
	for (uint32_t i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL) {
			if (_buckets[i] == &deletedBucket) {
				_buckets[i] = NULL;
				continue;
			}

			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);

			OFFreeMemory(_buckets[i]);
			_buckets[i] = NULL;
		}
	}

	_count = 0;
	_capacity = minCapacity;
	_buckets = OFResizeMemory(_buckets, _capacity, sizeof(*_buckets));

	/*
	 * Get a new random value for _rotation, so that it is not less secure
	 * than creating a new hash map.
	 */
	if (OFHashSeed != 0)
		_rotation = OFRandom16() & 31;
}

- (bool)containsObject: (void *)object
{
	if (object == NULL || _count == 0)
		return false;

	for (uint32_t i = 0; i < _capacity; i++)
		if (_buckets[i] != NULL && _buckets[i] != &deletedBucket)
			if (_objectFunctions.equal(_buckets[i]->object, object))
				return true;

	return false;
}

- (bool)containsObjectIdenticalTo: (void *)object
{
	if (object == NULL || _count == 0)
		return false;

	for (uint32_t i = 0; i < _capacity; i++)
		if (_buckets[i] != NULL && _buckets[i] != &deletedBucket)
			if (_buckets[i]->object == object)
				return true;

	return false;
}

- (OFMapTableEnumerator *)keyEnumerator
{
	return objc_autoreleaseReturnValue([[OFMapTableKeyEnumerator alloc]
	    of_initWithMapTable: self
			buckets: _buckets
		       capacity: _capacity
	       mutationsPointer: &_mutations]);
}

- (OFMapTableEnumerator *)objectEnumerator
{
	return objc_autoreleaseReturnValue([[OFMapTableObjectEnumerator alloc]
	    of_initWithMapTable: self
			buckets: _buckets
		       capacity: _capacity
	       mutationsPointer: &_mutations]);
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	unsigned long j = state->state;
	int i;

	for (i = 0; i < count; i++) {
		for (; j < _capacity && (_buckets[j] == NULL ||
		    _buckets[j] == &deletedBucket); j++);

		if (j < _capacity) {
			objects[i] = _buckets[j]->key;
			j++;
		} else
			break;
	}

	state->state = j;
	state->itemsPtr = objects;
	state->mutationsPtr = &_mutations;

	return i;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateKeysAndObjectsUsingBlock: (OFMapTableEnumerationBlock)block
{
	bool stop = false;
	unsigned long mutations = _mutations;

	for (size_t i = 0; i < _capacity && !stop; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deletedBucket)
			block(_buckets[i]->key, _buckets[i]->object, &stop);

		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithObject: self];
	}
}

- (void)replaceObjectsUsingBlock: (OFMapTableReplaceBlock)block
{
	unsigned long mutations = _mutations;

	for (size_t i = 0; i < _capacity; i++) {
		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithObject: self];

		if (_buckets[i] != NULL && _buckets[i] != &deletedBucket) {
			void *new;

			new = block(_buckets[i]->key, _buckets[i]->object);
			if (new == NULL)
				@throw [OFInvalidArgumentException exception];

			if (new != _buckets[i]->object) {
				_objectFunctions.release(_buckets[i]->object);
				_buckets[i]->object =
				    _objectFunctions.retain(new);
			}
		}
	}
}
#endif
@end

@implementation OFMapTableEnumerator
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithMapTable: (OFMapTable *)mapTable
			    buckets: (struct OFMapTableBucket **)buckets
			   capacity: (uint32_t)capacity
		   mutationsPointer: (unsigned long *)mutationsPtr
{
	self = [super init];

	_mapTable = objc_retain(mapTable);
	_buckets = buckets;
	_capacity = capacity;
	_mutations = *mutationsPtr;
	_mutationsPtr = mutationsPtr;

	return self;
}

- (void)dealloc
{
	objc_release(_mapTable);

	[super dealloc];
}

- (void **)nextObject
{
	OF_UNRECOGNIZED_SELECTOR
}
@end

@implementation OFMapTableKeyEnumerator
- (void **)nextObject
{
	if (*_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithObject: _mapTable];

	for (; _position < _capacity && (_buckets[_position] == NULL ||
	    _buckets[_position] == &deletedBucket); _position++);

	if (_position < _capacity)
		return &_buckets[_position++]->key;
	else
		return NULL;
}
@end

@implementation OFMapTableObjectEnumerator
- (void **)nextObject
{
	if (*_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithObject: _mapTable];

	for (; _position < _capacity && (_buckets[_position] == NULL ||
	    _buckets[_position] == &deletedBucket); _position++);

	if (_position < _capacity)
		return &_buckets[_position++]->object;
	else
		return NULL;
}
@end

@implementation OFMapTableEnumeratorWrapper
- (instancetype)initWithEnumerator: (OFMapTableEnumerator *)enumerator
			    object: (id)object
{
	self = [super init];

	_enumerator = objc_retain(enumerator);
	_object = objc_retain(object);

	return self;
}

- (void)dealloc
{
	objc_release(_enumerator);
	objc_release(_object);

	[super dealloc];
}

- (id)nextObject
{
	void **objectPtr;

	@try {
		objectPtr = [_enumerator nextObject];

		if (objectPtr == NULL)
			return nil;
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithObject: _object];
	}

	return (id)*objectPtr;
}
@end
