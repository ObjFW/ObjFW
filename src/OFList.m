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

#import "OFList.h"
#import "OFExceptions.h"

@implementation OFList
+ list
{
	return [[[self alloc] init] autorelease];
}

+ listWithListObjectSize: (size_t)listobj_size_
{
	return [[[self alloc]
	    initWithListObjectSize: listobj_size_] autorelease];
}

- init
{
	self = [super init];

	first = NULL;
	last = NULL;
	listobj_size = sizeof(of_list_object_t);
	retain_and_release = YES;

	return self;
}

- initWithListObjectSize: (size_t)listobj_size_;
{
	self = [super init];

	first = NULL;
	last = NULL;
	listobj_size = listobj_size_;
	retain_and_release = YES;

	return self;
}

- initWithoutRetainAndRelease
{
	self = [super init];

	first = NULL;
	last = NULL;
	listobj_size = sizeof(of_list_object_t);

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

- (of_list_object_t*)append: (id)obj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: listobj_size];
	o->object = obj;
	o->next = NULL;
	o->prev = last;

	if (last != NULL)
		last->next = o;

	last = o;
	if (first == NULL)
		first = o;

	if (retain_and_release)
		[obj retain];

	return o;
}

- (of_list_object_t*)prepend: (id)obj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: listobj_size];
	o->object = obj;
	o->next = first;
	o->prev = NULL;

	if (first != NULL)
		first->prev = o;

	first = o;
	if (last == NULL)
		last = o;

	if (retain_and_release)
		[obj retain];

	return o;
}

- (of_list_object_t*)insert: (id)obj
		     before: (of_list_object_t*)listobj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: listobj_size];
	o->object = obj;
	o->next = listobj;
	o->prev = listobj->prev;

	if (listobj->prev != NULL)
		listobj->prev->next = o;

	listobj->prev = o;

	if (listobj == first)
		first = o;

	if (retain_and_release)
		[obj retain];

	return o;
}

- (of_list_object_t*)insert: (id)obj
		      after: (of_list_object_t*)listobj
{
	of_list_object_t *o;

	o = [self allocMemoryWithSize: listobj_size];
	o->object = obj;
	o->next = listobj->next;
	o->prev = listobj;

	if (listobj->next != NULL)
		listobj->next->prev = o;

	listobj->next = o;

	if (listobj == last)
		last = o;

	if (retain_and_release)
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

	if (retain_and_release)
		[listobj->object release];

	[self freeMemory: listobj];

	return self;
}

- (size_t)count
{
	size_t i;
	of_list_object_t *iter;

	for (i = 0, iter = first; iter != NULL; iter = iter->next)
		i++;

	return i;
}

- (BOOL)isEqual: (id)obj
{
	of_list_object_t *iter, *iter2;

	if (![obj isKindOf: [OFList class]])
		return NO;

	for (iter = first, iter2 = [obj first]; iter != NULL && iter2 != NULL;
	    iter = iter->next, iter2 = iter2->next)
		if (![iter->object isEqual: iter2->object])
			return NO;

	/* One has still items */
	if (iter != NULL || iter2 != NULL)
		return NO;

	return YES;
}

- (id)copy
{
	OFList *new;
	of_list_object_t *iter, *o, *prev;

	if (retain_and_release)
		new = [[OFList alloc] init];
	else
		new = [[OFList alloc] initWithoutRetainAndRelease];

	o = NULL;
	prev = NULL;

	@try {
		for (iter = first; iter != NULL; iter = iter->next) {
			o = [new allocMemoryWithSize: listobj_size];
			o->object = iter->object;
			o->next = NULL;
			o->prev = prev;

			if (new->first == NULL)
				new->first = o;
			if (prev != NULL)
				prev->next = o;
			if (retain_and_release)
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
@end
