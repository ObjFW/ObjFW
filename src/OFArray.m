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

#include <stdarg.h>

#import "OFArray.h"
#import "OFExceptions.h"

@implementation OFArray
+ array
{
	return [[[self alloc] init] autorelease];
}

+ arrayWithObject: (OFObject*)obj
{
	return [[[self alloc] initWithObject: obj] autorelease];
}

+ arrayWithObjects: (OFObject*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [[[self alloc] initWithObject: first
				 andArgList: args] autorelease];
	va_end(args);

	return ret;
}

- init
{
	self = [super init];

	@try {
		array = [[OFDataArray alloc]
		    initWithItemSize: sizeof(OFObject*)];
	} @catch (OFException *e) {
		/*
		 * We can't use [super dealloc] on OS X here. Compiler bug?
		 * [self dealloc] will do here as we check for nil in dealloc.
		 */
		[self dealloc];
		@throw e;
	}

	return self;
}

- initWithObject: (OFObject*)obj
{
	self = [self init];

	@try {
		[array add: &obj];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	[obj retain];

	return self;
}

- initWithObjects: (OFObject*)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [self initWithObject: first
			andArgList: args];
	va_end(args);

	return ret;
}

- initWithObject: (OFObject*)first
      andArgList: (va_list)args
{
	id obj;
	OFObject **objs;
	size_t len, i;

	self = [self init];

	@try {
		[array add: &first];
		while ((obj = va_arg(args, id)) != nil)
			[array add: &obj];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	/* Retain objects after adding them for the case adding failed */
	objs = [array data];
	len = [array count];

	[first retain];
	for (i = 0; i < len; i++)
		[objs[i] retain];

	return self;
}

- (size_t)count
{
	return [array count];
}

- (id*)data
{
	return [array data];
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	OFArray *new = [OFMutableArray array];
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
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- removeNObjects: (size_t)nobjects
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- (void)dealloc
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

	[super dealloc];
}
@end
