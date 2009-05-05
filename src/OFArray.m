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

#import "OFArray.h"
#import "OFExceptions.h"

@implementation OFArray
+ array
{
	return [[[OFArray alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		array = [[OFDataArray alloc]
		    initWithItemSize: sizeof(OFObject*)];
	} @catch (OFException *e) {
		/*
		 * We can't use [super free] on OS X here. Compiler bug?
		 * [self free] will do here as we check for nil in free.
		 */
		[self free];
		@throw e;
	}

	return self;
}

- (size_t)count
{
	return [array count];
}

- (id)copy
{
	OFArray *new = [OFArray array];
	OFObject **objs;
	size_t len, i;

	objs = [array data];
	len = [array count];

	[new->array addNItems: len
		   fromCArray: objs];

	for (i = 0; i < len; i++)
		[objs[i] retain];

	return new;
}

- (id)object: (size_t)index
{
	return *((OFObject**)[array item: index]);
}

- (id)last
{
	return *((OFObject**)[array last]);
}

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

- free
{
	OFObject **objs;
	size_t len, i;

	if (array != nil) {
		objs = [array data];
		len = [array count];

		for (i = 0; i < len; i++)
			[objs[i] release];

		[array release];
	}

	return [super free];
}
@end
