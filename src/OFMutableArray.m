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

#include <string.h>

#import "OFMutableArray.h"
#import "OFDataArray.h"
#import "OFExceptions.h"

@implementation OFMutableArray
- copy
{
	OFArray *new = [[OFArray alloc] init];
	id *objs;
	size_t count, i;

	objs = [array cArray];
	count = [array count];

	[new->array addNItems: count
		   fromCArray: objs];

	for (i = 0; i < count; i++)
		[objs[i] retain];

	return new;
}

- (void)addObject: (id)obj
{
	[array addItem: &obj];
	[obj retain];

	mutations++;
}

- (void)addObject: (id)obj
	  atIndex: (size_t)index
{
	[array addItem: &obj
	       atIndex: index];
	[obj retain];

	mutations++;
}

- (void)replaceObject: (id)old
	   withObject: (id)new
{
	id *objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if ([objs[i] isEqual: old]) {
			[new retain];
			[objs[i] release];
			objs[i] = new;

			return;
		}
	}
}

- (void)replaceObjectAtIndex: (size_t)index
		  withObject: (id)obj
{
	id *objs = [array cArray];
	id old;

	if (index >= [array count])
		@throw [OFOutOfRangeException newWithClass: isa];

	old = objs[index];
	objs[index] = [obj retain];
	[old release];
}

- (void)replaceObjectIdenticalTo: (id)old
		      withObject: (id)new
{
	id *objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if (objs[i] == old) {
			[new retain];
			[objs[i] release];
			objs[i] = new;

			return;
		}
	}
}

- (void)removeObject: (id)obj
{
	id *objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if ([objs[i] isEqual: obj]) {
			id obj = objs[i];

			[array removeItemAtIndex: i];
			mutations++;

			[obj release];

			return;
		}
	}
}

- (void)removeObjectIdenticalTo: (id)obj
{
	id *objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if (objs[i] == obj) {
			[array removeItemAtIndex: i];
			mutations++;

			[obj release];

			return;
		}
	}
}

- (void)removeObjectAtIndex: (size_t)index
{
	id old = [self objectAtIndex: index];
	[array removeItemAtIndex: index];
	[old release];

	mutations++;
}

- (void)removeNObjects: (size_t)nobjects
{
	id *objs = [array cArray], *copy;
	size_t i, count = [array count];

	if (nobjects > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	copy = [self allocMemoryForNItems: nobjects
				 withSize: sizeof(id)];
	memcpy(copy, objs + (count - nobjects), nobjects * sizeof(id));

	@try {
		[array removeNItems: nobjects];
		mutations++;

		for (i = 0; i < nobjects; i++)
			[copy[i] release];
	} @finally {
		[self freeMemory: copy];
	}
}

- (void)removeNObjects: (size_t)nobjects
	       atIndex: (size_t)index
{
	id *objs = [array cArray], *copy;
	size_t i, count = [array count];

	if (nobjects > count - index)
		@throw [OFOutOfRangeException newWithClass: isa];

	copy = [self allocMemoryForNItems: nobjects
				 withSize: sizeof(id)];
	memcpy(copy, objs + index, nobjects * sizeof(id));

	@try {
		[array removeNItems: nobjects
			    atIndex: index];
		mutations++;

		for (i = 0; i < nobjects; i++)
			[copy[i] release];
	} @finally {
		[self freeMemory: copy];
	}
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	size_t count = [array count];

	if (state->state >= count)
		return 0;

	state->state = count;
	state->itemsPtr = [array cArray];
	state->mutationsPtr = &mutations;

	return count;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFArrayEnumerator alloc]
	    initWithDataArray: array
	     mutationsPointer: &mutations] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	id *objs = [array cArray];
	size_t i, count = [array count];
	BOOL stop = NO;
	unsigned long mutations2 = mutations;

	for (i = 0; i < count && !stop; i++) {
		if (mutations != mutations2)
			@throw [OFEnumerationMutationException
			    newWithClass: isa];

		block(objs[i], i, &stop);
	}
}

- (void)replaceObjectsUsingBlock: (of_array_replace_block_t)block
{
	id *objs = [array cArray];
	size_t i, count = [array count];
	BOOL stop = NO;
	unsigned long mutations2 = mutations;

	for (i = 0; i < count && !stop; i++) {
		if (mutations != mutations2)
			@throw [OFEnumerationMutationException
			    newWithClass: isa];

		id new = block(objs[i], i, &stop);

		if (new == nil)
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		[new retain];
		[objs[i] release];
		objs[i] = new;
	}
}
#endif
@end
