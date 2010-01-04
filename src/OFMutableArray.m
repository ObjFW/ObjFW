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

	return self;
}

- addObject: (OFObject*)obj
    atIndex: (size_t)index
{
	[array addItem: &obj
	       atIndex: index];
	[obj retain];

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
			[obj release];
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
			[obj release];
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

		for (i = 0; i < nobjects; i++)
			[copy[i] release];
	} @finally {
		[self freeMemory: copy];
	}

	return self;
}
@end
