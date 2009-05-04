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
#import "OFIterator.h"
#import "OFExceptions.h"

/* Reference for static linking */
void _reference_to_OFIterator_in_OFDictionary() { [OFIterator class]; }

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
	self = [super init];

	size = 4096;

	@try {
		data = [self allocNItems: size
				withSize: sizeof(OFList*)];
	} @catch (OFException *e) {
		/*
		 * We can't use [super free] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self free] works.
		 */
		size = 0;
		[self free];
		@throw e;
	}
	memset(data, 0, size * sizeof(OFList*));

	return self;
}

- initWithHashSize: (int)hashsize
{
	self = [super init];

	if (hashsize < 8 || hashsize > 31) {
		Class c = isa;
		[super free];
		@throw [OFInvalidArgumentException
			newWithClass: c
			 andSelector: _cmd];
	}

	size = (size_t)1 << hashsize;

	@try {
		data = [self allocNItems: size
				withSize: sizeof(OFList*)];
	} @catch (OFException *e) {
		/*
		 * We can't use [super free] on OS X here. Compiler bug?
		 * Anyway, set size to 0 so that [self free] works.
		 */
		size = 0;
		[self free];
		@throw e;
	}
	memset(data, 0, size * sizeof(OFList*));

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
	uint32_t hash;
	of_list_object_t *iter;

	if (key == nil || obj == nil)
		@throw [OFInvalidArgumentException newWithClass: isa];

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

	[data[hash] append: key];
	[data[hash] append: obj];

	return self;
}

- get: (OFObject*)key
{
	uint32_t hash;
	of_list_object_t *iter;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa];

	hash = [key hash] & (size - 1);

	if (data[hash] == nil)
		@throw [OFNotInSetException newWithClass: isa];

	for (iter = [data[hash] first]; iter != NULL; iter = iter->next->next)
		if ([iter->object isEqual: key])
			return iter->next->object;

	@throw [OFNotInSetException newWithClass: isa];
}

- remove: (OFObject*)key
{
	uint32_t hash;
	of_list_object_t *iter;

	if (key == nil)
		@throw [OFInvalidArgumentException newWithClass: isa];

	hash = [key hash] & (size - 1);

	if (data[hash] == nil)
		@throw [OFNotInSetException newWithClass: isa];

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

	@throw [OFNotInSetException newWithClass: isa];
}

/* FIXME: Implement this! */
/*
- (BOOL)isEqual
{
}
*/
@end
