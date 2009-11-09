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
	size_t len, i;

	objs = [array cArray];
	len = [array count];

	[new->array addNItems: len
		   fromCArray: objs];

	for (i = 0; i < len; i++)
		[objs[i] retain];

	return new;
}

- addObject: (OFObject*)obj
{
	[array addItem: &obj];
	[obj retain];

	return self;
}

- removeNObjects: (size_t)nobjects
{
	OFObject **objs;
	size_t len, i;

	objs = [array cArray];
	len = [array count];

	if (nobjects > len)
		@throw [OFOutOfRangeException newWithClass: isa];

	for (i = len - nobjects; i < len; i++)
		[objs[i] release];

	[array removeNItems: nobjects];

	return self;
}
@end
