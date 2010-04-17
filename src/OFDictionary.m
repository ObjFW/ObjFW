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

const int of_dictionary_deleted_bucket = 0;

#define BUCKET_SIZE sizeof(struct of_dictionary_bucket)
#define DELETED (id)&of_dictionary_deleted_bucket

@implementation OFDictionary
+ dictionary;
{
	return [[[self alloc] init] autorelease];
}

+ dictionaryWithDictionary: (OFDictionary*)dict
{
	return [[[self alloc] initWithDictionary: dict] autorelease];
}

+ dictionaryWithObject: (OFObject*)obj
		forKey: (OFObject <OFCopying>*)key
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

+ dictionaryWithKeysAndObjects: (OFObject <OFCopying>*)first, ...
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
		data = [self allocMemoryWithSize: BUCKET_SIZE];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 */
		size = 0;
		[self dealloc];
		@throw e;
	}
	data[0].key = nil;

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
					 withSize: BUCKET_SIZE];
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
		OFObject <OFCopying> *key;

		if (dict->data[i].key == nil || dict->data[i].key == DELETED) {
			data[i].key = nil;
			continue;
		}

		@try {
			key = [dict->data[i].key copy];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		}

		@try {
			[dict->data[i].object retain];
		} @catch (OFException *e) {
			[key release];
			[self dealloc];
			@throw e;
		}

		data[i].key = key;
		data[i].object = dict->data[i].object;
		data[i].hash = dict->data[i].hash;
	}

	return self;
}

- initWithObject: (OFObject*)obj
	  forKey: (OFObject <OFCopying>*)key
{
	uint32_t i;

	self = [self init];

	@try {
		data = [self allocMemoryForNItems: 2
					 withSize: BUCKET_SIZE];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, we didn't do anything yet anyway, so [self dealloc]
		 * works.
		 */
		[self dealloc];
		@throw e;
	}
	memset(data, 0, 2 * BUCKET_SIZE);
	size = 2;

	i = [key hash] & 1;

	@try {
		key = [key copy];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	@try {
		[obj retain];
	} @catch (OFException *e) {
		[key release];
		[self dealloc];
		@throw e;
	}

	data[i].key = key;
	data[i].object = obj;
	data[i].hash = [key hash];
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
		keys_carray = [keys cArray];
		objs_carray = [objs cArray];
		count = [keys count];

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException newWithClass: isa];

		for (size = 1; size < count; size <<= 1);

		if (size == 0)
			@throw [OFOutOfRangeException newWithClass: isa];

		data = [self allocMemoryForNItems: size
					 withSize: BUCKET_SIZE];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 */
		size = 0;
		[self dealloc];
		@throw e;
	}
	memset(data, 0, size * BUCKET_SIZE);

	for (i = 0; i < count; i++) {
		uint32_t j, hash, last;

		hash = [keys_carray[i] hash];
		last = size;

		for (j = hash & (size - 1); j < last && data[j].key != nil &&
		    ![data[j].key isEqual: keys_carray[i]]; j++);

		/* In case the last bucket is already used */
		if (j >= last) {
			last = hash & (size - 1);

			for (j = 0; j < last && data[j].key != nil &&
			    ![data[j].key isEqual: keys_carray[i]]; j++);
		}

		/* Key not in dictionary */
		if (j >= last || ![data[j].key isEqual: keys_carray[i]]) {
			OFObject <OFCopying> *key;

			last = size;

			j = hash & (size - 1);
			for (; j < last && data[j].key != nil; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = hash & (size - 1);

				for (j = 0; j < last && data[j].key != nil;
				    j++);
			}

			if (j >= last) {
				Class c = isa;
				[self dealloc];
				@throw [OFOutOfRangeException newWithClass: c];
			}

			@try {
				key = [keys_carray[i] copy];
			} @catch (OFException *e) {
				[self dealloc];
				@throw e;
			}

			@try {
				[objs_carray[i] retain];
			} @catch (OFException *e) {
				[key release];
				[self dealloc];
				@throw e;
			}

			data[j].key = key;
			data[j].object = objs_carray[i];
			data[j].hash = hash;

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
			[data[j].object release];
		} @catch (OFException *e) {
			[objs_carray[i] release];
			[self dealloc];
			@throw e;
		}

		data[j].object = objs_carray[i];
	}

	return self;
}

- initWithKeysAndObjects: (OFObject <OFCopying>*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [self initWithKey: first
			argList: args];
	va_end(args);

	return ret;
}

- initWithKey: (OFObject <OFCopying>*)key
      argList: (va_list)args
{
	OFObject *obj;
	size_t i;
	uint32_t j, hash;
	va_list args2;

	self = [super init];

	count = 1;
	for (va_copy(args2, args); va_arg(args2, OFObject*) != nil; count++);
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
					 withSize: BUCKET_SIZE];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self dealloc] works.
		 *                                                    */
		size = 0;
		[self dealloc];
		@throw e;
	}
	memset(data, 0, size * BUCKET_SIZE);

	if (key == nil)
		return self;

	if ((obj = va_arg(args, OFObject*)) == nil) {
		Class c = isa;
		[self dealloc];
		@throw [OFInvalidArgumentException newWithClass: c
						       selector: _cmd];
	}

	/* Add first key / object pair */
	hash = [key hash];
	j = hash & (size - 1);

	@try {
		key = [key copy];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	@try {
		[obj retain];
	} @catch (OFException *e) {
		[key release];
		[self dealloc];
		@throw e;
	}

	data[j].key = key;
	data[j].object = obj;
	data[j].hash = hash;

	for (i = 1; i < count; i++) {
		uint32_t last;

		key = va_arg(args, OFObject <OFCopying>*);
		obj = va_arg(args, OFObject*);

		if (key == nil || obj == nil) {
			Class c = isa;
			[self dealloc];
			@throw [OFInvalidArgumentException newWithClass: c
							       selector: _cmd];
		}

		hash = [key hash];
		last = size;

		for (j = hash & (size - 1); j < last && data[j].key != nil &&
		    ![data[j].key isEqual: key]; j++);

		/* In case the last bucket is already used */
		if (j >= last) {
			last = hash & (size - 1);

			for (j = 0; j < last && data[j].key != nil &&
			    ![data[j].key isEqual: key]; j++);
		}

		/* Key not in dictionary */
		if (j >= last || ![data[j].key isEqual: key]) {
			last = size;

			j = hash & (size - 1);
			for (; j < last && data[j].key != nil; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = hash & (size - 1);

				for (j = 0; j < last && data[j].key != nil;
				    j++);
			}

			if (j >= last) {
				Class c = isa;
				[self dealloc];
				@throw [OFOutOfRangeException newWithClass: c];
			}

			@try {
				key = [key copy];
			} @catch (OFException *e) {
				[self dealloc];
				@throw e;
			}

			@try {
				[obj retain];
			} @catch (OFException *e) {
				[key release];
				[self dealloc];
				@throw e;
			}

			data[j].key = key;
			data[j].object = obj;
			data[j].hash = hash;

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
			[data[j].object release];
		} @catch (OFException *e) {
			[obj release];
			[self dealloc];
			@throw e;
		}

		data[j].object = obj;
	}

	return self;
}

- (id)objectForKey: (OFObject <OFCopying>*)key
{
	uint32_t i, hash, last;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];
	last = size;

	for (i = hash & (size - 1); i < last && data[i].key != nil &&
	    (data[i].key == DELETED || ![data[i].key isEqual: key]); i++);

	if (i < last && (data[i].key == nil || data[i].key == DELETED))
		return nil;

	/* In case the last bucket is already used */
	if (i >= last) {
		last = hash & (size - 1);

		for (i = 0; i < last && data[i].key != nil &&
		    (data[i].key == DELETED || ![data[i].key isEqual: key]);
		    i++);
	}

	/* Key not in dictionary */
	if (i >= last || data[i].key == nil || data[i].key == DELETED ||
	    ![data[i].key isEqual: key])
		return nil;

	return [[data[i].object retain] autorelease];
}

- (size_t)count
{
	return count;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableDictionary alloc] initWithDictionary: self];
}

- (BOOL)isEqual: (OFDictionary*)dict
{
	uint32_t i;

	if ([dict count] != count)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i].key != nil && data[i].key != DELETED &&
		    ![[dict objectForKey: data[i].key] isEqual: data[i].object])
			return NO;

	return YES;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	int i;

	for (i = 0; i < count_; i++) {
		for (; state->state < size && (data[state->state].key == nil ||
		    data[state->state].key == DELETED); state->state++);

		if (state->state < size) {
			objects[i] = data[state->state].key;
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

- (void)dealloc
{
	uint32_t i;

	for (i = 0; i < size; i++) {
		if (data[i].key != nil && data[i].key != DELETED) {
			[data[i].key release];
			[data[i].object release];
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
		if (data[i].key != nil && data[i].key != DELETED) {
			uint32_t kh = [data[i].key hash];

			OF_HASH_ADD(hash, kh >> 24);
			OF_HASH_ADD(hash, (kh >> 16) & 0xFF);
			OF_HASH_ADD(hash, (kh >> 8) & 0xFF);
			OF_HASH_ADD(hash, kh & 0xFF);

			OF_HASH_ADD(hash, data[i].hash >> 24);
			OF_HASH_ADD(hash, (data[i].hash >> 16) & 0xFF);
			OF_HASH_ADD(hash, (data[i].hash >> 8) & 0xFF);
			OF_HASH_ADD(hash, data[i].hash & 0xFF);
		}
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end

/// \cond internal
@implementation OFDictionaryEnumerator
-     initWithData: (struct of_dictionary_bucket*)data_
	      size: (uint32_t)size_
  mutationsPointer: (unsigned long*)mutations_ptr_
{
	self = [super init];

	data = data_;
	size = size_;
	mutations = *mutations_ptr_;
	mutations_ptr = mutations_ptr_;

	return self;
}

- reset
{
	if (mutations_ptr != NULL && *mutations_ptr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	pos = 0;

	return self;
}
@end

@implementation OFDictionaryObjectEnumerator
- (id)nextObject
{
	if (mutations_ptr != NULL && *mutations_ptr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	for (; pos < size && (data[pos].key == nil ||
	    data[pos].key == DELETED); pos++);

	if (pos < size)
		return data[pos++].object;
	else
		return nil;
}
@end

@implementation OFDictionaryKeyEnumerator
- (id)nextObject
{
	if (mutations_ptr != NULL && *mutations_ptr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	for (; pos < size && (data[pos].key == nil ||
	    data[pos].key == DELETED); pos++);

	if (pos < size)
		return data[pos++].key;
	else
		return nil;
}
@end
/// \endcond
