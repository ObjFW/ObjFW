/*
 * Copyright (c) 2008 - 2010
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
#import "OFDataArray.h"
#import "OFString.h"
#import "OFExceptions.h"
#import "macros.h"

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

+ arrayWithCArray: (OFObject**)objs
	   length: (size_t)len
{
	return [[[self alloc] initWithCArray: objs
				      length: len] autorelease];
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
	size_t count;

	self = [self init];
	
	count = 0;

	for (obj = objs; *obj != nil; obj++) {
		[*obj retain];
		count++;
	}

	@try {
		[array addNItems: count
		      fromCArray: objs];
	} @catch (OFException *e) {
		for (obj = objs; *obj != nil; obj++)
			[*obj release];

		[self dealloc];
		@throw e;
	}

	return self;
}

- initWithCArray: (OFObject**)objs
	  length: (size_t)len
{
	size_t i;

	self = [self init];

	for (i = 0; i < len; i++)
		[objs[i] retain];

	@try {
		[array addNItems: len
		      fromCArray: objs];
	} @catch (OFException *e) {
		for (i = 0; i < len; i++)
			[objs[i] release];

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
	size_t count, i;

	objs = [array cArray];
	count = [array count];

	[new->array addNItems: count
		   fromCArray: objs];

	for (i = 0; i < count; i++)
		[objs[i] retain];

	return new;
}

- (id)objectAtIndex: (size_t)index
{
	return [[*((OFObject**)[array itemAtIndex: index]) retain] autorelease];
}

- (size_t)indexOfObject: (OFObject*)obj
{
	id *objs = [array cArray];
	size_t i, count = [array count];

	if (objs == NULL)
		return SIZE_MAX;

	for (i = 0; i < count; i++)
		if ([objs[i] isEqual: obj])
			return i;

	return SIZE_MAX;
}

- (size_t)indexOfObjectIdenticalTo: (OFObject*)obj
{
	id *objs = [array cArray];
	size_t i, count = [array count];

	if (objs == NULL)
		return SIZE_MAX;

	for (i = 0; i < count; i++)
		if (objs[i] == obj)
			return i;

	return SIZE_MAX;
}

- (id)firstObject
{
	id *first = [array firstItem];

	return (first != NULL ? [[*first retain] autorelease] : nil);
}

- (id)lastObject
{
	id *last = [array lastItem];

	return (last != NULL ? [[*last retain] autorelease] : nil);
}

- (OFString*)componentsJoinedByString: (OFString*)separator
{
	OFString *str;
	OFString **objs = [array cArray];
	size_t i, count = [array count];
	IMP append;

	if (count == 0)
		return @"";
	if (count == 1)
		return [objs[0] retain];

	str = [OFMutableString string];
	append = [str methodForSelector: @selector(appendString:)];

	for (i = 0; i < count - 1; i++) {
		append(str, @selector(appendString:), objs[i]);
		append(str, @selector(appendString:), separator);
	}
	append(str, @selector(appendString:), objs[i]);

	return str;
}

- (BOOL)isEqual: (OFObject*)obj
{
	OFObject **objs, **objs2;
	size_t i, count, count2;

	if (![obj isKindOfClass: [OFArray class]])
		return NO;

	count = [array count];
	count2 = [(OFArray*)obj count];

	if (count != count2)
		return NO;

	objs = [array cArray];
	objs2 = [(OFArray*)obj cArray];

	for (i = 0; i < count; i++)
		if (![objs[i] isEqual: objs2[i]])
			return NO;

	return YES;
}

- (uint32_t)hash
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < count; i++) {
		uint32_t h = [objs[i] hash];

		OF_HASH_ADD(hash, h >> 24);
		OF_HASH_ADD(hash, (h >> 16) & 0xFF);
		OF_HASH_ADD(hash, (h >> 8) & 0xFF);
		OF_HASH_ADD(hash, h & 0xFF);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
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
	state->mutationsPtr = (unsigned long*)self;

	return count;
}

- (OFEnumerator*)enumerator
{
	return [[[OFArrayEnumerator alloc]
	    initWithDataArray: array
	     mutationsPointer: NULL] autorelease];
}

- (void)dealloc
{
	OFObject **objs = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++)
		[objs[i] release];

	[array release];

	[super dealloc];
}
@end

/// \cond internal
@implementation OFArrayEnumerator
- initWithDataArray: (OFDataArray*)array_
   mutationsPointer: (unsigned long*)mutations_ptr_;
{
	self = [super init];

	array = array_;
	count = [array_ count];
	mutations = *mutations_ptr_;
	mutations_ptr = mutations_ptr_;

	return self;
}

- (id)nextObject
{
	if (mutations_ptr != NULL && *mutations_ptr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	if (pos < count)
		return *(OFObject**)[array itemAtIndex: pos++];

	return nil;
}

- (void)reset
{
	if (mutations_ptr != NULL && *mutations_ptr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	pos = 0;
}
@end
/// \endcond
