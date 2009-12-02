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

- removeObject: (id)obj
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if ([objs[i] isEqual: obj]) {
			[objs[i] release];
			[array removeItemAtIndex: i];
			return self;
		}
	}

	return self;
}

- removeObjectIdenticalTo: (id)obj
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++) {
		if (objs[i] == obj) {
			[obj release];
			[array removeItemAtIndex: i];
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
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	if (nobjects > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	for (i = count - nobjects; i < count; i++)
		[objs[i] release];

	[array removeNItems: nobjects];

	return self;
}

- removeNObjects: (size_t)nobjects
	 atIndex: (size_t)index
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	if (nobjects > count)
		@throw [OFOutOfRangeException newWithClass: isa];

	for (i = index; i < count && i < index + nobjects; i++)
		[objs[i] release];

	[array removeNItems: nobjects
		    atIndex: index];

	return self;
}
@end
