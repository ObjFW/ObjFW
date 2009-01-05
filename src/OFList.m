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

#import "OFList.h"

@implementation OFList
- init
{
	if ((self = [super init])) {
		first = NULL;
		last  = NULL;
	}

	return self;
}

- free
{
	of_list_object_t *iter;

	for (iter = first; iter != NULL; iter = iter->next)
		[iter->object release];

	return [super free];
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
	of_list_object_t *o = [self getMemWithSize: sizeof(of_list_object_t)];

	o->object = obj;
	o->next = NULL;
	o->prev = last;

	if (last != NULL)
		last->next = o;

	last = o;
	if (first == NULL)
		first = o;

	[obj retain];
	return o;
}

- (of_list_object_t*)prepend: (id)obj
{
	of_list_object_t *o = [self getMemWithSize: sizeof(of_list_object_t)];

	o->object = obj;
	o->next = first;
	o->prev = NULL;

	if (first != NULL)
		first->prev = o;

	first = o;
	if (last == NULL)
		last = o;

	[obj retain];
	return o;
}

- (of_list_object_t*)insert: (id)obj
		     before: (of_list_object_t*)listobj
{
	of_list_object_t *o = [self getMemWithSize: sizeof(of_list_object_t)];

	o->object = obj;
	o->next = listobj;
	o->prev = listobj->prev;

	if (listobj->prev != NULL)
		listobj->prev->next = o;

	listobj->prev = o;

	if (listobj == first)
		first = o;

	[obj retain];
	return o;
}

- (of_list_object_t*)insert: (id)obj
		      after: (of_list_object_t*)listobj
{
	of_list_object_t *o = [self getMemWithSize: sizeof(of_list_object_t)];

	o->object = obj;
	o->next = listobj->next;
	o->prev = listobj;

	if (listobj->next != NULL)
		listobj->next->prev = o;

	listobj->next = o;

	if (listobj == last)
		last = o;

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

	[self freeMem: listobj];
	return self;
}
@end
