/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <string.h>

#import "OFMutableDictionary.h"
#import "OFExceptions.h"
#import "OFMacros.h"

@implementation OFMutableDictionary
- setObject: (OFObject*)obj
     forKey: (OFObject <OFCopying>*)key
{
	uint32_t fullhash, hash;
	of_dictionary_list_object_t *iter;

	if (key == nil || obj == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

	fullhash = [key hash];
	hash = fullhash & (size - 1);

	if (data[hash] == nil)
		data[hash] = [[OFList alloc] initWithListObjectSize:
		    sizeof(of_dictionary_list_object_t)];

	for (iter = (of_dictionary_list_object_t*)[data[hash] first];
	    iter != NULL; iter = iter->next) {
		if ([iter->key isEqual: key]) {
			[iter->object release];
			iter->object = [obj retain];

			return self;
		}
	}

	key = [key copy];

	@try {
		of_dictionary_list_object_t *o;

		o = (of_dictionary_list_object_t*)[data[hash] append: obj];
		o->key = key;
		o->hash = fullhash;
	} @catch (OFException *e) {
		[key release];
		@throw e;
	}

	return self;
}

- removeObjectForKey: (OFObject*)key
{
	uint32_t hash;
	of_dictionary_list_object_t *iter;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

	hash = [key hash] & (size - 1);

	if (data[hash] == nil)
		return self;

	for (iter = (of_dictionary_list_object_t*)[data[hash] first];
	    iter != NULL; iter = iter->next) {
		if ([iter->object isEqual: key]) {
			[iter->key release];
			[data[hash] remove: (of_list_object_t*)iter];

			if ([data[hash] first] == NULL) {
				[data[hash] release];
				data[hash] = nil;
			}

			return self;
		}
	}

	return self;
}

- changeHashSize: (int)hashsize
{
	OFList **newdata;
	size_t newsize, i;
	of_dictionary_list_object_t *iter;

	if (hashsize < 8 || hashsize >= 28)
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

	newsize = (size_t)1 << hashsize;
	newdata = [self allocMemoryForNItems: newsize
				    withSize: sizeof(OFList*)];
	memset(newdata, 0, newsize * sizeof(OFList*));

	for (i = 0; i < size; i++) {
		if (OF_LIKELY(data[i] == nil))
			continue;

		for (iter = (of_dictionary_list_object_t*)[data[i] first];
		    iter != NULL; iter = iter->next) {
			uint32_t hash = iter->hash & (newsize - 1);
			of_dictionary_list_object_t *o;

			if (newdata[hash] == nil)
				newdata[hash] = [[OFList alloc]
				    initWithListObjectSize:
				    sizeof(of_dictionary_list_object_t)];

			o = (of_dictionary_list_object_t*)
			    [newdata[hash] append: iter->object];
			o->key = iter->key;
			o->hash = iter->hash;
		}

		[data[i] release];
	}

	[self freeMemory: data];
	data = newdata;
	size = newsize;

	return self;
}

/* FIXME: Implement this! */
/*
- (id)copy
{
}

- (id)mutableCopy
{
}
*/
@end
