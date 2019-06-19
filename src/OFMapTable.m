/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include <stdlib.h>
#include <string.h>

#include <assert.h>

#import "OFMapTable.h"
#import "OFMapTable+Private.h"
#import "OFEnumerator.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

#define MIN_CAPACITY 16

struct of_map_table_bucket {
	void *key, *object;
	uint32_t hash;
};
static struct of_map_table_bucket deleted = { 0 };

static void *
defaultRetain(void *object)
{
	return object;
}

static void
defaultRelease(void *object)
{
}

static uint32_t
defaultHash(void *object)
{
	return (uint32_t)(uintptr_t)object;
}

static bool
defaultEqual(void *object1, void *object2)
{
	return (object1 == object2);
}

@interface OFMapTable ()
- (void)of_setObject: (void *)object
	      forKey: (void *)key
		hash: (uint32_t)hash;
@end

@interface OFMapTableEnumerator ()
- (instancetype)of_initWithMapTable: (OFMapTable *)mapTable
			    buckets: (struct of_map_table_bucket **)buckets
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

+ (instancetype)mapTableWithKeyFunctions: (of_map_table_functions_t)keyFunctions
			 objectFunctions: (of_map_table_functions_t)
					      objectFunctions
{
	return [[[self alloc]
	    initWithKeyFunctions: keyFunctions
		  objectFunctions: objectFunctions] autorelease];
}

+ (instancetype)mapTableWithKeyFunctions: (of_map_table_functions_t)keyFunctions
			 objectFunctions: (of_map_table_functions_t)
					      objectFunctions
				capacity: (size_t)capacity
{
	return [[[self alloc]
	    initWithKeyFunctions: keyFunctions
		 objectFunctions: objectFunctions
			capacity: capacity] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithKeyFunctions: (of_map_table_functions_t)keyFunctions
		     objectFunctions: (of_map_table_functions_t)objectFunctions
{
	return [self initWithKeyFunctions: keyFunctions
			  objectFunctions: objectFunctions
				 capacity: 0];
}

- (instancetype)initWithKeyFunctions: (of_map_table_functions_t)keyFunctions
		     objectFunctions: (of_map_table_functions_t)objectFunctions
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

		if (_capacity < MIN_CAPACITY)
			_capacity = MIN_CAPACITY;

		_buckets = [self allocZeroedMemoryWithSize: sizeof(*_buckets)
						     count: _capacity];

		if (of_hash_seed != 0)
			_rotate = of_random() & 31;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	for (uint32_t i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);
		}
	}

	[super dealloc];
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
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			void *objectIter =
			    [mapTable objectForKey: _buckets[i]->key];

			if (!_objectFunctions.equal(objectIter,
			    _buckets[i]->object))
				return false;
		}
	}

	return true;
}

- (uint32_t)hash
{
	uint32_t hash = 0;

	for (uint32_t i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			hash += OF_ROR(_buckets[i]->hash, _rotate);
			hash += _objectFunctions.hash(_buckets[i]->object);
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
			if (_buckets[i] != NULL && _buckets[i] != &deleted)
				[copy of_setObject: _buckets[i]->object
					    forKey: _buckets[i]->key
					      hash: OF_ROR(_buckets[i]->hash,
							_rotate)];
	} @catch (id e) {
		[copy release];
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
	uint32_t i, hash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException exception];

	hash = OF_ROL(_keyFunctions.hash(key), _rotate);
	last = _capacity;

	for (i = hash & (_capacity - 1); i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key))
			return _buckets[i]->object;
	}

	if (i < last)
		return nil;

	/* In case the last bucket is already used */
	last = hash & (_capacity - 1);

	for (i = 0; i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key))
			return _buckets[i]->object;
	}

	return NULL;
}

- (void)of_resizeForCount: (uint32_t)count
{
	uint32_t fullness, capacity;
	struct of_map_table_bucket **buckets;

	if (count > UINT32_MAX / sizeof(*_buckets) || count > UINT32_MAX / 8)
		@throw [OFOutOfRangeException exception];

	fullness = count * 8 / _capacity;

	if (fullness >= 6) {
		if (_capacity > UINT32_MAX / 2)
			return;

		capacity = _capacity * 2;
	} else if (fullness <= 1)
		capacity = _capacity / 2;
	else
		return;

	/*
	 * Don't downsize if we have an initial capacity or if we would fall
	 * below the minimum capacity.
	 */
	if ((capacity < _capacity && count > _count) || capacity < MIN_CAPACITY)
		return;

	buckets = [self allocZeroedMemoryWithSize: sizeof(*buckets)
					    count: capacity];

	for (uint32_t i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			uint32_t j, last;

			last = capacity;

			for (j = _buckets[i]->hash & (capacity - 1);
			    j < last && buckets[j] != NULL; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = _buckets[i]->hash & (capacity - 1);

				for (j = 0; j < last &&
				    buckets[j] != NULL; j++);
			}

			if (j >= last)
				@throw [OFOutOfRangeException exception];

			buckets[j] = _buckets[i];
		}
	}

	[self freeMemory: _buckets];
	_buckets = buckets;
	_capacity = capacity;
}

- (void)of_setObject: (void *)object
	      forKey: (void *)key
		hash: (uint32_t)hash
{
	uint32_t i, last;
	void *old;

	if (key == NULL || object == NULL)
		@throw [OFInvalidArgumentException exception];

	hash = OF_ROL(hash, _rotate);
	last = _capacity;

	for (i = hash & (_capacity - 1); i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key))
			break;
	}

	/* In case the last bucket is already used */
	if (i >= last) {
		last = hash & (_capacity - 1);

		for (i = 0; i < last && _buckets[i] != NULL; i++) {
			if (_buckets[i] == &deleted)
				continue;

			if (_keyFunctions.equal(_buckets[i]->key, key))
				break;
		}
	}

	/* Key not in map table */
	if (i >= last || _buckets[i] == NULL || _buckets[i] == &deleted ||
	    !_keyFunctions.equal(_buckets[i]->key, key)) {
		struct of_map_table_bucket *bucket;

		[self of_resizeForCount: _count + 1];

		_mutations++;
		last = _capacity;

		for (i = hash & (_capacity - 1); i < last &&
		    _buckets[i] != NULL && _buckets[i] != &deleted; i++);

		/* In case the last bucket is already used */
		if (i >= last) {
			last = hash & (_capacity - 1);

			for (i = 0; i < last && _buckets[i] != NULL &&
			    _buckets[i] != &deleted; i++);
		}

		if (i >= last)
			@throw [OFOutOfRangeException exception];

		bucket = [self allocMemoryWithSize: sizeof(*bucket)];

		@try {
			bucket->key = _keyFunctions.retain(key);
		} @catch (id e) {
			[self freeMemory: bucket];
			@throw e;
		}

		@try {
			bucket->object = _objectFunctions.retain(object);
		} @catch (id e) {
			_keyFunctions.release(bucket->key);
			[self freeMemory: bucket];
			@throw e;
		}

		bucket->hash = hash;

		_buckets[i] = bucket;
		_count++;

		return;
	}

	old = _buckets[i]->object;
	_buckets[i]->object = _objectFunctions.retain(object);
	_objectFunctions.release(old);
}

- (void)setObject: (void *)object
	   forKey: (void *)key
{
	[self of_setObject: object
		    forKey: key
		      hash: _keyFunctions.hash(key)];
}

- (void)removeObjectForKey: (void *)key
{
	uint32_t i, hash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException exception];

	hash = OF_ROL(_keyFunctions.hash(key), _rotate);
	last = _capacity;

	for (i = hash & (_capacity - 1); i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key)) {
			_mutations++;

			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);

			[self freeMemory: _buckets[i]];
			_buckets[i] = &deleted;

			_count--;
			[self of_resizeForCount: _count];

			return;
		}
	}

	if (i < last)
		return;

	/* In case the last bucket is already used */
	last = hash & (_capacity - 1);

	for (i = 0; i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key)) {
			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);

			[self freeMemory: _buckets[i]];
			_buckets[i] = &deleted;

			_count--;
			_mutations++;
			[self of_resizeForCount: _count];

			return;
		}
	}
}

- (void)removeAllObjects
{
	for (uint32_t i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL) {
			if (_buckets[i] == &deleted) {
				_buckets[i] = NULL;
				continue;
			}

			_keyFunctions.release(_buckets[i]->key);
			_objectFunctions.release(_buckets[i]->object);

			[self freeMemory: _buckets[i]];
			_buckets[i] = NULL;
		}
	}

	_count = 0;
	_capacity = MIN_CAPACITY;
	_buckets = [self resizeMemory: _buckets
				 size: sizeof(*_buckets)
				count: _capacity];

	/*
	 * Get a new random value for _rotate, so that it is not less secure
	 * than creating a new hash map.
	 */
	if (of_hash_seed != 0)
		_rotate = of_random() & 31;
}

- (bool)containsObject: (void *)object
{
	if (object == NULL || _count == 0)
		return false;

	for (uint32_t i = 0; i < _capacity; i++)
		if (_buckets[i] != NULL && _buckets[i] != &deleted)
			if (_objectFunctions.equal(_buckets[i]->object, object))
				return true;

	return false;
}

- (bool)containsObjectIdenticalTo: (void *)object
{
	if (object == NULL || _count == 0)
		return false;

	for (uint32_t i = 0; i < _capacity; i++)
		if (_buckets[i] != NULL && _buckets[i] != &deleted)
			if (_buckets[i]->object == object)
				return true;

	return false;
}

- (OFMapTableEnumerator *)keyEnumerator
{
	return [[[OFMapTableKeyEnumerator alloc]
	    of_initWithMapTable: self
			buckets: _buckets
		       capacity: _capacity
	       mutationsPointer: &_mutations] autorelease];
}

- (OFMapTableEnumerator *)objectEnumerator
{
	return [[[OFMapTableObjectEnumerator alloc]
	    of_initWithMapTable: self
			buckets: _buckets
		       capacity: _capacity
	       mutationsPointer: &_mutations] autorelease];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	uint32_t j = (uint32_t)state->state;
	int i;

	for (i = 0; i < count; i++) {
		for (; j < _capacity && (_buckets[j] == NULL ||
		    _buckets[j] == &deleted); j++);

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
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_map_table_enumeration_block_t)block
{
	bool stop = false;
	unsigned long mutations = _mutations;

	for (size_t i = 0; i < _capacity && !stop; i++) {
		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithObject: self];

		if (_buckets[i] != NULL && _buckets[i] != &deleted)
			block(_buckets[i]->key, _buckets[i]->object, &stop);
	}
}

- (void)replaceObjectsUsingBlock: (of_map_table_replace_block_t)block
{
	unsigned long mutations = _mutations;

	for (size_t i = 0; i < _capacity; i++) {
		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithObject: self];

		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
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
			    buckets: (struct of_map_table_bucket **)buckets
			   capacity: (uint32_t)capacity
		   mutationsPointer: (unsigned long *)mutationsPtr
{
	self = [super init];

	_mapTable = [mapTable retain];
	_buckets = buckets;
	_capacity = capacity;
	_mutations = *mutationsPtr;
	_mutationsPtr = mutationsPtr;

	return self;
}

- (void)dealloc
{
	[_mapTable release];

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
	    _buckets[_position] == &deleted); _position++);

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
	    _buckets[_position] == &deleted); _position++);

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

	_enumerator = [enumerator retain];
	_object = [object retain];

	return self;
}

- (void)dealloc
{
	[_enumerator release];
	[_object release];

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
