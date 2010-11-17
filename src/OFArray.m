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
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"
#import "macros.h"

@implementation OFArray
+ array
{
	return [[[self alloc] init] autorelease];
}

+ arrayWithObject: (id)obj
{
	return [[[self alloc] initWithObject: obj] autorelease];
}

+ arrayWithObjects: (id)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [[[self alloc] initWithObject: first
				    argList: args] autorelease];
	va_end(args);

	return ret;
}

+ arrayWithCArray: (id*)objs
{
	return [[[self alloc] initWithCArray: objs] autorelease];
}

+ arrayWithCArray: (id*)objs
	   length: (size_t)len
{
	return [[[self alloc] initWithCArray: objs
				      length: len] autorelease];
}

- init
{
	self = [super init];

	@try {
		array = [[OFDataArray alloc] initWithItemSize: sizeof(id)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)obj
{
	self = [self init];

	@try {
		[array addItem: &obj];
		[obj retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObjects: (id)first, ...
{
	id ret;
	va_list args;

	va_start(args, first);
	ret = [self initWithObject: first
			   argList: args];
	va_end(args);

	return ret;
}

- initWithObject: (id)first
	 argList: (va_list)args
{
	self = [self init];

	@try {
		id obj;

		[array addItem: &first];
		while ((obj = va_arg(args, id)) != nil) {
			[array addItem: &obj];
			[obj retain];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCArray: (id*)objs
{
	self = [self init];

	@try {
		id *obj;
		size_t count = 0;

		for (obj = objs; *obj != nil; obj++) {
			[*obj retain];
			count++;
		}

		[array addNItems: count
		      fromCArray: objs];
	} @catch (id e) {
		id *obj;

		for (obj = objs; *obj != nil; obj++)
			[*obj release];

		[self release];
		@throw e;
	}

	return self;
}

- initWithCArray: (id*)objs
	  length: (size_t)len
{
	self = [self init];

	@try {
		size_t i;

		for (i = 0; i < len; i++)
			[objs[i] retain];

		[array addNItems: len
		      fromCArray: objs];
	} @catch (id e) {
		size_t i;

		for (i = 0; i < len; i++)
			[objs[i] release];

		[self release];
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

- copy
{
	return [self retain];
}

- mutableCopy
{
	OFArray *new = [[OFMutableArray alloc] init];
	id *objs;
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
	return *((id*)[array itemAtIndex: index]);
}

- (size_t)indexOfObject: (id)obj
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

- (size_t)indexOfObjectIdenticalTo: (id)obj
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

	return (first != NULL ? *first : nil);
}

- (id)lastObject
{
	id *last = [array lastItem];

	return (last != NULL ? *last : nil);
}

- (OFArray*)objectsFromIndex: (size_t)start
		     toIndex: (size_t)end
{
	size_t count = [array count];

	if (end > count || start > end)
		@throw [OFOutOfRangeException newWithClass: isa];

	return [OFArray arrayWithCArray: (id*)[array cArray] + start
				 length: end - start];
}

- (OFArray*)objectsInRange: (of_range_t)range
{
	return [self objectsFromIndex: range.start
			      toIndex: range.start + range.length];
}

- (OFString*)componentsJoinedByString: (OFString*)separator
{
	OFAutoreleasePool *pool;
	OFString *str;
	OFString **objs = [array cArray];
	size_t i, count = [array count];
	Class cls;
	IMP append;

	if (count == 0)
		return @"";
	if (count == 1)
		return [objs[0] description];

	str = [OFMutableString string];
	cls = [OFString class];
	append = [str methodForSelector: @selector(appendString:)];

	pool = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count - 1; i++) {
		if (![objs[i] isKindOfClass: cls])
			@throw [OFInvalidArgumentException newWithClass: isa
							       selector: _cmd];

		append(str, @selector(appendString:), [objs[i] description]);
		append(str, @selector(appendString:), separator);

		[pool releaseObjects];
	}
	append(str, @selector(appendString:), [objs[i] description]);

	[pool release];

	return str;
}

- (BOOL)isEqual: (id)obj
{
	id *objs, *objs2;
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
	id *objs = [array cArray];
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

- (OFString*)description
{
	OFMutableString *ret;

	ret = (OFMutableString*)[self componentsJoinedByString: @", "];
	[ret prependString: @"("];
	[ret appendString: @")"];

	return ret;
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

- (OFEnumerator*)objectEnumerator
{
	return [[[OFArrayEnumerator alloc]
	    initWithDataArray: array
	     mutationsPointer: NULL] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	id *objs = [array cArray];
	size_t i, count = [array count];
	BOOL stop = NO;

	for (i = 0; i < count && !stop; i++)
		block(objs[i], i, &stop);
}
#endif

- (void)dealloc
{
	id *objs = [array cArray];
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
   mutationsPointer: (unsigned long*)mutationsPtr_;
{
	self = [super init];

	array = array_;
	count = [array_ count];
	mutations = (mutationsPtr_ != NULL ? *mutationsPtr_ : 0);
	mutationsPtr = mutationsPtr_;

	return self;
}

- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	if (pos < count)
		return *(id*)[array itemAtIndex: pos++];

	return nil;
}

- (void)reset
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa];

	pos = 0;
}
@end
/// \endcond
