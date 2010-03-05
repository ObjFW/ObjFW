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
#import "OFMacros.h"

#define BUCKET_SIZE sizeof(struct of_dictionary_bucket)

static OF_INLINE void
resize(id self, Class isa, size_t count, struct of_dictionary_bucket **data,
    size_t *size)
{
	size_t fill = count * 4 / *size;
	size_t newsize;
	struct of_dictionary_bucket *newdata;
	uint32_t i;

	if (fill > 3) {
		if (*size > SIZE_MAX / 8)
			@throw [OFOutOfRangeException newWithClass: isa];

		newsize = *size << 1;
	} else if (fill < 1)
		newsize = *size >> 1;
	else
		return;

	newdata = [self allocMemoryForNItems: newsize
				    withSize: BUCKET_SIZE];
	memset(newdata, 0, newsize * BUCKET_SIZE);

	for (i = 0; i < *size; i++) {
		if ((*data)[i].key != nil) {
			uint32_t j = (*data)[i].hash & (newsize - 1);
			for (; j < newsize && newdata[j].key != nil; j++);

			/* In case the last bucket is already used */
			if (j >= newsize)
				for (j = 0; j < newsize &&
				    newdata[j].key != nil; i++);
			if (j >= newsize)
				@throw [OFOutOfRangeException
				    newWithClass: [self class]];

			newdata[j].key = (*data)[i].key;
			newdata[j].object = (*data)[i].object;
			newdata[j].hash = (*data)[i].hash;
		}
	}

	[self freeMemory: *data];
	*data = newdata;
	*size = newsize;
}

@implementation OFMutableDictionary
- setObject: (OFObject*)obj
     forKey: (OFObject <OFCopying>*)key
{
	uint32_t i, hash;

	if (key == nil || obj == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];

	for (i = hash & (size - 1); i < size && data[i].key != nil &&
	    ![data[i].key isEqual: key]; i++);

	/* In case the last bucket is already used */
	if (i >= size)
		for (i = 0; i < size && data[i].key != nil &&
		    ![data[i].key isEqual: key]; i++);

	/* Key not in dictionary */
	if (i >= size || ![data[i].key isEqual: key]) {
		resize(self, isa, count + 1, &data, &size);

		mutations++;

		i = hash & (size - 1);
		for (; i < size && data[i].key != nil; i++);

		/* In case the last bucket is already used */
		if (i >= size)
			for (i = 0; i < size && data[i].key != nil; i++);
		if (i >= size)
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
	uint32_t i, hash;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	hash = [key hash];

	for (i = hash & (size - 1); i < size && data[i].key != nil &&
	    ![data[i].key isEqual: key]; i++);

	if (i < size && data[i].key == nil)
		return self;

	/* In case the last bucket is already used */
	if (i >= size)
		for (i = 0; i < size && data[i].key != nil &&
		    ![data[i].key isEqual: key]; i++);

	/* Key not in dictionary */
	if (i >= size || ![data[i].key isEqual: key])
		return self;

	[data[i].key release];
	[data[i].object release];
	data[i].key = nil;

	count--;
	mutations++;
	resize(self, isa, count, &data, &size);

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
	size_t i;

	for (i = 0; i < count_; i++) {
		for (; state->state < size && data[state->state].key == nil;
		    state->state++);

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
