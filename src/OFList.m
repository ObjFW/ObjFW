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
	    initWithFirstListObject: firstListObject
		   mutationsPointer: &mutations] autorelease];
}
@end

/// \cond internal
@implementation OFListEnumerator
- initWithFirstListObject: (of_list_object_t*)first_
	 mutationsPointer: (unsigned long*)mutationsPtr_;
{
	self = [super init];

	first = first_;
	current = first_;
	mutations = *mutationsPtr_;
	mutationsPtr = mutationsPtr_;

	return self;
}

- (id)nextObject
{
	id ret;

	if (*mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

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

	current = first;
}
@end
/// \endcond
