/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <stdlib.h>
#include <string.h>

#include <assert.h>

#import "OFMapTable.h"
#import "OFEnumerator.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

#define MIN_CAPACITY 16

struct of_map_table_bucket {
	void *key, *value;
	uint32_t hash;
};
static struct of_map_table_bucket deleted = {};

static void*
default_retain(void *value)
{
	return value;
}

static void
default_release(void *value)
{
}

static uint32_t
default_hash(void *value)
{
	return (uint32_t)(uintptr_t)value;
}

static bool
default_equal(void *value1, void *value2)
{
	return (value1 == value2);
}

@interface OFMapTableKeyEnumerator: OFMapTableEnumerator
@end

@interface OFMapTableValueEnumerator: OFMapTableEnumerator
@end

@implementation OFMapTable
+ (instancetype)mapTableWithKeyFunctions: (of_map_table_functions_t)keyFunctions
			  valueFunctions: (of_map_table_functions_t)
					      valueFunctions
{
	return [[[self alloc]
	    initWithKeyFunctions: keyFunctions
		  valueFunctions: valueFunctions] autorelease];
}

+ (instancetype)mapTableWithKeyFunctions: (of_map_table_functions_t)keyFunctions
			  valueFunctions: (of_map_table_functions_t)
					      valueFunctions
				capacity: (size_t)capacity
{
	return [[[self alloc]
	    initWithKeyFunctions: keyFunctions
		  valueFunctions: valueFunctions
			capacity: capacity] autorelease];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithKeyFunctions: (of_map_table_functions_t)keyFunctions
	valueFunctions: (of_map_table_functions_t)valueFunctions
{
	return [self initWithKeyFunctions: keyFunctions
			   valueFunctions: valueFunctions
				 capacity: 0];
}

- initWithKeyFunctions: (of_map_table_functions_t)keyFunctions
	valueFunctions: (of_map_table_functions_t)valueFunctions
	      capacity: (size_t)capacity
{
	self = [super init];

	@try {
		_keyFunctions = keyFunctions;
		_valueFunctions = valueFunctions;

#define SET_DEFAULT(var, value) \
	if (var == NULL)	\
		var = value;

		SET_DEFAULT(_keyFunctions.retain, default_retain);
		SET_DEFAULT(_keyFunctions.release, default_release);
		SET_DEFAULT(_keyFunctions.hash, default_hash);
		SET_DEFAULT(_keyFunctions.equal, default_equal);

		SET_DEFAULT(_valueFunctions.retain, default_retain);
		SET_DEFAULT(_valueFunctions.release, default_release);
		SET_DEFAULT(_valueFunctions.hash, default_hash);
		SET_DEFAULT(_valueFunctions.equal, default_equal);

#undef SET_DEFAULT

		if (capacity > UINT32_MAX ||
		    capacity > UINT32_MAX / sizeof(*_buckets) ||
		    capacity > UINT32_MAX / 8)
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		for (_capacity = 1; _capacity < capacity; _capacity *= 2);
		if (capacity * 8 / _capacity >= 6)
			_capacity *= 2;

		if (_capacity < MIN_CAPACITY)
			_capacity = MIN_CAPACITY;

		_buckets = [self allocMemoryWithSize: sizeof(*_buckets)
					       count: _capacity];

		memset(_buckets, 0, _capacity * sizeof(*_buckets));

		if (of_hash_seed != 0)
#if defined(HAVE_ARC4RANDOM)
			_rotate = arc4random() & 31;
#elif defined(HAVE_RANDOM)
			_rotate = random() & 31;
#else
			_rotate = rand() & 31;
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	uint32_t i;

	for (i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			_keyFunctions.release(_buckets[i]->key);
			_valueFunctions.release(_buckets[i]->value);
		}
	}

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFMapTable *mapTable;
	uint32_t i;

	if (![object isKindOfClass: [OFMapTable class]])
		return false;

	mapTable = object;

	if (mapTable->_count != _count ||
	    mapTable->_keyFunctions.equal != _keyFunctions.equal ||
	    mapTable->_valueFunctions.equal != _valueFunctions.equal)
		return false;

	for (i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			void *value = [mapTable valueForKey: _buckets[i]->key];

			if (!_valueFunctions.equal(value, _buckets[i]->value))
				return false;
		}
	}

	return true;
}

- (uint32_t)hash
{
	uint32_t i, hash = 0;

	for (i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			hash += OF_ROR(_buckets[i]->hash, _rotate);
			hash += _valueFunctions.hash(_buckets[i]->value);
		}
	}

	return hash;
}

- (id)copy
{
	OFMapTable *copy = [[OFMapTable alloc]
	    initWithKeyFunctions: _keyFunctions
		  valueFunctions: _valueFunctions
			capacity: _capacity];

	@try {
		uint32_t i;

		for (i = 0; i < _capacity; i++)
			if (_buckets[i] != NULL && _buckets[i] != &deleted)
				[copy OF_setValue: _buckets[i]->value
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

- (void*)valueForKey: (void*)key
{
	uint32_t i, hash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	hash = OF_ROL(_keyFunctions.hash(key), _rotate);
	last = _capacity;

	for (i = hash & (_capacity - 1); i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key))
			return _buckets[i]->value;
	}

	if (i < last)
		return nil;

	/* In case the last bucket is already used */
	last = hash & (_capacity - 1);

	for (i = 0; i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key))
			return _buckets[i]->value;
	}

	return NULL;
}

- (void)OF_resizeForCount: (uint32_t)count
{
	uint32_t i, fullness, capacity;
	struct of_map_table_bucket **buckets;

	if (count > UINT32_MAX || count > UINT32_MAX / sizeof(*_buckets) ||
	    count > UINT32_MAX / 8)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	fullness = count * 8 / _capacity;

	if (fullness >= 6)
		capacity = _capacity * 2;
	else if (fullness <= 1)
		capacity = _capacity / 2;
	else
		return;

	/*
	 * Don't downsize if we have an initial capacity or if we would fall
	 * below the minimum capacity.
	 */
	if ((capacity < _capacity && count > _count) || capacity < MIN_CAPACITY)
		return;

	buckets = [self allocMemoryWithSize: sizeof(*buckets)
				      count: capacity];

	for (i = 0; i < capacity; i++)
		buckets[i] = NULL;

	for (i = 0; i < _capacity; i++) {
		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			uint32_t j, last;

			last = capacity;

			j = _buckets[i]->hash & (capacity - 1);
			for (; j < last && buckets[j] != NULL; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = _buckets[i]->hash & (capacity - 1);

				for (j = 0; j < last &&
				    buckets[j] != NULL; j++);
			}

			assert(j < last);

			buckets[j] = _buckets[i];
		}
	}

	[self freeMemory: _buckets];
	_buckets = buckets;
	_capacity = capacity;
}

- (void)OF_setValue: (void*)value
	     forKey: (void*)key
	       hash: (uint32_t)hash
{
	uint32_t i, last;
	void *old;

	if (key == NULL || value == NULL)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

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

	/* Key not in dictionary */
	if (i >= last || _buckets[i] == NULL || _buckets[i] == &deleted ||
	    !_keyFunctions.equal(_buckets[i]->key, key)) {
		struct of_map_table_bucket *bucket;

		[self OF_resizeForCount: _count + 1];

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
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		bucket = [self allocMemoryWithSize: sizeof(*bucket)];

		@try {
			bucket->key = _keyFunctions.retain(key);
		} @catch (id e) {
			[self freeMemory: bucket];
			@throw e;
		}

		@try {
			bucket->value = _valueFunctions.retain(value);
		} @catch (id e) {
			_keyFunctions.release(key);
			[self freeMemory: bucket];
			@throw e;
		}

		bucket->hash = hash;

		_buckets[i] = bucket;
		_count++;

		return;
	}

	old = _buckets[i]->value;
	_buckets[i]->value = _valueFunctions.retain(value);
	_valueFunctions.release(old);
}

- (void)setValue: (void*)value
	  forKey: (void*)key
{
	[self OF_setValue: value
		   forKey: key
		     hash: _keyFunctions.hash(key)];
}

- (void)removeValueForKey: (void*)key
{
	uint32_t i, hash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	hash = OF_ROL(_keyFunctions.hash(key), _rotate);
	last = _capacity;

	for (i = hash & (_capacity - 1); i < last && _buckets[i] != NULL; i++) {
		if (_buckets[i] == &deleted)
			continue;

		if (_keyFunctions.equal(_buckets[i]->key, key)) {
			_keyFunctions.release(_buckets[i]->key);
			_valueFunctions.release(_buckets[i]->value);

			[self freeMemory: _buckets[i]];
			_buckets[i] = &deleted;

			_count--;
			_mutations++;
			[self OF_resizeForCount: _count];

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
			_valueFunctions.release(_buckets[i]->value);

			[self freeMemory: _buckets[i]];
			_buckets[i] = &deleted;

			_count--;
			_mutations++;
			[self OF_resizeForCount: _count];

			return;
		}
	}
}

- (bool)containsValue: (void*)value
{
	uint32_t i;

	if (value == NULL || _count == 0)
		return false;

	for (i = 0; i < _capacity; i++)
		if (_buckets[i] != NULL && _buckets[i] != &deleted)
			if (_valueFunctions.equal(_buckets[i]->value, value))
				return true;

	return false;
}

- (bool)containsValueIdenticalTo: (void*)value
{
	uint32_t i;

	if (value == NULL || _count == 0)
		return false;

	for (i = 0; i < _capacity; i++)
		if (_buckets[i] != NULL && _buckets[i] != &deleted)
			if (_buckets[i]->value == value)
				return true;

	return false;
}

- (OFMapTableEnumerator*)keyEnumerator
{
	return [[[OFMapTableKeyEnumerator alloc]
	    OF_initWithMapTable: self
			buckets: _buckets
		       capacity: _capacity
	       mutationsPointer: &_mutations] autorelease];
}

- (OFMapTableEnumerator*)valueEnumerator
{
	return [[[OFMapTableValueEnumerator alloc]
	    OF_initWithMapTable: self
			buckets: _buckets
		       capacity: _capacity
	       mutationsPointer: &_mutations] autorelease];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
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
- (void)enumerateKeysAndValuesUsingBlock:
    (of_map_table_enumeration_block_t)block
{
	size_t i;
	bool stop = false;
	unsigned long mutations = _mutations;

	for (i = 0; i < _capacity && !stop; i++) {
		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithClass: [self class]
					object: self];

		if (_buckets[i] != NULL && _buckets[i] != &deleted)
			block(_buckets[i]->key, _buckets[i]->value, &stop);
	}
}

- (void)replaceValuesUsingBlock: (of_map_table_replace_block_t)block
{
	size_t i;
	unsigned long mutations = _mutations;

	for (i = 0; i < _capacity; i++) {
		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithClass: [self class]
					object: self];

		if (_buckets[i] != NULL && _buckets[i] != &deleted) {
			void *new;

			new = block(_buckets[i]->key, _buckets[i]->value);
			if (new == NULL)
				@throw [OFInvalidArgumentException
				    exceptionWithClass: [self class]
					      selector: _cmd];

			if (new != _buckets[i]->value) {
				_valueFunctions.release(_buckets[i]->value);
				_buckets[i]->value =
				    _valueFunctions.retain(new);
			}
		}
	}
}
#endif

- (of_map_table_functions_t)keyFunctions
{
	return _keyFunctions;
}

- (of_map_table_functions_t)valueFunctions
{
	return _valueFunctions;
}
@end

@implementation OFMapTableEnumerator
- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- OF_initWithMapTable: (OFMapTable*)mapTable
	      buckets: (struct of_map_table_bucket**)buckets
	     capacity: (uint32_t)capacity
     mutationsPointer: (unsigned long*)mutationsPtr
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

- (void*)nextValue
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (void)reset
{
	if (*_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [_mapTable class]
				object: _mapTable];

	_position = 0;
}
@end

@implementation OFMapTableKeyEnumerator
- (void*)nextValue
{
	if (*_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [_mapTable class]
				object: _mapTable];

	for (; _position < _capacity && (_buckets[_position] == NULL ||
	    _buckets[_position] == &deleted); _position++);

	if (_position < _capacity)
		return _buckets[_position++]->key;
	else
		return NULL;
}
@end

@implementation OFMapTableValueEnumerator
- (void*)nextValue
{
	if (*_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [_mapTable class]
				object: _mapTable];

	for (; _position < _capacity && (_buckets[_position] == NULL ||
	    _buckets[_position] == &deleted); _position++);

	if (_position < _capacity)
		return _buckets[_position++]->value;
	else
		return NULL;
}
@end

@implementation OFMapTableEnumeratorWrapper
- initWithEnumerator: (OFMapTableEnumerator*)enumerator
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
	id ret;

	@try {
		ret = [_enumerator nextValue];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [_object class]
				object: _object];
	}

	return ret;
}

- (void)reset
{
	@try {
		[_enumerator reset];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [_object class]
				object: _object];
	}
}
@end
