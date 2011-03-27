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

#include "assert.h"

#import "OFList.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"

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

- (of_list_object_t*)appendObject: (id)obj
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
	mutations++;

	[obj retain];

	return o;
}

- (of_list_object_t*)prependObject: (id)obj
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
	mutations++;

	[obj retain];

	return o;
}

- (of_list_object_t*)insertObject: (id)obj
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
	mutations++;

	[obj retain];

	return o;
}

- (of_list_object_t*)insertObject: (id)obj
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
	mutations++;

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
	mutations++;

	[listobj->object release];

	[self freeMemory: listobj];
}

- (size_t)count
{
	return count;
}

- (BOOL)isEqual: (id)obj
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

- (BOOL)containsObject: (id)obj
{
	of_list_object_t *iter;

	if (count == 0)
		return NO;

	for (iter = firstListObject; iter != NULL; iter = iter->next)
		if ([iter->object isEqual: obj])
			return YES;

	return NO;
}

- (BOOL)containsObjectIdenticalTo: (id)obj
{
	of_list_object_t *iter;

	if (count == 0)
		return NO;

	for (iter = firstListObject; iter != NULL; iter = iter->next)
		if (iter->object == obj)
			return YES;

	return NO;
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
	} @catch (id e) {
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

- (OFString*)description
{
	OFMutableString *ret = [OFMutableString stringWithString: @"["];
	OFAutoreleasePool *pool;
	of_list_object_t *iter;

	pool = [[OFAutoreleasePool alloc] init];

	for (iter = firstListObject; iter != NULL; iter = iter->next) {
		[ret appendString: [iter->object description]];

		if (iter->next != NULL)
			[ret appendString: @", "];

		[pool releaseObjects];
	}

	[ret appendString: @"]"];

	[pool release];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	of_list_object_t **list_obj = (of_list_object_t**)state->extra;

	state->itemsPtr = objects;
	state->mutationsPtr = &mutations;

	if (state->state == 0) {
		*list_obj = firstListObject;
		state->state = 1;
	}

	if (*list_obj == NULL)
		return 0;

	objects[0] = (*list_obj)->object;
	*list_obj = (*list_obj)->next;
	return 1;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFListEnumerator alloc]
	        initWithList: self
	    mutationsPointer: &mutations] autorelease];
}
@end

@implementation OFListEnumerator
-     initWithList: (OFList*)list_
  mutationsPointer: (unsigned long*)mutationsPtr_;
{
	self = [super init];

	list = [list_ retain];
	current = [list firstListObject];
	mutations = *mutationsPtr_;
	mutationsPtr = mutationsPtr_;

	return self;
}

- (void)dealloc
{
	[list release];

	[super dealloc];
}

- (id)nextObject
{
	id ret;

	if (*mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa
							     object: list];

	if (current == NULL)
		return nil;

	ret = current->object;
	current = current->next;

	return ret;
}

- (void)reset
{
	if (*mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	current = [list firstListObject];
}
@end
