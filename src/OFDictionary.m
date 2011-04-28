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

#define DELETED &of_dictionary_deleted_bucket

@implementation OFDictionary
+ dictionary;
{
	return [[[self alloc] init] autorelease];
}

+ dictionaryWithDictionary: (OFDictionary*)dictionary
{
	return [[[self alloc] initWithDictionary: dictionary] autorelease];
}

+ dictionaryWithObject: (id)object
		forKey: (id <OFCopying>)key
{
	return [[[self alloc] initWithObject: object
				      forKey: key] autorelease];
}

+ dictionaryWithObjects: (OFArray*)objects
		forKeys: (OFArray*)keys
{
	return [[[self alloc] initWithObjects: objects
				      forKeys: keys] autorelease];
}

+ dictionaryWithKeysAndObjects: (id <OFCopying>)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [[[self alloc] initWithKey: firstKey
			       arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

- init
{
	self = [super init];

	@try {
		data = [self allocMemoryWithSize:
		    sizeof(struct of_dictionary_bucket)];
		size = 1;
		data[0] = NULL;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithDictionary: (OFDictionary*)dictionary
{
	self = [super init];

	@try {
		uint32_t i;

		if (dictionary == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		data = [self allocMemoryForNItems: dictionary->size
					 withSize: sizeof(*data)];

		for (i = 0; i < dictionary->size; i++)
			data[i] = NULL;

		size = dictionary->size;
		count = dictionary->count;

		for (i = 0; i < size; i++) {
			id <OFCopying> key;
			struct of_dictionary_bucket *bucket;

			if (dictionary->data[i] == NULL ||
			    dictionary->data[i] == DELETED)
				continue;

			bucket = [self allocMemoryWithSize: sizeof(*bucket)];
			key = [dictionary->data[i]->key copy];

			@try {
				[dictionary->data[i]->object retain];
			} @catch (id e) {
				[key release];
				@throw e;
			}

			bucket->key = key;
			bucket->object = dictionary->data[i]->object;
			bucket->hash = dictionary->data[i]->hash;

			data[i] = bucket;
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)object
	  forKey: (id <OFCopying>)key
{
	self = [super init];

	@try {
		uint32_t i;
		struct of_dictionary_bucket *bucket;

		if (key == nil || object == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		data = [self allocMemoryForNItems: 2
					 withSize: sizeof(*bucket)];

		size = 2;
		for (i = 0; i < size; i++)
			data[i] = NULL;

		i = [key hash] & 1;
		bucket = [self allocMemoryWithSize: sizeof(*bucket)];
		key = [key copy];

		@try {
			[object retain];
		} @catch (id e) {
			[key release];
			@throw e;
		}

		bucket->key = key;
		bucket->object = object;
		bucket->hash = [key hash];

		data[i] = bucket;
		count = 1;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObjects: (OFArray*)objects
	  forKeys: (OFArray*)keys
{
	self = [super init];

	@try {
		id *objectsCArray, *keysCArray;
		uint32_t i, j, newSize;

		keysCArray = [keys cArray];
		objectsCArray = [objects cArray];
		count = [keys count];

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException newWithClass: isa];

		for (newSize = 1; newSize < count; newSize <<= 1);

		if (newSize == 0)
			@throw [OFOutOfRangeException newWithClass: isa];

		data = [self allocMemoryForNItems: newSize
					 withSize: sizeof(*data)];

		for (j = 0; j < newSize; j++)
			data[j] = NULL;

		size = newSize;

		for (i = 0; i < count; i++) {
			uint32_t hash, last;

			hash = [keysCArray[i] hash];
			last = size;

			for (j = hash & (size - 1); j < last && data[j] != NULL;
			    j++)
				if ([data[j]->key isEqual: keysCArray[i]])
					break;

			/* In case the last bucket is already used */
			if (j >= last) {
				last = hash & (size - 1);

				for (j = 0; j < last && data[j] != NULL; j++)
					if ([data[j]->key
					    isEqual: keysCArray[i]])
						break;
			}

			/* Key not in dictionary */
			if (j >= last || data[j] == NULL ||
			    ![data[j]->key isEqual: keysCArray[i]]) {
				struct of_dictionary_bucket *bucket;
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

				bucket =
				    [self allocMemoryWithSize: sizeof(*bucket)];
				key = [keysCArray[i] copy];

				@try {
					[objectsCArray[i] retain];
				} @catch (id e) {
					[key release];
					@throw e;
				}

				bucket->key = key;
				bucket->object = objectsCArray[i];
				bucket->hash = hash;

				data[j] = bucket;

				continue;
			}

			/*
			 * The key is already in the dictionary. However, we
			 * just replace it so that the programmer gets the same
			 * behavior as if he'd call setObject:forKey: for each
			 * key/object pair.
			 */
			[objectsCArray[i] retain];

			@try {
				[data[j]->object release];
			} @catch (id e) {
				[objectsCArray[i] release];
				@throw e;
			}

			data[j]->object = objectsCArray[i];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithKeysAndObjects: (id <OFCopying>)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [self initWithKey: firstKey
		      arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithKey: (id <OFCopying>)firstKey
    arguments: (va_list)arguments
{
	self = [super init];

	@try {
		id key, object;
		uint32_t i, j, hash, newSize;
		va_list argumentsCopy;
		struct of_dictionary_bucket *bucket;

		va_copy(argumentsCopy, arguments);

		if (firstKey == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		key = firstKey;

		if ((object = va_arg(arguments, id)) == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		count = 1;
		for (; va_arg(argumentsCopy, id) != nil; count++);
		count >>= 1;

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException newWithClass: isa];

		for (newSize = 1; newSize < count; newSize <<= 1);

		if (newSize == 0)
			@throw [OFOutOfRangeException newWithClass: isa];

		data = [self allocMemoryForNItems: newSize
					 withSize: sizeof(*data)];

		for (j = 0; j < newSize; j++)
			data[j] = NULL;

		size = newSize;

		/* Add first key / object pair */
		hash = [key hash];
		j = hash & (size - 1);

		bucket = [self allocMemoryWithSize: sizeof(*bucket)];
		key = [key copy];

		@try {
			[object retain];
		} @catch (id e) {
			[key release];
			@throw e;
		}

		bucket->key = key;
		bucket->object = object;
		bucket->hash = hash;

		data[j] = bucket;

		for (i = 1; i < count; i++) {
			uint32_t last;

			key = va_arg(arguments, id <OFCopying>);
			object = va_arg(arguments, id);

			if (key == nil || object == nil)
				@throw [OFInvalidArgumentException
				    newWithClass: isa
					selector: _cmd];

			hash = [key hash];
			last = size;

			for (j = hash & (size - 1); j < last && data[j] != NULL;
			    j++)
				if ([data[j]->key isEqual: key])
					break;

			/* In case the last bucket is already used */
			if (j >= last) {
				last = hash & (size - 1);

				for (j = 0; j < last && data[j] != NULL; j++)
					if ([data[j]->key isEqual: key])
						break;
			}

			/* Key not in dictionary */
			if (j >= last || data[j] == NULL ||
			    ![data[j]->key isEqual: key]) {
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

				bucket =
				    [self allocMemoryWithSize: sizeof(*bucket)];
				key = [key copy];

				@try {
					[object retain];
				} @catch (id e) {
					[key release];
					@throw e;
				}

				bucket->key = key;
				bucket->object = object;
				bucket->hash = hash;

				data[j] = bucket;

				continue;
			}

			/*
			 * The key is already in the dictionary. However, we
			 * just replace it so that the programmer gets the same
			 * behavior as if he'd call setObject:forKey: for each
			 * key/object pair.
			 */
			[object retain];

			@try {
				[data[j]->object release];
			} @catch (id e) {
				[object release];
				@throw e;
			}

			data[j]->object = object;
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

		if ([data[i]->key isEqual: key])
			return data[i]->object;
	}

	if (i < last)
		return nil;

	/* In case the last bucket is already used */
	last = hash & (size - 1);

	for (i = 0; i < last && data[i] != NULL; i++) {
		if (data[i] == DELETED)
			continue;

		if ([data[i]->key isEqual: key])
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
	    initWithDictionary: self
			  data: data
			  size: size
	      mutationsPointer: NULL] autorelease];
}

- (OFEnumerator*)keyEnumerator
{
	return [[[OFDictionaryKeyEnumerator alloc]
	    initWithDictionary: self
			  data: data
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
	OFMutableDictionary *new = [OFMutableDictionary dictionary];
	size_t i;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED)
			[new setObject: block(data[i]->key, data[i]->object)
				forKey: data[i]->key];

	/*
	 * Class swizzle the dictionary to be immutable. We declared the return
	 * type to be OFDictionary*, so it can't be modified anyway. But not
	 * swizzling it would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFDictionary class];
	return new;
}

- (OFDictionary*)filteredDictionaryUsingBlock:
    (of_dictionary_filter_block_t)block
{
	OFMutableDictionary *new = [OFMutableDictionary dictionary];
	size_t i;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED)
			if (block(data[i]->key, data[i]->object))
				[new setObject: data[i]->object
					forKey: data[i]->key];

	/*
	 * Class swizzle the dictionary to be immutable. We declared the return
	 * type to be OFDictionary*, so it can't be modified anyway. But not
	 * swizzling it would create a real copy each time -[copy] is called.
	 */
	new->isa = [OFDictionary class];
	return new;
}
#endif

- (void)dealloc
{
	uint32_t i;

	for (i = 0; i < size; i++) {
		if (data[i] != NULL && data[i] != DELETED) {
			[data[i]->key release];
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
	OFMutableString *ret;
	OFAutoreleasePool *pool, *pool2;
	OFEnumerator *keyEnumerator;
	OFEnumerator *objectEnumerator;
	id key, object;
	size_t i;

	if (count == 0)
		return @"{}";

	ret = [OFMutableString stringWithString: @"{\n"];
	pool = [[OFAutoreleasePool alloc] init];
	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];

	i = 0;
	pool2 = [[OFAutoreleasePool alloc] init];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		[ret appendString: [key description]];
		[ret appendString: @" = "];
		[ret appendString: [object description]];

		if (++i < count)
			[ret appendString: @";\n"];

		[pool2 releaseObjects];
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendString: @";\n}"];

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
- initWithDictionary: (OFDictionary*)dictionary_
		data: (struct of_dictionary_bucket**)data_
		size: (uint32_t)size_
    mutationsPointer: (unsigned long*)mutationsPtr_
{
	self = [super init];

	dictionary = [dictionary_ retain];
	data = data_;
	size = size_;
	mutations = (mutationsPtr_ != NULL ? *mutationsPtr_ : 0);
	mutationsPtr = mutationsPtr_;

	return self;
}

- (void)dealloc
{
	[dictionary release];

	[super dealloc];
}

- (void)reset
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    newWithClass: isa
			  object: dictionary];

	pos = 0;
}
@end

@implementation OFDictionaryObjectEnumerator
- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    newWithClass: isa
			  object: dictionary];

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
		@throw [OFEnumerationMutationException
		    newWithClass: isa
			  object: dictionary];

	for (; pos < size && (data[pos] == NULL ||
	    data[pos] == DELETED); pos++);

	if (pos < size)
		return data[pos++]->key;
	else
		return nil;
}
@end
