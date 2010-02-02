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

#include "assert.h"

#import "OFList.h"
#import "OFExceptions.h"
#import "macros.h"

@implementation OFList
+ list
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	first = NULL;
	last = NULL;

	return self;
}

- (void)dealloc
{
	of_list_object_t *iter;

	for (iter = first; iter != NULL; iter = iter->next)
		[iter->object release];

	[super dealloc];
}

- (of_list_object_t*)first
{
	return first;
}

- (of_list_object_t*)last
{
	return last;
}

- (of_list_object_t*)append: (OFObject*)obj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = NULL;
	o->prev = last;

	if (last != NULL)
		last->next = o;

	last = o;
	if (first == NULL)
		first = o;

	count++;

	[obj retain];

	return o;
}

- (of_list_object_t*)prepend: (OFObject*)obj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = first;
	o->prev = NULL;

	if (first != NULL)
		first->prev = o;

	first = o;
	if (last == NULL)
		last = o;

	count++;

	[obj retain];

	return o;
}

- (of_list_object_t*)insert: (OFObject*)obj
		     before: (of_list_object_t*)listobj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = listobj;
	o->prev = listobj->prev;

	if (listobj->prev != NULL)
		listobj->prev->next = o;

	listobj->prev = o;

	if (listobj == first)
		first = o;

	count++;

	[obj retain];

	return o;
}

- (of_list_object_t*)insert: (OFObject*)obj
		      after: (of_list_object_t*)listobj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = listobj->next;
	o->prev = listobj;

	if (listobj->next != NULL)
		listobj->next->prev = o;

	listobj->next = o;

	if (listobj == last)
		last = o;

	count++;

	[obj retain];

	return o;
}

- remove: (of_list_object_t*)listobj
{
	if (listobj->prev != NULL)
		listobj->prev->next = listobj->next;
	if (listobj->next != NULL)
		listobj->next->prev = listobj->prev;

	if (first == listobj)
		first = listobj->next;
	if (last == listobj)
		last = listobj->prev;

	count--;

	[listobj->object release];

	[self freeMemory: listobj];

	return self;
}

- (size_t)count
{
	return count;
}

- (BOOL)isEqual: (OFObject*)obj
{
	of_list_object_t *iter, *iter2;

	if (![obj isKindOfClass: [OFList class]])
		return NO;

	if ([(OFList*)obj count] != count)
		return NO;

	for (iter = first, iter2 = [(OFList*)obj first]; iter != NULL &&
	    iter2 != NULL; iter = iter->next, iter2 = iter2->next)
		if (![iter->object isEqual: iter2->object])
			return NO;

	/* One is bigger than the other although we checked the count */
	assert(iter == NULL && iter2 == NULL);

	return YES;
}

- (id)copy
{
	OFList *new = [[OFList alloc] init];
	of_list_object_t *iter, *o, *prev;

	o = NULL;
	prev = NULL;

	@try {
		for (iter = first; iter != NULL; iter = iter->next) {
			o = [new allocMemoryWithSize: sizeof(of_list_object_t)];
			o->object = [iter->object retain];
			o->next = NULL;
			o->prev = prev;

			if (new->first == NULL)
				new->first = o;
			if (prev != NULL)
				prev->next = o;

			new->count++;

			[o->object retain];

			prev = o;
		}
	} @catch (OFException *e) {
		[new release];
		@throw e;
	}

	new->last = o;

	return new;
}

- (uint32_t)hash
{
	of_list_object_t *iter;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (iter = first; iter != NULL; iter = iter->next) {
		uint32_t h = [iter->object hash];

		OF_HASH_ADD(hash, h >> 24);
		OF_HASH_ADD(hash, (h >> 16) & 0xFF);
		OF_HASH_ADD(hash, (h >> 8) & 0xFF);
		OF_HASH_ADD(hash, h & 0xFF);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end
