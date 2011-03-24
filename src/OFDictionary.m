/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#include <string.h>

#import "OFDictionary.h"
#import "OFEnumerator.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

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

	@try {
		data = [self allocMemoryWithSize: sizeof(BUCKET*)];
		size = 1;
		data[0] = NULL;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithDictionary: (OFDictionary*)dict
{
	self = [super init];

	@try {
		uint32_t i;

		if (dict == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		data = [self allocMemoryForNItems: dict->size
					 withSize: sizeof(BUCKET*)];

		for (i = 0; i < dict->size; i++)
			data[i] = NULL;

		size = dict->size;
		count = dict->count;

		for (i = 0; i < size; i++) {
			id <OFCopying> key;
			BUCKET *b;

			if (dict->data[i] == NULL || dict->data[i] == DELETED)
				continue;

			b = [self allocMemoryWithSize: sizeof(BUCKET)];
			key = [dict->data[i]->key copy];

			@try {
				[dict->data[i]->object retain];
			} @catch (id e) {
				[(id)key release];
				@throw e;
			}

			b->key = key;
			b->object = dict->data[i]->object;
			b->hash = dict->data[i]->hash;

			data[i] = b;
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)obj
	  forKey: (id <OFCopying>)key
{
	self = [super init];

	@try {
		uint32_t i;
		BUCKET *b;

		data = [self allocMemoryForNItems: 2
					 withSize: sizeof(BUCKET*)];

		size = 2;
		for (i = 0; i < size; i++)
			data[i] = NULL;

		i = [(id)key hash] & 1;
		b = [self allocMemoryWithSize: sizeof(BUCKET)];
		key = [key copy];

		@try {
			[obj retain];
		} @catch (id e) {
			[(id)key release];
			@throw e;
		}

		b->key = key;
		b->object = obj;
		b->hash = [(id)key hash];

		data[i] = b;
		count = 1;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObjects: (OFArray*)objs
	  forKeys: (OFArray*)keys
{
	self = [super init];

	@try {
		id *objs_carray, *keys_carray;
		uint32_t i, j, nsize;

		keys_carray = [keys cArray];
		objs_carray = [objs cArray];
		count = [keys count];

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException newWithClass: isa];

		for (nsize = 1; nsize < count; nsize <<= 1);

		if (nsize == 0)
			@throw [OFOutOfRangeException newWithClass: isa];

		data = [self allocMemoryForNItems: nsize
					 withSize: sizeof(BUCKET*)];

		for (j = 0; j < nsize; j++)
			data[j] = NULL;

		size = nsize;

		for (i = 0; i < count; i++) {
			uint32_t hash, last;

			hash = [keys_carray[i] hash];
			last = size;

			for (j = hash & (size - 1); j < last && data[j] != NULL;
			    j++)
				if ([(id)data[j]->key isEqual: keys_carray[i]])
					break;

			/* In case the last bucket is already used */
			if (j >= last) {
				last = hash & (size - 1);

				for (j = 0; j < last && data[j] != NULL; j++)
					if ([(id)data[j]->key
					    isEqual: keys_carray[i]])
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

					for (j = 0; j < last && data[j] != NULL;
					    j++);
				}

				if (j >= last)
					@throw [OFOutOfRangeException
					    newWithClass: isa];

				b = [self allocMemoryWithSize: sizeof(BUCKET)];
				key = [keys_carray[i] copy];

				@try {
					[objs_carray[i] retain];
				} @catch (id e) {
					[(id)key release];
					@throw e;
				}

				b->key = key;
				b->object = objs_carray[i];
				b->hash = hash;

				data[j] = b;

				continue;
			}

			/*
			 * The key is already in the dictionary. However, we
			 * just replace it so that the programmer gets the same
			 * behavior as if he'd call setObject:forKey: for each
			 * key/object pair.
			 */
			[objs_carray[i] retain];

			@try {
				[data[j]->object release];
			} @catch (id e) {
				[objs_carray[i] release];
				@throw e;
			}

			data[j]->object = objs_carray[i];
		}
	} @catch (id e) {
		[self release];
		@throw e;
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
	self = [super init];

	@try {
		id obj;
		uint32_t i, j, hash, nsize;
		va_list args2;
		BUCKET *b;

		va_copy(args2, args);

		if (key == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		if ((obj = va_arg(args, id)) == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		count = 1;
		for (; va_arg(args2, id) != nil; count++);
		count >>= 1;

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException newWithClass: isa];

		for (nsize = 1; nsize < count; nsize <<= 1);

		if (nsize == 0)
			@throw [OFOutOfRangeException newWithClass: isa];

		data = [self allocMemoryForNItems: nsize
					 withSize: sizeof(BUCKET*)];

		for (j = 0; j < nsize; j++)
			data[j] = NULL;

		size = nsize;

		/* Add first key / object pair */
		hash = [(id)key hash];
		j = hash & (size - 1);

		b = [self allocMemoryWithSize: sizeof(BUCKET)];
		key = [key copy];

		@try {
			[obj retain];
		} @catch (id e) {
			[(id)key release];
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

			if (key == nil || obj == nil)
				@throw [OFInvalidArgumentException
				    newWithClass: isa
					selector: _cmd];

			hash = [(id)key hash];
			last = size;

			for (j = hash & (size - 1); j < last && data[j] != NULL;
			    j++)
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

					for (j = 0; j < last && data[j] != NULL;
					    j++);
				}

				if (j >= last)
					@throw [OFOutOfRangeException
					    newWithClass: isa];

				b = [self allocMemoryWithSize: sizeof(BUCKET)];
				key = [key copy];

				@try {
					[obj retain];
				} @catch (id e) {
					[(id)key release];
					@throw e;
				}

				b->key = key;
				b->object = obj;
				b->hash = hash;

				data[j] = b;

				continue;
			}

			/*
			 * The key is already in the dictionary. However, we
			 * just replace it so that the programmer gets the same
			 * behavior as if he'd call setObject:forKey: for each
			 * key/object pair.
			 */
			[obj retain];

			@try {
				[data[j]->object release];
			} @catch (id e) {
				[obj release];
				@throw e;
			}

			data[j]->object = obj;
		}
	} @catch (id e) {
		[self release];
		@throw e;
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

- (BOOL)isEqual: (id)dict
{
	uint32_t i;

	if ([dict count] != count)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED &&
		    ![[dict objectForKey: data[i]->key]
		    isEqual: data[i]->object])
			return NO;

	return YES;
}

- (BOOL)containsObject: (id)obj
{
	uint32_t i;

	if (count == 0)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED &&
		    [data[i]->object isEqual: obj])
			return YES;

	return NO;
}

- (BOOL)containsObjectIdenticalTo: (id)obj
{
	uint32_t i;

	if (count == 0)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED &&
		    data[i]->object == obj)
			return YES;

	return NO;
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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	size_t i;
	BOOL stop = NO;

	for (i = 0; i < size && !stop; i++) {
		if (data[i] != NULL && data[i] != DELETED) {
			block(data[i]->key, data[i]->object, &stop);
			[pool releaseObjects];
		}
	}

	[pool release];
}

- (OFDictionary*)mappedDictionaryUsingBlock: (of_dictionary_map_block_t)block
{
	OFMutableDictionary *dict = [OFMutableDictionary dictionary];
	size_t i;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED)
			[dict setObject: block(data[i]->key, data[i]->object)
				 forKey: data[i]->key];

	/*
	 * Class swizzle the dictionary to be immutable. We declared the return
	 * type to be OFDictionary*, so it can't be modified anyway. But not
	 * swizzling it would create a real copy each time -[copy] is called.
	 */
	dict->isa = [OFDictionary class];
	return dict;
}

- (OFDictionary*)filteredDictionaryUsingBlock:
    (of_dictionary_filter_block_t)block
{
	OFMutableDictionary *dict = [OFMutableDictionary dictionary];
	size_t i;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED)
			if (block(data[i]->key, data[i]->object))
				[dict setObject: data[i]->object
					 forKey: data[i]->key];

	/*
	 * Class swizzle the dictionary to be immutable. We declared the return
	 * type to be OFDictionary*, so it can't be modified anyway. But not
	 * swizzling it would create a real copy each time -[copy] is called.
	 */
	dict->isa = [OFDictionary class];
	return dict;
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

- (OFString*)description
{
	OFMutableString *ret = [OFMutableString stringWithString: @"{"];
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;
	OFEnumerator *enumerator = [self keyEnumerator];
	id key;
	size_t i;

	i = 0;
	pool2 = [[OFAutoreleasePool alloc] init];

	while ((key = [enumerator nextObject]) != nil) {
		[ret appendString: [key description]];
		[ret appendString: @" = "];
		[ret appendString: [[self objectForKey: key] description]];

		if (++i < count)
			[ret appendString: @"; "];

		[pool2 releaseObjects];
	}
	[ret appendString: @"}"];

	[pool release];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}
@end

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
