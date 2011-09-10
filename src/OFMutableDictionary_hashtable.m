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

#import "OFMutableDictionary_hashtable.h"
#import "OFDictionary_hashtable.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

#define DELETED &of_dictionary_hashtable_deleted_bucket

static Class dictionary = Nil;

@implementation OFMutableDictionary_hashtable
+ (void)initialize
{
	if (self == [OFMutableDictionary_hashtable class]) {
		dictionary = [OFDictionary_hashtable class];
		[self inheritMethodsFromClass: dictionary];
	}
}

- (void)_resizeForCount: (size_t)newCount
{
	size_t fullness = newCount * 4 / size;
	struct of_dictionary_hashtable_bucket **newData;
	uint32_t i, newSize;

	if (newCount > UINT32_MAX)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (fullness >= 3)
		newSize = size << 1;
	else if (fullness <= 1)
		newSize = size >> 1;
	else
		return;

	if (newSize == 0)
		@throw [OFOutOfRangeException newWithClass: isa];

	newData = [self allocMemoryForNItems: newSize
				    withSize: sizeof(*newData)];

	for (i = 0; i < newSize; i++)
		newData[i] = NULL;

	for (i = 0; i < size; i++) {
		if (data[i] != NULL && data[i] != DELETED) {
			uint32_t j, last;

			last = newSize;

			j = data[i]->hash & (newSize - 1);
			for (; j < last && newData[j] != NULL; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = data[i]->hash & (newSize - 1);

				for (j = 0; j < last &&
				    newData[j] != NULL; j++);
			}

			if (j >= last) {
				[self freeMemory: newData];
				@throw [OFOutOfRangeException
				    newWithClass: isa];
			}

			newData[j] = data[i];
		}
	}

	[self freeMemory: data];
	data = newData;
	size = newSize;
}

- (void)_setObject: (id)object
	    forKey: (id)key
	   copyKey: (BOOL)copyKey
{
	uint32_t i, hash, last;
	id old;

	if (key == nil || object == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];
	last = size;

	for (i = hash & (size - 1); i < last && data[i] != NULL; i++) {
		if (data[i] == DELETED)
			continue;

		if ([data[i]->key isEqual: key])
			break;
	}

	/* In case the last bucket is already used */
	if (i >= last) {
		last = hash & (size - 1);

		for (i = 0; i < last && data[i] != NULL; i++) {
			if (data[i] == DELETED)
				continue;

			if ([data[i]->key isEqual: key])
				break;
		}
	}

	/* Key not in dictionary */
	if (i >= last || data[i] == NULL || data[i] == DELETED ||
	    ![data[i]->key isEqual: key]) {
		struct of_dictionary_hashtable_bucket *bucket;

		[self _resizeForCount: count + 1];

		mutations++;
		last = size;

		for (i = hash & (size - 1); i < last && data[i] != NULL &&
		    data[i] != DELETED; i++);

		/* In case the last bucket is already used */
		if (i >= last) {
			last = hash & (size - 1);

			for (i = 0; i < last && data[i] != NULL &&
			    data[i] != DELETED; i++);
		}

		if (i >= last)
			@throw [OFOutOfRangeException newWithClass: isa];

		bucket = [self allocMemoryWithSize: sizeof(*bucket)];

		if (copyKey) {
			@try {
				bucket->key = [key copy];
			} @catch (id e) {
				[self freeMemory: bucket];
				@throw e;
			}
		} else
			bucket->key = [key retain];

		bucket->object = [object retain];
		bucket->hash = hash;

		data[i] = bucket;
		count++;

		return;
	}

	old = data[i]->object;
	data[i]->object = [object retain];
	[old release];
}

- (void)setObject: (id)object
	   forKey: (id)key
{
	[self _setObject: object
		  forKey: key
		 copyKey: YES];
}

- (void)removeObjectForKey: (id)key
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

		if ([data[i]->key isEqual: key]) {
			[data[i]->key release];
			[data[i]->object release];
			[self freeMemory: data[i]];
			data[i] = DELETED;

			count--;
			mutations++;
			[self _resizeForCount: count];

			return;
		}
	}

	if (i < last)
		return;

	/* In case the last bucket is already used */
	last = hash & (size - 1);

	for (i = 0; i < last && data[i] != NULL; i++) {
		if (data[i] == DELETED)
			continue;

		if ([data[i]->key isEqual: key]) {
			[data[i]->key release];
			[data[i]->object release];
			[self freeMemory: data[i]];
			data[i] = DELETED;

			count--;
			mutations++;
			[self _resizeForCount: count];

			return;
		}
	}
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	const SEL selector =
	    @selector(countByEnumeratingWithState:objects:count:);
	int (*imp)(id, SEL, of_fast_enumeration_state_t*, id*, int) =
	    (int(*)(id, SEL, of_fast_enumeration_state_t*, id*, int))
	    [dictionary instanceMethodForSelector: selector];

	int ret = imp(self, selector, state, objects, count_);

	state->mutationsPtr = &mutations;

	return ret;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFDictionaryObjectEnumerator_hashtable alloc]
	    initWithDictionary: (OFDictionary_hashtable*)self
			  data: data
			  size: size
	      mutationsPointer: &mutations] autorelease];
}

- (OFEnumerator*)keyEnumerator
{
	return [[[OFDictionaryKeyEnumerator_hashtable alloc]
	    initWithDictionary: (OFDictionary_hashtable*)self
			  data: data
			  size: size
	      mutationsPointer: &mutations] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_dictionary_enumeration_block_t)block
{
	size_t i;
	BOOL stop = NO;
	unsigned long mutations2 = mutations;

	for (i = 0; i < size && !stop; i++) {
		if (mutations != mutations2)
			@throw [OFEnumerationMutationException
			    newWithClass: isa
				  object: self];

		if (data[i] != NULL && data[i] != DELETED)
			block(data[i]->key, data[i]->object, &stop);
	}
}

- (void)replaceObjectsUsingBlock: (of_dictionary_replace_block_t)block
{
	size_t i;
	BOOL stop = NO;
	unsigned long mutations2 = mutations;

	for (i = 0; i < size && !stop; i++) {
		if (mutations != mutations2)
			@throw [OFEnumerationMutationException
			    newWithClass: isa
				  object: self];

		if (data[i] != NULL && data[i] != DELETED) {
			id new = block(data[i]->key, data[i]->object, &stop);

			if (new == nil)
				@throw [OFInvalidArgumentException
				    newWithClass: isa
					selector: _cmd];

			[new retain];
			[data[i]->object release];
			data[i]->object = new;
		}
	}
}
#endif

- (void)makeImmutable
{
	isa = [OFDictionary_hashtable class];
}
@end
