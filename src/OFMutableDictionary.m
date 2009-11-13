/*
 * Copyright (c) 2008 - 2009
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
	float fill = (float)count / *size;
	size_t newsize;
	struct of_dictionary_bucket *newdata;
	uint32_t i;

	if (fill > 0.75) {
		if (*size > SIZE_MAX / 2)
			@throw [OFOutOfRangeException newWithClass: isa];

		newsize = *size * 2;
	} else if (fill < 0.25)
		newsize = *size / 2;
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
	if (i >= size || data[i].key == nil) {
		resize(self, isa, count + 1, &data, &size);

		i = hash & (size - 1);
		for (; i < size && data[i].key != nil; i++);

		/* In case the last bucket is already used */
		if (i >= size)
			for (i = 0; i < size && data[i].key != nil; i++);
		if (i >= size)
			@throw [OFOutOfRangeException newWithClass: isa];

		data[i].key = [key copy];
		data[i].object = [obj retain];
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

	/* In case the last bucket is already used */
	if (i >= size)
		for (i = 0; i < size && data[i].key != nil &&
		    ![data[i].key isEqual: key]; i++);

	/* Key not in dictionary */
	if (i >= size || data[i].key == nil)
		return self;

	[data[i].key release];
	[data[i].object release];
	data[i].key = nil;

	count--;
	resize(self, isa, count, &data, &size);

	return self;
}

- (id)copy
{
	return [[OFDictionary alloc] initWithDictionary: self];
}
@end
