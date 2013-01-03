/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

static BOOL
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
		abort();
	} @catch (id e) {
		[self release];
		@throw e;
	}
}

- initWithKeyFunctions: (of_map_table_functions_t)keyFunctions_
	valueFunctions: (of_map_table_functions_t)valueFunctions_
{
	return [self initWithKeyFunctions: keyFunctions_
			   valueFunctions: valueFunctions_
				 capacity: 0];
}

- initWithKeyFunctions: (of_map_table_functions_t)keyFunctions_
	valueFunctions: (of_map_table_functions_t)valueFunctions_
	      capacity: (size_t)capacity_
{
	self = [super init];

	@try {
		keyFunctions = keyFunctions_;
		valueFunctions = valueFunctions_;

#define SET_DEFAULT(var, value) \
	if (var == NULL)	\
		var = value;

		SET_DEFAULT(keyFunctions.retain, default_retain);
		SET_DEFAULT(keyFunctions.release, default_release);
		SET_DEFAULT(keyFunctions.hash, default_hash);
		SET_DEFAULT(keyFunctions.equal, default_equal);

		SET_DEFAULT(valueFunctions.retain, default_retain);
		SET_DEFAULT(valueFunctions.release, default_release);
		SET_DEFAULT(valueFunctions.hash, default_hash);
		SET_DEFAULT(valueFunctions.equal, default_equal);

#undef SET_DEFAULT

		if (capacity_ > UINT32_MAX ||
		    capacity_ > UINT32_MAX / sizeof(*buckets) ||
		    capacity_ > UINT32_MAX / 8)
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		for (capacity = 1; capacity < capacity_; capacity <<= 1);
		if (capacity_ * 8 / capacity >= 6)
			capacity <<= 1;

		if (capacity < MIN_CAPACITY)
			capacity = MIN_CAPACITY;

		minCapacity = capacity;

		buckets = [self allocMemoryWithSize: sizeof(*buckets)
					      count: capacity];

		memset(buckets, 0, capacity * sizeof(*buckets));

		if (of_hash_seed != 0)
#if defined(OF_HAVE_ARC4RANDOM)
			rotate = arc4random() & 31;
#elif defined(OF_HAVE_RANDOM)
			rotate = random() & 31;
#else
			rotate = rand() & 31;
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

	for (i = 0; i < capacity; i++) {
		if (buckets[i] != NULL && buckets[i] != &deleted) {
			keyFunctions.release(buckets[i]->key);
			valueFunctions.release(buckets[i]->value);
		}
	}

	[super dealloc];
}

- (BOOL)isEqual: (id)mapTable_
{
	OFMapTable *mapTable;
	uint32_t i;

	if (![mapTable_ isKindOfClass: [OFMapTable class]])
		return NO;

	mapTable = mapTable_;

	if (mapTable->count != count ||
	    mapTable->keyFunctions.equal != keyFunctions.equal ||
	    mapTable->valueFunctions.equal != valueFunctions.equal)
		return NO;

	for (i = 0; i < capacity; i++) {
		if (buckets[i] != NULL && buckets[i] != &deleted) {
			void *value = [mapTable valueForKey: buckets[i]->key];

			if (!valueFunctions.equal(value, buckets[i]->value))
				return NO;
		}
	}

	return YES;
}

- (uint32_t)hash
{
	uint32_t i, hash = 0;

	for (i = 0; i < capacity; i++) {
		if (buckets[i] != NULL && buckets[i] != &deleted) {
			hash += OF_ROR(buckets[i]->hash, rotate);
			hash += valueFunctions.hash(buckets[i]->value);
		}
	}

	return hash;
}

- (id)copy
{
	OFMapTable *copy = [[OFMapTable alloc]
	    initWithKeyFunctions: keyFunctions
		  valueFunctions: valueFunctions
			capacity: capacity];

	@try {
		uint32_t i;

		for (i = 0; i < capacity; i++)
			if (buckets[i] != NULL && buckets[i] != &deleted)
				[copy OF_setValue: buckets[i]->value
					   forKey: buckets[i]->key
					     hash: OF_ROR(buckets[i]->hash,
						       rotate)];
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	copy->minCapacity = MIN_CAPACITY;

	return copy;
}

- (size_t)count
{
	return count;
}

- (void*)valueForKey: (void*)key
{
	uint32_t i, hash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	hash = OF_ROL(keyFunctions.hash(key), rotate);
	last = capacity;

	for (i = hash & (capacity - 1); i < last && buckets[i] != NULL; i++) {
		if (buckets[i] == &deleted)
			continue;

		if (keyFunctions.equal(buckets[i]->key, key))
			return buckets[i]->value;
	}

	if (i < last)
		return nil;

	/* In case the last bucket is already used */
	last = hash & (capacity - 1);

	for (i = 0; i < last && buckets[i] != NULL; i++) {
		if (buckets[i] == &deleted)
			continue;

		if (keyFunctions.equal(buckets[i]->key, key))
			return buckets[i]->value;
	}

	return NULL;
}

- (void)OF_resizeForCount: (uint32_t)newCount
{
	uint32_t i, fullness, newCapacity;
	struct of_map_table_bucket **newBuckets;

	if (newCount > UINT32_MAX || newCount > UINT32_MAX / sizeof(*buckets) ||
	    newCount > UINT32_MAX / 8)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	fullness = newCount * 8 / capacity;

	if (fullness >= 6)
		newCapacity = capacity << 1;
	else if (fullness <= 1)
		newCapacity = capacity >> 1;
	else
		return;

	if (newCapacity < capacity && newCapacity < minCapacity)
		return;

	newBuckets = [self allocMemoryWithSize: sizeof(*newBuckets)
					 count: newCapacity];

	for (i = 0; i < newCapacity; i++)
		newBuckets[i] = NULL;

	for (i = 0; i < capacity; i++) {
		if (buckets[i] != NULL && buckets[i] != &deleted) {
			uint32_t j, last;

			last = newCapacity;

			j = buckets[i]->hash & (newCapacity - 1);
			for (; j < last && newBuckets[j] != NULL; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = buckets[i]->hash & (newCapacity - 1);

				for (j = 0; j < last &&
				    newBuckets[j] != NULL; j++);
			}

			assert(j < last);

			newBuckets[j] = buckets[i];
		}
	}

	[self freeMemory: buckets];
	buckets = newBuckets;
	capacity = newCapacity;
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

	hash = OF_ROL(hash, rotate);
	last = capacity;

	for (i = hash & (capacity - 1); i < last && buckets[i] != NULL; i++) {
		if (buckets[i] == &deleted)
			continue;

		if (keyFunctions.equal(buckets[i]->key, key))
			break;
	}

	/* In case the last bucket is already used */
	if (i >= last) {
		last = hash & (capacity - 1);

		for (i = 0; i < last && buckets[i] != NULL; i++) {
			if (buckets[i] == &deleted)
				continue;

			if (keyFunctions.equal(buckets[i]->key, key))
				break;
		}
	}

	/* Key not in dictionary */
	if (i >= last || buckets[i] == NULL || buckets[i] == &deleted ||
	    !keyFunctions.equal(buckets[i]->key, key)) {
		struct of_map_table_bucket *bucket;

		[self OF_resizeForCount: count + 1];

		mutations++;
		last = capacity;

		for (i = hash & (capacity - 1); i < last &&
		    buckets[i] != NULL && buckets[i] != &deleted; i++);

		/* In case the last bucket is already used */
		if (i >= last) {
			last = hash & (capacity - 1);

			for (i = 0; i < last && buckets[i] != NULL &&
			    buckets[i] != &deleted; i++);
		}

		if (i >= last)
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];

		bucket = [self allocMemoryWithSize: sizeof(*bucket)];

		@try {
			bucket->key = keyFunctions.retain(key);
		} @catch (id e) {
			[self freeMemory: bucket];
			@throw e;
		}

		@try {
			bucket->value = valueFunctions.retain(value);
		} @catch (id e) {
			keyFunctions.release(key);
			[self freeMemory: bucket];
			@throw e;
		}

		bucket->hash = hash;

		buckets[i] = bucket;
		count++;

		return;
	}

	old = buckets[i]->value;
	buckets[i]->value = valueFunctions.retain(value);
	valueFunctions.release(old);
}

- (void)setValue: (void*)value
	  forKey: (void*)key
{
	[self OF_setValue: value
		   forKey: key
		     hash: keyFunctions.hash(key)];
}

- (void)removeValueForKey: (void*)key
{
	uint32_t i, hash, last;

	if (key == NULL)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	hash = OF_ROL(keyFunctions.hash(key), rotate);
	last = capacity;

	for (i = hash & (capacity - 1); i < last && buckets[i] != NULL; i++) {
		if (buckets[i] == &deleted)
			continue;

		if (keyFunctions.equal(buckets[i]->key, key)) {
			keyFunctions.release(buckets[i]->key);
			valueFunctions.release(buckets[i]->value);

			[self freeMemory: buckets[i]];
			buckets[i] = &deleted;

			count--;
			mutations++;
			[self OF_resizeForCount: count];

			return;
		}
	}

	if (i < last)
		return;

	/* In case the last bucket is already used */
	last = hash & (capacity - 1);

	for (i = 0; i < last && buckets[i] != NULL; i++) {
		if (buckets[i] == &deleted)
			continue;

		if (keyFunctions.equal(buckets[i]->key, key)) {
			keyFunctions.release(buckets[i]->key);
			valueFunctions.release(buckets[i]->value);

			[self freeMemory: buckets[i]];
			buckets[i] = &deleted;

			count--;
			mutations++;
			[self OF_resizeForCount: count];

			return;
		}
	}
}

- (BOOL)containsValue: (void*)value
{
	uint32_t i;

	if (value == NULL || count == 0)
		return NO;

	for (i = 0; i < capacity; i++)
		if (buckets[i] != NULL && buckets[i] != &deleted)
			if (valueFunctions.equal(buckets[i]->value, value))
				return YES;

	return NO;
}

- (BOOL)containsValueIdenticalTo: (void*)value
{
	uint32_t i;

	if (value == NULL || count == 0)
		return NO;

	for (i = 0; i < capacity; i++)
		if (buckets[i] != NULL && buckets[i] != &deleted)
			if (buckets[i]->value == value)
				return YES;

	return NO;
}

- (OFMapTableEnumerator*)keyEnumerator
{
	return [[[OFMapTableKeyEnumerator alloc]
	    OF_initWithMapTable: self
			buckets: buckets
		       capacity: capacity
	       mutationsPointer: &mutations] autorelease];
}

- (OFMapTableEnumerator*)valueEnumerator
{
	return [[[OFMapTableValueEnumerator alloc]
	    OF_initWithMapTable: self
			buckets: buckets
		       capacity: capacity
	       mutationsPointer: &mutations] autorelease];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	uint32_t j = (uint32_t)state->state;
	int i;

	for (i = 0; i < count_; i++) {
		for (; j < capacity && (buckets[j] == NULL ||
		    buckets[j] == &deleted); j++);

		if (j < capacity) {
			objects[i] = buckets[j]->key;
			j++;
		} else
			break;
	}

	state->state = j;
	state->itemsPtr = objects;
	state->mutationsPtr = &mutations;

	return i;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateKeysAndValuesUsingBlock:
    (of_map_table_enumeration_block_t)block
{
	size_t i;
	BOOL stop = NO;
	unsigned long mutations_ = mutations;

	for (i = 0; i < capacity && !stop; i++) {
		if (mutations != mutations_)
			@throw [OFEnumerationMutationException
			    exceptionWithClass: [self class]
					object: self];

		if (buckets[i] != NULL && buckets[i] != &deleted)
			block(buckets[i]->key, buckets[i]->value, &stop);
	}
}

- (void)replaceValuesUsingBlock: (of_map_table_replace_block_t)block
{
	size_t i;
	BOOL stop = NO;
	unsigned long mutations_ = mutations;

	for (i = 0; i < capacity && !stop; i++) {
		if (mutations != mutations_)
			@throw [OFEnumerationMutationException
			    exceptionWithClass: [self class]
					object: self];

		if (buckets[i] != NULL && buckets[i] != &deleted) {
			void *old, *new;

			new = block(buckets[i]->key, buckets[i]->value, &stop);
			if (new == NULL)
				@throw [OFInvalidArgumentException
				    exceptionWithClass: [self class]
					      selector: _cmd];

			old = buckets[i]->value;
			buckets[i]->value = valueFunctions.retain(new);
			valueFunctions.release(old);
		}
	}
}
#endif

- (of_map_table_functions_t)keyFunctions
{
	return keyFunctions;
}

- (of_map_table_functions_t)valueFunctions
{
	return valueFunctions;
}
@end

@implementation OFMapTableEnumerator
- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	} @catch (id e) {
		[self release];
		@throw e;
	}
}

- OF_initWithMapTable: (OFMapTable*)mapTable_
	      buckets: (struct of_map_table_bucket**)buckets_
	     capacity: (uint32_t)capacity_
     mutationsPointer: (unsigned long*)mutationsPtr_
{
	self = [super init];

	mapTable = [mapTable_ retain];
	buckets = buckets_;
	capacity = capacity_;
	mutations = *mutationsPtr_;
	mutationsPtr = mutationsPtr_;

	return self;
}

- (void)dealloc
{
	[mapTable release];

	[super dealloc];
}

- (void*)nextValue
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (void)reset
{
	if (*mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [mapTable class]
				object: mapTable];

	position = 0;
}
@end

@implementation OFMapTableKeyEnumerator
- (void*)nextValue
{
	if (*mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [mapTable class]
				object: mapTable];

	for (; position < capacity && (buckets[position] == NULL ||
	    buckets[position] == &deleted); position++);

	if (position < capacity)
		return buckets[position++]->key;
	else
		return NULL;
}
@end

@implementation OFMapTableValueEnumerator
- (void*)nextValue
{
	if (*mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [mapTable class]
				object: mapTable];

	for (; position < capacity && (buckets[position] == NULL ||
	    buckets[position] == &deleted); position++);

	if (position < capacity)
		return buckets[position++]->value;
	else
		return NULL;
}
@end

@implementation OFMapTableEnumeratorWrapper
- initWithEnumerator: (OFMapTableEnumerator*)enumerator_
	      object: (id)object_
{
	self = [super init];

	enumerator = [enumerator_ retain];
	object = [object_ retain];

	return self;
}

- (void)dealloc
{
	[enumerator release];
	[object release];

	[super dealloc];
}

- (id)nextObject
{
	id ret;

	@try {
		ret = [enumerator nextValue];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [object class]
				object: object];
	}

	return ret;
}

- (void)reset
{
	@try {
		[enumerator reset];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [object class]
				object: object];
	}
}
@end
