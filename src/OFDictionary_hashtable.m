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

#include <string.h>

#include <assert.h>

#import "OFDictionary_hashtable.h"
#import "OFMutableDictionary_hashtable.h"
#import "OFEnumerator.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

struct of_dictionary_hashtable_bucket
    of_dictionary_hashtable_deleted_bucket = {};
#define DELETED &of_dictionary_hashtable_deleted_bucket

@implementation OFDictionary_hashtable
- init
{
	self = [super init];

	@try {
		data = [self allocMemoryWithSize: sizeof(*data)];
		size = 1;
		data[0] = NULL;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- _initWithDictionary: (OFDictionary*)dictionary
	     copyKeys: (BOOL)copyKeys
{
	self = [super init];

	@try {
		uint32_t i;
		OFDictionary_hashtable *hashtable;

		if (dictionary == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		if (![dictionary isKindOfClass:
		    [OFDictionary_hashtable class]] &&
		    ![dictionary isKindOfClass:
		    [OFMutableDictionary_hashtable class]])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		hashtable = (OFDictionary_hashtable*)dictionary;

		data = [self allocMemoryForNItems: hashtable->size
					   ofSize: sizeof(*data)];

		for (i = 0; i < hashtable->size; i++)
			data[i] = NULL;

		size = hashtable->size;
		count = hashtable->count;

		for (i = 0; i < size; i++) {
			struct of_dictionary_hashtable_bucket *bucket;

			if (hashtable->data[i] == NULL ||
			    hashtable->data[i] == DELETED)
				continue;

			bucket = [self allocMemoryWithSize: sizeof(*bucket)];
			bucket->key = (copyKeys
			    ? [hashtable->data[i]->key copy]
			    : [hashtable->data[i]->key retain]);
			bucket->object = [hashtable->data[i]->object retain];
			bucket->hash = hashtable->data[i]->hash;

			data[i] = bucket;
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithDictionary: (OFDictionary*)dictionary
{
	if ([dictionary class] == [OFDictionary_hashtable class] ||
	    [dictionary class] == [OFMutableDictionary_hashtable class])
		return [self _initWithDictionary: dictionary
					copyKeys: YES];

	self = [super init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFEnumerator *enumerator;
		id key;
		uint32_t i, newSize;

		count = [dictionary count];

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		for (newSize = 1; newSize < count; newSize <<= 1);
		if (count * 4 / newSize >= 3)
			newSize <<= 1;

		if (newSize == 0)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		data = [self allocMemoryForNItems: newSize
					   ofSize: sizeof(*data)];

		for (i = 0; i < newSize; i++)
			data[i] = NULL;

		size = newSize;

		pool = [[OFAutoreleasePool alloc] init];
		enumerator = [dictionary keyEnumerator];

		while ((key = [enumerator nextObject]) != nil) {
			uint32_t hash, last;
			struct of_dictionary_hashtable_bucket *bucket;
			id object;

			hash = [key hash];
			last = size;

			for (i = hash & (size - 1); i < last && data[i] != NULL;
			    i++);

			/* In case the last bucket is already used */
			if (i >= last) {
				last = hash & (size - 1);

				for (i = 0; i < last && data[i] != NULL; i++);
			}

			if (data[i] != NULL)
				@throw [OFOutOfRangeException
				    exceptionWithClass: isa];

			bucket = [self allocMemoryWithSize: sizeof(*bucket)];

			object = [dictionary objectForKey: key];

			bucket->key = [key copy];
			bucket->object = [object retain];
			bucket->hash = hash;

			data[i] = bucket;
		}

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)object
	  forKey: (id)key
{
	self = [super init];

	@try {
		uint32_t i;
		struct of_dictionary_hashtable_bucket *bucket;

		if (key == nil || object == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		data = [self allocMemoryForNItems: 2
					   ofSize: sizeof(*data)];

		size = 2;
		for (i = 0; i < size; i++)
			data[i] = NULL;

		i = [key hash] & 1;

		bucket = [self allocMemoryWithSize: sizeof(*bucket)];
		bucket->key = [key copy];
		bucket->object = [object retain];
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

		keysCArray = [keys objects];
		objectsCArray = [objects objects];
		count = [keys count];

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		for (newSize = 1; newSize < count; newSize <<= 1);
		if (count * 4 / newSize >= 3)
			newSize <<= 1;

		if (newSize == 0)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		data = [self allocMemoryForNItems: newSize
					   ofSize: sizeof(*data)];

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
				struct of_dictionary_hashtable_bucket *bucket;
				id key;

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
					    exceptionWithClass: isa];

				bucket =
				    [self allocMemoryWithSize: sizeof(*bucket)];
				key = [keysCArray[i] copy];

				bucket->key = key;
				bucket->object = [objectsCArray[i] retain];
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
			[data[j]->object release];
			data[j]->object = objectsCArray[i];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithKey: (id)firstKey
    arguments: (va_list)arguments
{
	self = [super init];

	@try {
		id key, object;
		uint32_t i, j, hash, newSize;
		va_list argumentsCopy;
		struct of_dictionary_hashtable_bucket *bucket;

		va_copy(argumentsCopy, arguments);

		if (firstKey == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		key = firstKey;

		if ((object = va_arg(arguments, id)) == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		count = 1;
		for (; va_arg(argumentsCopy, id) != nil; count++);
		count >>= 1;

		if (count > UINT32_MAX)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		for (newSize = 1; newSize < count; newSize <<= 1);
		if (count * 4 / newSize >= 3)
			newSize <<= 1;

		if (newSize == 0)
			@throw [OFOutOfRangeException exceptionWithClass: isa];

		data = [self allocMemoryForNItems: newSize
					   ofSize: sizeof(*data)];

		for (j = 0; j < newSize; j++)
			data[j] = NULL;

		size = newSize;

		/* Add first key / object pair */
		hash = [key hash];
		j = hash & (size - 1);

		bucket = [self allocMemoryWithSize: sizeof(*bucket)];
		bucket->key = [key copy];
		bucket->object = [object retain];
		bucket->hash = hash;

		data[j] = bucket;

		for (i = 1; i < count; i++) {
			uint32_t last;

			key = va_arg(arguments, id);
			object = va_arg(arguments, id);

			if (key == nil || object == nil)
				@throw [OFInvalidArgumentException
				    exceptionWithClass: isa
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
					    exceptionWithClass: isa];

				bucket =
				    [self allocMemoryWithSize: sizeof(*bucket)];
				bucket->key = [key copy];
				bucket->object = [object retain];
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
			[data[j]->object release];
			data[j]->object = object;
			count--;
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFAutoreleasePool *pool2;
		OFMutableDictionary *dictionary;
		OFArray *keys, *objects;
		OFEnumerator *keyEnumerator, *objectEnumerator;
		OFXMLElement *keyElement, *objectElement;

		if ((![[element name] isEqual: @"OFDictionary"] &&
		    ![[element name] isEqual: @"OFMutableDictionary"]) ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		dictionary = [OFMutableDictionary dictionary];

		keys = [element elementsForName: @"key"
				      namespace: OF_SERIALIZATION_NS];
		objects = [element elementsForName: @"object"
					 namespace: OF_SERIALIZATION_NS];

		if ([keys count] != [objects count])
			@throw [OFInvalidFormatException
			    exceptionWithClass: isa];

		keyEnumerator = [keys objectEnumerator];
		objectEnumerator = [objects objectEnumerator];
		pool2 = [[OFAutoreleasePool alloc] init];

		while ((keyElement = [keyEnumerator nextObject]) != nil &&
		    (objectElement = [objectEnumerator nextObject]) != nil) {
			OFXMLElement *key, *object;

			key = [[keyElement elementsForNamespace:
			    OF_SERIALIZATION_NS] firstObject];
			object = [[objectElement elementsForNamespace:
			    OF_SERIALIZATION_NS] firstObject];

			if (key == nil || object == nil)
				@throw [OFInvalidFormatException
				    exceptionWithClass: isa];

			[dictionary setObject: [object objectByDeserializing]
				       forKey: [key objectByDeserializing]];

			[pool2 releaseObjects];
		}

		self = [self initWithDictionary: dictionary];

		[pool release];
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
		@throw [OFInvalidArgumentException exceptionWithClass: isa
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

- (BOOL)isEqual: (id)dictionary
{
	uint32_t i;

	if ([self class] != [OFDictionary_hashtable class] &&
	    [self class] != [OFMutableDictionary_hashtable class])
		return [super isEqual: dictionary];

	if ([dictionary count] != count)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED &&
		    ![[dictionary objectForKey: data[i]->key]
		    isEqual: data[i]->object])
			return NO;

	return YES;
}

- (BOOL)containsObject: (id)object
{
	uint32_t i;

	if (count == 0)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED &&
		    [data[i]->object isEqual: object])
			return YES;

	return NO;
}

- (BOOL)containsObjectIdenticalTo: (id)object
{
	uint32_t i;

	if (count == 0)
		return NO;

	for (i = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED &&
		    data[i]->object == object)
			return YES;

	return NO;
}

- (OFArray*)allKeys
{
	OFArray *ret;
	id *keys = [self allocMemoryForNItems: count
				       ofSize: sizeof(id)];
	size_t i, j;

	for (i = j = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED)
			keys[j++] = data[i]->key;

	assert(j == count);

	@try {
		ret = [OFArray arrayWithObjects: keys
					  count: count];
	} @finally {
		[self freeMemory: keys];
	}

	return ret;
}

- (OFArray*)allObjects
{
	OFArray *ret;
	id *objects = [self allocMemoryForNItems: count
					  ofSize: sizeof(id)];
	size_t i, j;

	for (i = j = 0; i < size; i++)
		if (data[i] != NULL && data[i] != DELETED)
			objects[j++] = data[i]->object;

	assert(j == count);

	@try {
		ret = [OFArray arrayWithObjects: objects
					  count: count];
	} @finally {
		[self freeMemory: objects];
	}

	return ret;
}

- (OFEnumerator*)keyEnumerator
{
	return [[[OFDictionaryKeyEnumerator_hashtable alloc]
	    initWithDictionary: self
			  data: data
			  size: size
	      mutationsPointer: NULL] autorelease];
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFDictionaryObjectEnumerator_hashtable alloc]
	    initWithDictionary: self
			  data: data
			  size: size
	      mutationsPointer: NULL] autorelease];
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
			[data[i]->key release];
			[data[i]->object release];
		}
	}

	[super dealloc];
}

- (uint32_t)hash
{
	uint32_t i, hash = 0;

	for (i = 0; i < size; i++) {
		if (data[i] != NULL && data[i] != DELETED) {
			hash += data[i]->hash;
			hash += [data[i]->object hash];
		}
	}

	return hash;
}
@end

@implementation OFDictionaryEnumerator_hashtable
- initWithDictionary: (OFDictionary_hashtable*)dictionary_
		data: (struct of_dictionary_hashtable_bucket**)data_
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
		    exceptionWithClass: isa
				object: dictionary];

	pos = 0;
}
@end

@implementation OFDictionaryObjectEnumerator_hashtable
- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: isa
				object: dictionary];

	for (; pos < size && (data[pos] == NULL ||
	    data[pos] == DELETED); pos++);

	if (pos < size)
		return data[pos++]->object;
	else
		return nil;
}
@end

@implementation OFDictionaryKeyEnumerator_hashtable
- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: isa
				object: dictionary];

	for (; pos < size && (data[pos] == NULL ||
	    data[pos] == DELETED); pos++);

	if (pos < size)
		return data[pos++]->key;
	else
		return nil;
}
@end
