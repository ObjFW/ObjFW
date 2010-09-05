/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFDictionary.h"
#import "OFEnumerator.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "macros.h"

struct of_dictionary_bucket of_dictionary_deleted_bucket = {};

#define BUCKET struct of_dictionary_bucket
#define DELETED &of_dictionary_deleted_bucket

@implementation OFDictionary
+ dictionary;
{
	return [[[self alloc] init] autorelease];
}

+ dictionaryWithDictionary: (OFDictionary*)dict
{
	return [[[self alloc] initWithDictionary: dict] autorelease];
}

+ dictionaryWithObject: (id)obj
		forKey: (id <OFCopying>)key
{
	return [[[self alloc] initWithObject: obj
				      forKey: key] autorelease];
}

+ dictionaryWithObjects: (OFArray*)objs
		forKeys: (OFArray*)keys
{
	return [[[self alloc] initWithObjects: objs
				      forKeys: keys] autorelease];
}

+ dictionaryWithKeysAndObjects: (id <OFCopying>)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [[[self alloc] initWithKey: first
				 argList: args] autorelease];
	va_end(args);

	return ret;
}

- init
{
	self = [super init];

	size = 1;

	@try {
		data = [self allocMemoryWithSize: sizeof(BUCKET*)];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 */
		size = 0;
		[self dealloc];
		@throw e;
	}
	data[0] = NULL;

	return self;
}

- initWithDictionary: (OFDictionary*)dict
{
	uint32_t i;

	self = [super init];

	if (dict == nil) {
		Class c = isa;
		size = 0;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	@try {
		data = [self allocMemoryForNItems: dict->size
					 withSize: sizeof(BUCKET*)];

		for (i = 0; i < dict->size; i++)
			data[i] = NULL;
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, we didn't do anything yet anyway, so [self dealloc]
		 * works.
		 */
		[self dealloc];
		@throw e;
	}

	size = dict->size;
	count = dict->count;

	for (i = 0; i < size; i++) {
		id <OFCopying> key;
		BUCKET *b;

		if (dict->data[i] == NULL || dict->data[i] == DELETED)
			continue;

		@try {
			b = [self allocMemoryWithSize: sizeof(BUCKET)];
			key = [dict->data[i]->key copy];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		}

		@try {
			[dict->data[i]->object retain];
		} @catch (OFException *e) {
			[(id)key release];
			[self dealloc];
			@throw e;
		}

		b->key = key;
		b->object = dict->data[i]->object;
		b->hash = dict->data[i]->hash;
		data[i] = b;
	}

	return self;
}

- initWithObject: (id)obj
	  forKey: (id <OFCopying>)key
{
	uint32_t i;
	BUCKET *b;

	self = [self init];

	@try {
		data = [self allocMemoryForNItems: 2
					 withSize: sizeof(BUCKET*)];

		size = 2;
		for (i = 0; i < size; i++)
			data[i] = NULL;
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, we didn't do anything yet anyway, so [self dealloc]
		 * works.
		 */
		[self dealloc];
		@throw e;
	}

	i = [(id)key hash] & 1;

	@try {
		b = [self allocMemoryWithSize: sizeof(BUCKET)];
		key = [key copy];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	@try {
		[obj retain];
	} @catch (OFException *e) {
		[(id)key release];
		[self dealloc];
		@throw e;
	}

	b->key = key;
	b->object = obj;
	b->hash = [(id)key hash];
	data[i] = b;
	count = 1;

	return self;
}

- initWithObjects: (OFArray*)objs
	  forKeys: (OFArray*)keys
{
	id *objs_carray, *keys_carray;
	size_t i;

	self = [super init];

	@try {
		uint32_t j;

		keys_carray = [keys cArray];
		objs_carray = [objs cArray];
		count = [keys count];

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException newWithClass: isa];

		for (size = 1; size < count; size <<= 1);

		if (size == 0)
			@throw [OFOutOfRangeException newWithClass: isa];

		data = [self allocMemoryForNItems: size
					 withSize: sizeof(BUCKET*)];

		for (j = 0; j < size; j++)
			data[j] = NULL;
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 */
		size = 0;
		[self dealloc];
		@throw e;
	}

	for (i = 0; i < count; i++) {
		uint32_t j, hash, last;

		hash = [keys_carray[i] hash];
		last = size;

		for (j = hash & (size - 1); j < last && data[j] != NULL; j++)
			if ([(id)data[j]->key isEqual: keys_carray[i]])
				break;

		/* In case the last bucket is already used */
		if (j >= last) {
			last = hash & (size - 1);

			for (j = 0; j < last && data[j] != NULL; j++)
				if ([(id)data[j]->key isEqual: keys_carray[i]])
					break;
		}

		/* Key not in dictionary */
		if (j >= last || data[j] == NULL ||
		    ![(id)data[j]->key isEqual: keys_carray[i]]) {
			BUCKET *b;
			id <OFCopying> key;

			last = size;

			j = hash & (size - 1);
			for (; j < last && data[j] != NULL; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = hash & (size - 1);

				for (j = 0; j < last && data[j] != NULL; j++);
			}

			if (j >= last) {
				Class c = isa;
				[self dealloc];
				@throw [OFOutOfRangeException newWithClass: c];
			}

			@try {
				b = [self allocMemoryWithSize: sizeof(BUCKET)];
				key = [keys_carray[i] copy];
			} @catch (OFException *e) {
				[self dealloc];
				@throw e;
			}

			@try {
				[objs_carray[i] retain];
			} @catch (OFException *e) {
				[(id)key release];
				[self dealloc];
				@throw e;
			}

			b->key = key;
			b->object = objs_carray[i];
			b->hash = hash;
			data[j] = b;

			continue;
		}

		/*
		 * They key is already in the dictionary. However, we just
		 * replace it so that the programmer gets the same behavior
		 * as if he'd call setObject:forKey: for each key/object pair.
		 */
		@try {
			[objs_carray[i] retain];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		}

		@try {
			[data[j]->object release];
		} @catch (OFException *e) {
			[objs_carray[i] release];
			[self dealloc];
			@throw e;
		}

		data[j]->object = objs_carray[i];
	}

	return self;
}

- initWithKeysAndObjects: (id <OFCopying>)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [self initWithKey: first
			argList: args];
	va_end(args);

	return ret;
}

- initWithKey: (id <OFCopying>)key
      argList: (va_list)args
{
	BUCKET *b;
	id obj;
	size_t i;
	uint32_t j, hash;
	va_list args2;

	self = [super init];

	count = 1;
	for (va_copy(args2, args); va_arg(args2, id) != nil; count++);
	count >>= 1;

	if (count > UINT32_MAX) {
		Class c = isa;
		[self dealloc];
		@throw [OFOutOfRangeException newWithClass: c];
	}

	for (size = 1; size < count; size <<= 1);

	if (size == 0) {
		Class c = isa;
		[self dealloc];
		@throw [OFOutOfRangeException newWithClass: c];
	}

	@try {
		data = [self allocMemoryForNItems: size
					 withSize: sizeof(BUCKET*)];

		for (j = 0; j < size; j++)
			data[j] = NULL;
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 *                                                    */
		size = 0;
		[self dealloc];
		@throw e;
	}

	if (key == nil) {
		Class c = isa;
		size = 0;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	if ((obj = va_arg(args, id)) == nil) {
		Class c = isa;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	/* Add first key / object pair */
	hash = [(id)key hash];
	j = hash & (size - 1);

	@try {
		b = [self allocMemoryWithSize: sizeof(BUCKET)];
		key = [key copy];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	@try {
		[obj retain];
	} @catch (OFException *e) {
		[(id)key release];
		[self dealloc];
		@throw e;
	}

	b->key = key;
	b->object = obj;
	b->hash = hash;
	data[j] = b;

	for (i = 1; i < count; i++) {
		uint32_t last;

		key = va_arg(args, id <OFCopying>);
		obj = va_arg(args, id);

		if (key == nil || obj == nil) {
			Class c = isa;
			[self dealloc];
			@throw [OFInvalidArgumentException newWithClass: c
							       selector: _cmd];
		}

		hash = [(id)key hash];
		last = size;

		for (j = hash & (size - 1); j < last && data[j] != NULL; j++)
			if ([(id)data[j]->key isEqual: key])
				break;

		/* In case the last bucket is already used */
		if (j >= last) {
			last = hash & (size - 1);

			for (j = 0; j < last && data[j] != NULL; j++)
				if ([(id)data[j]->key isEqual: key])
					break;
		}

		/* Key not in dictionary */
		if (j >= last || data[j] == NULL ||
		    ![(id)data[j]->key isEqual: key]) {
			last = size;

			j = hash & (size - 1);
			for (; j < last && data[j] != NULL; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = hash & (size - 1);

				for (j = 0; j < last && data[j] != NULL; j++);
			}

			if (j >= last) {
				Class c = isa;
				[self dealloc];
				@throw [OFOutOfRangeException newWithClass: c];
			}

			@try {
				b = [self allocMemoryWithSize: sizeof(BUCKET)];
				key = [key copy];
			} @catch (OFException *e) {
				[self dealloc];
				@throw e;
			}

			@try {
				[obj retain];
			} @catch (OFException *e) {
				[(id)key release];
				[self dealloc];
				@throw e;
			}

			b->key = key;
			b->object = obj;
			b->hash = hash;
			data[j] = b;

			continue;
		}

		/*
		 * They key is already in the dictionary. However, we just
		 * replace it so that the programmer gets the same behavior
		 * as if he'd call setObject:forKey: for each key/object pair.
		 */
		@try {
			[obj retain];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		}

		@try {
			[data[j]->object release];
		} @catch (OFException *e) {
			[obj release];
			[self dealloc];
			@throw e;
		}

		data[j]->object = obj;
	}

	return self;
}

- (id)objectForKey: (id)key
{
	uint32_t i, hash, last;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];
	last = size;

	for (i = hash & (size - 1); i < last && data[i] != NULL; i++) {
		if (data[i] == DELETED)
			continue;

		if ([(id)data[i]->key isEqual: key])
			return data[i]->object;
	}

	if (i < last)
		return nil;

	/* In case the last bucket is already used */
	last = hash & (size - 1);

	for (i = 0; i < last && data[i] != NULL; i++) {
		if (data[i] == DELETED)
			continue;

		if ([(id)data[i]->key isEqual: key])
			return data[i]->object;
	}

	return nil;
}

- (size_t)count
{
	return count;
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableDictionary alloc] initWithDictionary: self];
}

- (BOOL)isEqual: (OFDictionary*)dict
{
	uint32_t i;

	if ([dict count] != count)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i]!= DELETED &&
		    ![[dict objectForKey: data[i]->key]
		    isEqual: data[i]->object])
			return NO;

	return YES;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	int i;

	for (i = 0; i < count_; i++) {
		for (; state->state < size && (data[state->state] == NULL ||
		    data[state->state] == DELETED); state->state++);

		if (state->state < size) {
			objects[i] = data[state->state]->key;
			state->state++;
		} else
			break;
	}

	state->itemsPtr = objects;
	state->mutationsPtr = (unsigned long*)self;

	return i;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFDictionaryObjectEnumerator alloc]
		initWithData: data
			size: size
	    mutationsPointer: NULL] autorelease];
}

- (OFEnumerator*)keyEnumerator
{
	return [[[OFDictionaryKeyEnumerator alloc]
		initWithData: data
			size: size
	    mutationsPointer: NULL] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_dictionary_enumeration_block_t)block
{
	size_t i;
	BOOL stop = NO;

	for (i = 0; i < size && !stop; i++)
		if (data[i] != NULL && data[i] != DELETED)
			block(data[i]->key, data[i]->object, &stop);
}
#endif

- (void)dealloc
{
	uint32_t i;

	for (i = 0; i < size; i++) {
		if (data[i] != NULL && data[i] != DELETED) {
			[(id)data[i]->key release];
			[data[i]->object release];
		}
	}

	[super dealloc];
}

- (uint32_t)hash
{
	uint32_t i;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < size; i++) {
		if (data[i] != NULL && data[i] != DELETED) {
			uint32_t h = [data[i]->object hash];

			OF_HASH_ADD(hash, data[i]->hash >> 24);
			OF_HASH_ADD(hash, (data[i]->hash >> 16) & 0xFF);
			OF_HASH_ADD(hash, (data[i]->hash >> 8) & 0xFF);
			OF_HASH_ADD(hash, data[i]->hash & 0xFF);

			OF_HASH_ADD(hash, h >> 24);
			OF_HASH_ADD(hash, (h >> 16) & 0xFF);
			OF_HASH_ADD(hash, (h >> 8) & 0xFF);
			OF_HASH_ADD(hash, h & 0xFF);
		}
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end

/// \cond internal
@implementation OFDictionaryEnumerator
-     initWithData: (struct of_dictionary_bucket**)data_
	      size: (uint32_t)size_
  mutationsPointer: (unsigned long*)mutationsPtr_
{
	self = [super init];

	data = data_;
	size = size_;
	mutations = (mutationsPtr_ != NULL ? *mutationsPtr_ : 0);
	mutationsPtr = mutationsPtr_;

	return self;
}

- (void)reset
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	pos = 0;
}
@end

@implementation OFDictionaryObjectEnumerator
- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	for (; pos < size && (data[pos] == NULL ||
	    data[pos] == DELETED); pos++);

	if (pos < size)
		return data[pos++]->object;
	else
		return nil;
}
@end

@implementation OFDictionaryKeyEnumerator
- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	for (; pos < size && (data[pos] == NULL ||
	    data[pos] == DELETED); pos++);

	if (pos < size)
		return data[pos++]->key;
	else
		return nil;
}
@end
/// \endcond
