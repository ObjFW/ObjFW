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
	uint32_t hash;
	of_list_object_t *iter, *key_obj;

	if (key == nil || obj == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

	hash = [key hash] & (size - 1);

	if (data[hash] == nil)
		data[hash] = [[OFList alloc] init];

	for (iter = [data[hash] first]; iter != NULL; iter = iter->next->next) {
		if ([iter->object isEqual: key]) {
			[iter->next->object release];
			[obj retain];
			iter->next->object = obj;

			return self;
		}
	}

	key = [key copy];
	@try {
		key_obj = [data[hash] append: key];
	} @finally {
		[key release];
	}

	@try {
		[data[hash] append: obj];
	} @catch (OFException *e) {
		[data[hash] remove: key_obj];
		@throw e;
	}

	return self;
}

- removeObjectForKey: (OFObject*)key
{
	uint32_t hash;
	of_list_object_t *iter;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						    andSelector: _cmd];

	hash = [key hash] & (size - 1);

	if (data[hash] == nil)
		return self;

	for (iter = [data[hash] first]; iter != NULL; iter = iter->next->next) {
		if ([iter->object isEqual: key]) {
			[data[hash] remove: iter->next];
			[data[hash] remove: iter];

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
	of_list_object_t *iter;

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

		for (iter = [data[i] first]; iter != NULL;
		    iter = iter->next->next) {
			uint32_t hash = [iter->object hash] & (newsize - 1);

			if (newdata[hash] == nil)
				newdata[hash] = [[OFList alloc] init];

			[newdata[hash] append: iter->object];
			[newdata[hash] append: iter->next->object];
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
