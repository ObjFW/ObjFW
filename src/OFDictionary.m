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

#import "config.h"

#include <string.h>

#import "OFDictionary.h"
#import "OFExceptions.h"

@implementation OFDictionary
+ dictionary;
{
	return [[[OFDictionary alloc] init] autorelease];
}

+ dictionaryWithHashSize: (int)hashsize
{
	return [[[OFDictionary alloc] initWithHashSize: hashsize] autorelease];
}

- init
{
	if ((self = [super init])) {
		size = 4096;

		@try {
			data = [self getMemForNItems: size
					      ofSize: sizeof(OFList*)];
		} @catch (OFException *e) {
			[self free];
			@throw e;
		}
		memset(data, 0, size);
	}

	return self;
}

- initWithHashSize: (int)hashsize
{
	if ((self = [super init])) {
		if (hashsize < 8 || hashsize > 31) {
			Class c = isa;
			[self free];
			@throw [OFInvalidArgumentException
			    newWithClass: c
			     andSelector: _cmd];
		}

		size = (size_t)1 << hashsize;

		@try {
			data = [self getMemForNItems: size
					      ofSize: sizeof(OFList*)];
		} @catch (OFException *e) {
			[self free];
			@throw e;
		}
		memset(data, 0, size);
	}

	return self;
}

- free
{
	size_t i;

	for (i = 0; i < size; i++)
		if (data[i] != nil)
			[data[i] release];

	return [super free];
}

- set: (OFObject*)key
   to: (OFObject*)obj
{
	uint32_t hash = [key hash] & (size - 1);
	of_list_object_t *iter;

	if (data[hash] == nil)
		data[hash] = [OFList new];

	if (data[hash] == nil)
		@throw [OFInitializationFailedException
		    newWithClass: [OFList class]];

	for (iter = [data[hash] first]; iter != NULL; iter = iter->next->next) {
		if ([iter->object isEqual: key]) {
			[iter->next->object release];
			[obj retain];
			iter->next->object = obj;

			return self;
		}
	}

	[data[hash] append: key];
	[data[hash] append: obj];

	return self;
}

- get: (OFObject*)key
{
	uint32_t hash = [key hash] & (size - 1);
	of_list_object_t *iter;

	if (data[hash] == nil)
		return nil;

	for (iter = [data[hash] first]; iter != NULL; iter = iter->next->next)
		if ([iter->object isEqual: key])
			return iter->next->object;

	return nil;
}

- remove: (OFObject*)key
{
	uint32_t hash = [key hash] & (size - 1);
	of_list_object_t *iter;

	if (data[hash] == nil)
		return self; // FIXME: Throw exception?

	for (iter = [data[hash] first]; iter != NULL; iter = iter->next->next) {
		if ([iter->object isEqual: key]) {
			[data[hash] remove: iter->next];
			[data[hash] remove: iter];

			return self;
		}
	}

	return self;  // FIXME: Throw exception?
}

/* FIXME: Implement this! */
/*
- (BOOL)isEqual
{
}
*/
@end
