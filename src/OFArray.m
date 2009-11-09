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

#include <stdarg.h>

#import "OFArray.h"
#import "OFExceptions.h"
#import "OFMacros.h"

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
				    argList: args] autorelease];
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
			   argList: args];
	va_end(args);

	return ret;
}

- initWithObject: (OFObject*)first
	 argList: (va_list)args
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

- (id*)cArray
{
	return [array cArray];
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

	objs = [array cArray];
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
	void *last = [array lastItem];

	return (last != NULL ? *((id*)last) : nil);
}

- (BOOL)isEqual: (id)obj
{
	OFObject **objs, **objs2;
	size_t i, len, len2;

	if (![obj isKindOfClass: [OFArray class]])
		return NO;

	len = [array count];
	len2 = [obj count];

	if (len != len2)
		return NO;

	objs = [array cArray];
	objs2 = [obj cArray];

	for (i = 0; i < len; i++)
		if (![objs[i] isEqual: objs2[i]])
			return NO;

	return YES;
}

- (void)dealloc
{
	OFObject **objs;
	size_t len, i;

	if (array != nil) {
		objs = [array cArray];
		len = [array count];

		for (i = 0; i < len; i++)
			[objs[i] release];

		[array release];
	}

	[super dealloc];
}

- addObject: (OFObject*)obj
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- removeNObjects: (size_t)nobjects
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (uint32_t)hash
{
	OFObject **carray = [array cArray];
	size_t i, count = [array count];
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < count; i++) {
		uint32_t h = [carray[i] hash];

		OF_HASH_ADD(hash, h >> 24);
		OF_HASH_ADD(hash, (h >> 16) & 0xFF);
		OF_HASH_ADD(hash, (h >> 8) & 0xFF);
		OF_HASH_ADD(hash, h & 0xFF);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end
