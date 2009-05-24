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

+ arrayWithCArray: (OFObject**)objs
{
	return [[[self alloc] initWithCArray: objs] autorelease];
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
		[array addItem: &obj];
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

	self = [self init];

	@try {
		[array addItem: &first];
		while ((obj = va_arg(args, id)) != nil) {
			[array addItem: &obj];
			[obj retain];
		}
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

- initWithCArray: (OFObject**)objs
{
	id *obj;

	self = [self init];

	@try {
		for (obj = objs; *obj != nil; obj++) {
			[array addItem: obj];
			[*obj retain];
		}
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

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
	OFArray *new = [[OFMutableArray alloc] init];
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

- (id)objectAtIndex: (size_t)index
{
	return *((OFObject**)[array itemAtIndex: index]);
}

- (id)lastObject
{
	return *((OFObject**)[array lastItem]);
}

- (BOOL)isEqual: (id)obj
{
	OFObject **objs, **objs2;
	size_t i, len, len2;

	if (![obj isKindOf: [OFArray class]])
		return NO;

	len = [array count];
	len2 = [obj count];

	if (len != len2)
		return NO;

	objs = [array data];
	objs2 = [obj data];

	for (i = 0; i < len; i++)
		if (![objs[i] isEqual: objs2[i]])
			return NO;

	return YES;
}

- addObject: (OFObject*)obj
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
