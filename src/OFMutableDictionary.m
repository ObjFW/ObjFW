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

#import "OFMutableDictionary.h"
#import "OFExceptions.h"
#import "macros.h"

#define BUCKET_SIZE sizeof(struct of_dictionary_bucket)
#define DELETED (id)&of_dictionary_deleted_bucket

@implementation OFMutableDictionary
- (void)_resizeForCount: (size_t)newcount
{
	size_t fill = newcount * 4 / size;
	size_t newsize;
	struct of_dictionary_bucket *newdata;
	uint32_t i;

	if (newcount > UINT32_MAX)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (fill >= 3)
		newsize = size << 1;
	else if (fill <= 1)
		newsize = size >> 1;
	else
		return;

	if (newsize == 0)
		@throw [OFOutOfRangeException newWithClass: isa];

	newdata = [self allocMemoryForNItems: newsize
				    withSize: BUCKET_SIZE];
	memset(newdata, 0, newsize * BUCKET_SIZE);

	for (i = 0; i < size; i++) {
		if (data[i].key != nil && data[i].key != DELETED) {
			uint32_t j, last;

			last = newsize;

			j = data[i].hash & (newsize - 1);
			for (; j < last && newdata[j].key != nil; j++);

			/* In case the last bucket is already used */
			if (j >= last) {
				last = data[i].hash & (newsize - 1);

				for (j = 0; j < last &&
				    newdata[j].key != nil; i++);
			}

			if (j >= last) {
				[self freeMemory: newdata];
				@throw [OFOutOfRangeException
				    newWithClass: [self class]];
			}

			newdata[j].key = data[i].key;
			newdata[j].object = data[i].object;
			newdata[j].hash = data[i].hash;
		}
	}

	[self freeMemory: data];
	data = newdata;
	size = newsize;
}

- setObject: (OFObject*)obj
     forKey: (OFObject <OFCopying>*)key
{
	uint32_t i, hash, last;

	if (key == nil || obj == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];
	last = size;

	for (i = hash & (size - 1); i < last && data[i].key != nil; i++) {
		if (data[i].key == DELETED)
			continue;

		if ([data[i].key isEqual: key])
			break;
	}

	/* In case the last bucket is already used */
	if (i >= last) {
		last = hash & (size - 1);

		for (i = 0; i < last && data[i].key != nil; i++) {
			if (data[i].key == DELETED)
				continue;

			if ([data[i].key isEqual: key])
				break;
		}
	}

	/* Key not in dictionary */
	if (i >= last || data[i].key == nil || data[i].key == DELETED ||
	    ![data[i].key isEqual: key]) {
		[self _resizeForCount: count + 1];

		mutations++;
		last = size;

		for (i = hash & (size - 1); i < last && data[i].key != nil &&
		    data[i].key != DELETED; i++);

		/* In case the last bucket is already used */
		if (i >= last) {
			last = hash & (size - 1);

			for (i = 0; i < last && data[i].key != nil &&
			    data[i].key != DELETED; i++);
		}

		if (i >= last)
			@throw [OFOutOfRangeException newWithClass: isa];

		key = [key copy];
		@try {
			[obj retain];
		} @catch (OFException *e) {
			[key release];
			@throw e;
		}

		data[i].key = key;
		data[i].object = obj;
		data[i].hash = hash;
		count++;

		return self;
	}

	[obj retain];
	[data[i].object release];
	data[i].object = obj;

	return self;
}

- removeObjectForKey: (OFObject*)key
{
	uint32_t i, hash, last;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];
	last = size;

	for (i = hash & (size - 1); i < last && data[i].key != nil; i++) {
		if (data[i].key == DELETED)
			continue;

		if ([data[i].key isEqual: key]) {
			[data[i].key release];
			[data[i].object release];
			data[i].key = DELETED;

			count--;
			mutations++;
			[self _resizeForCount: count];

			return self;
		}
	}

	if (i < last)
		return self;

	/* In case the last bucket is already used */
	last = hash & (size - 1);

	for (i = 0; i < last && data[i].key != nil; i++) {
		if (data[i].key == DELETED)
			continue;

		if ([data[i].key isEqual: key]) {
			[data[i].key release];
			[data[i].object release];
			data[i].key = DELETED;

			count--;
			mutations++;
			[self _resizeForCount: count];

			return self;
		}
	}

	return self;
}

- (id)copy
{
	return [[OFDictionary alloc] initWithDictionary: self];
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
	state->mutationsPtr = &mutations;

	return i;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFDictionaryObjectEnumerator alloc]
		initWithData: data
			size: size
	    mutationsPointer: &mutations] autorelease];
}

- (OFEnumerator*)keyEnumerator
{
	return [[[OFDictionaryKeyEnumerator alloc]
		initWithData: data
			size: size
	    mutationsPointer: &mutations] autorelease];
}
@end
