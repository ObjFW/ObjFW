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

	firstListObject = NULL;
	lastListObject = NULL;

	return self;
}

- (void)dealloc
{
	of_list_object_t *iter;

	for (iter = firstListObject; iter != NULL; iter = iter->next)
		[iter->object release];

	[super dealloc];
}

- (of_list_object_t*)firstListObject;
{
	return firstListObject;
}

- (of_list_object_t*)lastListObject;
{
	return lastListObject;
}

- (of_list_object_t*)appendObject: (OFObject*)obj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = NULL;
	o->prev = lastListObject;

	if (lastListObject != NULL)
		lastListObject->next = o;

	lastListObject = o;
	if (firstListObject == NULL)
		firstListObject = o;

	count++;

	[obj retain];

	return o;
}

- (of_list_object_t*)prependObject: (OFObject*)obj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = firstListObject;
	o->prev = NULL;

	if (firstListObject != NULL)
		firstListObject->prev = o;

	firstListObject = o;
	if (lastListObject == NULL)
		lastListObject = o;

	count++;

	[obj retain];

	return o;
}

- (of_list_object_t*)insertObject: (OFObject*)obj
		 beforeListObject: (of_list_object_t*)listobj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = listobj;
	o->prev = listobj->prev;

	if (listobj->prev != NULL)
		listobj->prev->next = o;

	listobj->prev = o;

	if (listobj == firstListObject)
		firstListObject = o;

	count++;

	[obj retain];

	return o;
}

- (of_list_object_t*)insertObject: (OFObject*)obj
		  afterListObject: (of_list_object_t*)listobj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: sizeof(of_list_object_t)];
	o->object = [obj retain];
	o->next = listobj->next;
	o->prev = listobj;

	if (listobj->next != NULL)
		listobj->next->prev = o;

	listobj->next = o;

	if (listobj == lastListObject)
		lastListObject = o;

	count++;

	[obj retain];

	return o;
}

- (void)removeListObject: (of_list_object_t*)listobj
{
	if (listobj->prev != NULL)
		listobj->prev->next = listobj->next;
	if (listobj->next != NULL)
		listobj->next->prev = listobj->prev;

	if (firstListObject == listobj)
		firstListObject = listobj->next;
	if (lastListObject == listobj)
		lastListObject = listobj->prev;

	count--;

	[listobj->object release];

	[self freeMemory: listobj];
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

	for (iter = firstListObject, iter2 = [(OFList*)obj firstListObject];
	    iter != NULL && iter2 != NULL;
	    iter = iter->next, iter2 = iter2->next)
		if (![iter->object isEqual: iter2->object])
			return NO;

	/* One is bigger than the other although we checked the count */
	assert(iter == NULL && iter2 == NULL);

	return YES;
}

- copy
{
	OFList *new = [[OFList alloc] init];
	of_list_object_t *iter, *o, *prev;

	o = NULL;
	prev = NULL;

	@try {
		for (iter = firstListObject; iter != NULL; iter = iter->next) {
			o = [new allocMemoryWithSize: sizeof(of_list_object_t)];
			o->object = [iter->object retain];
			o->next = NULL;
			o->prev = prev;

			if (new->firstListObject == NULL)
				new->firstListObject = o;
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

	new->lastListObject = o;

	return new;
}

- (uint32_t)hash
{
	of_list_object_t *iter;
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (iter = firstListObject; iter != NULL; iter = iter->next) {
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
