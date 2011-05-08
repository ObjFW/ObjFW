/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#include <stdarg.h>

#import "OFArray.h"
#import "OFDataArray.h"
#import "OFString.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

@implementation OFArray
+ array
{
	return [[[self alloc] init] autorelease];
}

+ arrayWithObject: (id)object
{
	return [[[self alloc] initWithObject: object] autorelease];
}

+ arrayWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[[self alloc] initWithObject: firstObject
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ arrayWithCArray: (id*)objects
{
	return [[[self alloc] initWithCArray: objects] autorelease];
}

+ arrayWithCArray: (id*)objects
	   length: (size_t)length
{
	return [[[self alloc] initWithCArray: objects
				      length: length] autorelease];
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

- initWithObject: (id)object
{
	self = [self init];

	@try {
		[array addItem: &object];
		[object retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [self initWithObject: firstObject
			 arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	self = [self init];

	@try {
		id object;

		[array addItem: &firstObject];
		while ((object = va_arg(arguments, id)) != nil) {
			[array addItem: &object];
			[object retain];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCArray: (id*)objects
{
	self = [self init];

	@try {
		id *object;
		size_t count = 0;

		for (object = objects; *object != nil; object++) {
			[*object retain];
			count++;
		}

		[array addNItems: count
		      fromCArray: objects];
	} @catch (id e) {
		id *object;

		for (object = objects; *object != nil; object++)
			[*object release];

		[self release];
		@throw e;
	}

	return self;
}

- initWithCArray: (id*)objects
	  length: (size_t)length
{
	self = [self init];

	@try {
		size_t i;

		for (i = 0; i < length; i++)
			[objects[i] retain];

		[array addNItems: length
		      fromCArray: objects];
	} @catch (id e) {
		size_t i;

		for (i = 0; i < length; i++)
			[objects[i] release];

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
	OFArray *mutableCopy = [[OFMutableArray alloc] init];
	id *cArray;
	size_t count, i;

	cArray = [array cArray];
	count = [array count];

	[mutableCopy->array addNItems: count
			   fromCArray: cArray];

	for (i = 0; i < count; i++)
		[cArray[i] retain];

	return mutableCopy;
}

- (id)objectAtIndex: (size_t)index
{
	return *((id*)[array itemAtIndex: index]);
}

- (size_t)indexOfObject: (id)object
{
	id *cArray = [array cArray];
	size_t i, count = [array count];

	if (cArray == NULL)
		return OF_INVALID_INDEX;

	for (i = 0; i < count; i++)
		if ([cArray[i] isEqual: object])
			return i;

	return OF_INVALID_INDEX;
}

- (size_t)indexOfObjectIdenticalTo: (id)object
{
	id *cArray = [array cArray];
	size_t i, count = [array count];

	if (cArray == NULL)
		return OF_INVALID_INDEX;

	for (i = 0; i < count; i++)
		if (cArray[i] == object)
			return i;

	return OF_INVALID_INDEX;
}

- (BOOL)containsObject: (id)object
{
	id *cArray = [array cArray];
	size_t i, count = [array count];

	if (cArray == NULL)
		return NO;

	for (i = 0; i < count; i++)
		if ([cArray[i] isEqual: object])
			return YES;

	return NO;
}

- (BOOL)containsObjectIdenticalTo: (id)object
{
	id *cArray = [array cArray];
	size_t i, count = [array count];

	if (cArray == NULL)
		return NO;

	for (i = 0; i < count; i++)
		if (cArray[i] == object)
			return YES;

	return NO;
}

- (id)firstObject
{
	id *firstObject = [array firstItem];

	return (firstObject != NULL ? *firstObject : nil);
}

- (id)lastObject
{
	id *lastObject = [array lastItem];

	return (lastObject != NULL ? *lastObject : nil);
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
	OFString *ret;
	OFObject **cArray = [array cArray];
	size_t i, count = [array count];
	IMP append;

	if (count == 0)
		return @"";
	if (count == 1)
		return [cArray[0] description];

	ret = [OFMutableString string];
	append = [ret methodForSelector: @selector(appendString:)];

	pool = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count - 1; i++) {
		append(ret, @selector(appendString:), [cArray[i] description]);
		append(ret, @selector(appendString:), separator);

		[pool releaseObjects];
	}
	append(ret, @selector(appendString:), [cArray[i] description]);

	[pool release];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}

- (BOOL)isEqual: (id)object
{
	OFArray *otherArray;
	id *cArray, *otherCArray;
	size_t i, count;

	if (![object isKindOfClass: [OFArray class]])
		return NO;

	otherArray = (OFArray*)object;

	count = [array count];

	if (count != [otherArray count])
		return NO;

	cArray = [array cArray];
	otherCArray = [otherArray cArray];

	for (i = 0; i < count; i++)
		if (![cArray[i] isEqual: otherCArray[i]])
			return NO;

	return YES;
}

- (uint32_t)hash
{
	id *cArray = [array cArray];
	size_t i, count = [array count];
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < count; i++) {
		uint32_t h = [cArray[i] hash];

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
	OFAutoreleasePool *pool;
	OFMutableString *ret;

	if ([array count] == 0)
		return @"()";

	pool = [[OFAutoreleasePool alloc] init];
	ret = [[self componentsJoinedByString: @",\n"] mutableCopy];

	@try {
		[ret prependString: @"(\n"];
		[ret replaceOccurrencesOfString: @"\n"
				     withString: @"\n\t"];
		[ret appendString: @"\n)"];
	} @catch (id e) {
		[ret release];
		@throw e;
	}

	[pool release];

	[ret autorelease];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}

- (OFString*)stringBySerializing
{
	OFAutoreleasePool *pool;
	OFMutableString *ret;
	OFObject <OFSerialization> **cArray;
	size_t i, count;
	IMP append;

	if ([array count] == 0) {
		if ([self isKindOfClass: [OFMutableArray class]])
			return @"<mutable,0>()";
		else
			return @"<0>()";
	}

	cArray = [array cArray];
	count = [array count];
	if ([self isKindOfClass: [OFMutableArray class]])
		ret = [OFMutableString stringWithFormat: @"<mutable,%zd>(\n",
							 count];
	else
		ret = [OFMutableString stringWithFormat: @"<%zd>(\n", count];
	pool = [[OFAutoreleasePool alloc] init];
	append = [ret methodForSelector: @selector(appendString:)];

	for (i = 0; i < count - 1; i++) {
		append(ret, @selector(appendString:),
		    [cArray[i] stringBySerializing]);
		append(ret, @selector(appendString:), @",\n");

		[pool releaseObjects];
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendFormat: @"%@\n)", [cArray[i] stringBySerializing]];

	[pool release];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}

- (void)makeObjectsPerformSelector: (SEL)selector
{
	id *cArray = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++)
		((void(*)(id, SEL))[cArray[i]
		    methodForSelector: selector])(cArray[i], selector);
}

- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (id)object
{
	id *cArray = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++)
		((void(*)(id, SEL, id))[cArray[i]
		    methodForSelector: selector])(cArray[i], selector, object);
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	size_t count = [array count];

	if (count > INT_MAX)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (state->state >= count)
		return 0;

	state->state = count;
	state->itemsPtr = [array cArray];
	state->mutationsPtr = (unsigned long*)self;

	return (int)count;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFArrayEnumerator alloc] initWithArray: self
					       dataArray: array
					mutationsPointer: NULL] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	id *cArray = [array cArray];
	size_t i, count = [array count];
	BOOL stop = NO;

	for (i = 0; i < count && !stop; i++) {
		block(cArray[i], i, &stop);
		[pool releaseObjects];
	}

	[pool release];
}

- (OFArray*)mappedArrayUsingBlock: (of_array_map_block_t)block
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *ret;
	size_t count = [array count];
	id *tmp = [self allocMemoryForNItems: count
				    withSize: sizeof(id)];

	@try {
		id *cArray = [array cArray];
		size_t i;

		for (i = 0; i < count; i++)
			tmp[i] = block(cArray[i], i);

		ret = [[OFArray alloc] initWithCArray: tmp
					       length: count];

		@try {
			[pool release];
		} @finally {
			[ret autorelease];
		}
	} @finally {
		[self freeMemory: tmp];
	}

	return ret;
}

- (OFArray*)filteredArrayUsingBlock: (of_array_filter_block_t)block
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFArray *ret;
	size_t count = [array count];
	id *tmp = [self allocMemoryForNItems: count
				    withSize: sizeof(id)];

	@try {
		id *cArray = [array cArray];
		size_t i, j = 0;

		for (i = 0; i < count; i++) {
			if (block(cArray[i], i))
				tmp[j++] = cArray[i];

			[pool releaseObjects];
		}

		[pool release];

		ret = [OFArray arrayWithCArray: tmp
					length: j];
	} @finally {
		[self freeMemory: tmp];
	}

	return ret;
}
#endif

- (void)dealloc
{
	id *cArray = [array cArray];
	size_t i, count = [array count];

	for (i = 0; i < count; i++)
		[cArray[i] release];

	[array release];

	[super dealloc];
}
@end

@implementation OFArrayEnumerator
-    initWithArray: (OFArray*)array_
	 dataArray: (OFDataArray*)dataArray_
  mutationsPointer: (unsigned long*)mutationsPtr_;
{
	self = [super init];

	array = [array_ retain];
	dataArray = [dataArray_ retain];
	count = [dataArray count];
	mutations = (mutationsPtr_ != NULL ? *mutationsPtr_ : 0);
	mutationsPtr = mutationsPtr_;

	return self;
}

- (void)dealloc
{
	[array release];
	[dataArray release];

	[super dealloc];
}

- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa
							     object: array];

	if (pos < count)
		return *(id*)[dataArray itemAtIndex: pos++];

	return nil;
}

- (void)reset
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa
							     object: array];

	pos = 0;
}
@end
