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

#import "OFMutableArray.h"
#import "OFExceptions.h"

@implementation OFMutableArray
- add: (OFObject*)obj
{
	[array add: &obj];
	[obj retain];

	return self;
}

- removeNObjects: (size_t)nobjects
{
	OFObject **objs;
	size_t len, i;

	objs = [array data];
	len = [array count];

	if (nobjects > len)
		@throw [OFOutOfRangeException newWithClass: isa];

	for (i = len - nobjects; i < len; i++)
		[objs[i] release];

	[array removeNItems: nobjects];

	return self;
}
@end
