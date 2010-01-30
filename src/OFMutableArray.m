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

#include <string.h>

#import "OFMutableArray.h"
#import "OFDataArray.h"
#import "OFExceptions.h"

@implementation OFMutableArray
- (id)copy
{
	OFArray *new = [[OFArray alloc] init];
	OFObject **objs;
	size_t count, i;

	objs = [array cArray];
	count = [array count];

	[new->array addNItems: count
		   fromCArray: objs];

	for (i = 0; i < count; i++)
		[objs[i] retain];

	return new;
}

- addObject: (OFObject*)obj
{
	[array addItem: &obj];
	[obj retain];

	mutations++;

	return self;
}

- addObject: (OFObject*)obj
    atIndex: (size_t)index
{
	[array addItem: &obj
	       atIndex: index];
	[obj retain];

	mutations++;

	return self;
}

- replaceObject: (OFObject*)old
     withObject: (OFObject*)new
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if ([objs[i] isEqual: old]) {
			[new retain];
			[objs[i] release];
			objs[i] = new;
		}
	}

	return self;
}

- replaceObjectAtIndex: (size_t)index
	    withObject: (OFObject*)obj
{
	OFObject **objs = [array cArray];

	if (index >= [array count])
		@throw [OFOutOfRangeException newWithClass: isa];

	[obj retain];
	[objs[index] release];
	objs[index] = obj;

	return self;
}

- replaceObjectIdenticalTo: (OFObject*)old
		withObject: (OFObject*)new
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if (objs[i] == old) {
			[new retain];
			[objs[i] release];
			objs[i] = new;
		}
	}

	return self;
}

- removeObject: (OFObject*)obj
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if ([objs[i] isEqual: obj]) {
			OFObject *obj = objs[i];

			[array removeItemAtIndex: i];
			mutations++;

			[obj release];

			/*
			 * We need to get the C array again as it might have
			 * been relocated. We also need to adjust the count
			 * as otherwise we would have an out of bounds access.
			 * As another object will be at the current index now,
			 * we also need to handle the same index again, thus we
			 * decrease it.
			 */
			objs = [array cArray];
			count--;
			i--;
		}
	}

	return self;
}

- removeObjectIdenticalTo: (OFObject*)obj
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if (objs[i] == obj) {
			[array removeItemAtIndex: i];
			mutations++;

			[obj release];

			/*
			 * We need to get the C array again as it might have
			 * been relocated. We also need to adjust the count
			 * as otherwise we would have an out of bounds access.
			 * As another object will be at the current index now,
			 * we also need to handle the same index again, thus we
			 * decrease it.
			 */
			objs = [array cArray];
			count--;
			i--;
		}
	}

	return self;
}

- removeObjectAtIndex: (size_t)index
{
	return [self removeNObjects: 1
			    atIndex: index];
}

- removeNObjects: (size_t)nobjects
{
	OFObject **objs = [array cArray], **copy;
	size_t i, count = [array count];

	if (nobjects > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	copy = [self allocMemoryForNItems: nobjects
				 withSize: sizeof(OFObject*)];
	memcpy(copy, objs + (count - nobjects), nobjects * sizeof(OFObject*));

	@try {
		[array removeNItems: nobjects];
		mutations++;

		for (i = 0; i < nobjects; i++)
			[copy[i] release];
	} @finally {
		[self freeMemory: copy];
	}

	return self;
}

- removeNObjects: (size_t)nobjects
	 atIndex: (size_t)index
{
	OFObject **objs = [array cArray], **copy;
	size_t i, count = [array count];

	if (nobjects > count - index)
		@throw [OFOutOfRangeException newWithClass: isa];

	copy = [self allocMemoryForNItems: nobjects
				 withSize: sizeof(OFObject*)];
	memcpy(copy, objs + index, nobjects * sizeof(OFObject*));

	@try {
		[array removeNItems: nobjects
			    atIndex: index];
		mutations++;

		for (i = 0; i < nobjects; i++)
			[copy[i] release];
	} @finally {
		[self freeMemory: copy];
	}

	return self;
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

- (OFEnumerator*)enumerator
{
	return [[[OFArrayEnumerator alloc]
	    initWithDataArray: array
	     mutationsPointer: &mutations] autorelease];
}
@end
