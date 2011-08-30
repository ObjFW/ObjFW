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
#import "OFArray_adjacent.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

static struct {
	Class isa;
} placeholder;

@implementation OFArray_placeholder
- init
{
	return (id)[[OFArray_adjacent alloc] init];
}

- initWithObject: (id)object
{
	return (id)[[OFArray_adjacent alloc] initWithObject: object];
}

- initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFArray_adjacent alloc] initWithObject: firstObject
					     arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	return (id)[[OFArray_adjacent alloc] initWithObject: firstObject
						  arguments: arguments];
}

- initWithArray: (OFArray*)array
{
	return (id)[[OFArray_adjacent alloc] initWithArray: array];
}

- initWithCArray: (id*)objects
{
	return (id)[[OFArray_adjacent alloc] initWithCArray: objects];
}

- initWithCArray: (id*)objects
	  length: (size_t)length
{
	return (id)[[OFArray_adjacent alloc] initWithCArray: objects
						     length: length];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFArray_adjacent alloc] initWithSerialization: element];
}

- retain
{
	return self;
}

- autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}
@end

@implementation OFArray
+ (void)initialize
{
	if (self == [OFArray class])
		placeholder.isa = [OFArray_placeholder class];
}

+ alloc
{
	if (self == [OFArray class])
		return (id)&placeholder;

	return [super alloc];
}

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

+ arrayWithArray: (OFArray*)array
{
	return [[[self alloc] initWithArray: array] autorelease];
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
	if (isa == [OFArray class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException newWithClass: c
						      selector: _cmd];
	}

	return [super init];
}

- initWithObject: (id)object
{
	return [self initWithObjects: object, nil];
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
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithArray: (OFArray*)array
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithCArray: (id*)objects
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithCArray: (id*)objects
	  length: (size_t)length
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithSerialization: (OFXMLElement*)element
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- (size_t)count
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)getObjects: (id*)buffer
	   inRange: (of_range_t)range
{
	size_t i;

	for (i = 0; i < range.length; i++)
		buffer[i] = [self objectAtIndex: range.start + i];
}

- (id*)cArray
{
	OFObject *container;
	size_t count;
	id *buffer;

	container = [[[OFObject alloc] init] autorelease];
	count = [self count];
	buffer = [container allocMemoryForNItems: [self count]
					withSize: sizeof(*buffer)];

	[self getObjects: buffer
		 inRange: of_range(0, count)];

	return buffer;
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableArray alloc] initWithArray: self];
}

- (id)objectAtIndex: (size_t)index
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (size_t)indexOfObject: (id)object
{
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		if ([[self objectAtIndex: i] isEqual: object])
			return i;

	return OF_INVALID_INDEX;
}

- (size_t)indexOfObjectIdenticalTo: (id)object
{
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		if ([self objectAtIndex: i] == object)
			return i;

	return OF_INVALID_INDEX;
}

- (BOOL)containsObject: (id)object
{
	return ([self indexOfObject: object] != OF_INVALID_INDEX);
}

- (BOOL)containsObjectIdenticalTo: (id)object
{
	return ([self indexOfObjectIdenticalTo: object] != OF_INVALID_INDEX);
}

- (id)firstObject
{
	if ([self count] > 0)
		return [self objectAtIndex: 0];

	return nil;
}

- (id)lastObject
{
	size_t count = [self count];

	if (count > 0)
		return [self objectAtIndex: count - 1];

	return nil;
}

- (OFArray*)objectsInRange: (of_range_t)range
{
	OFArray *ret;
	id *buffer = [self allocMemoryForNItems: range.length
				       withSize: sizeof(*buffer)];

	@try {
		[self getObjects: buffer
			 inRange: range];

		ret = [OFArray arrayWithCArray: buffer
					length: range.length];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString*)componentsJoinedByString: (OFString*)separator
{
	OFAutoreleasePool *pool, *pool2;
	OFMutableString *ret;
	id *cArray;
	size_t i, count = [self count];
	IMP append;

	if (count == 0)
		return @"";
	if (count == 1)
		return [[self firstObject] description];

	ret = [OFMutableString string];
	append = [ret methodForSelector: @selector(appendString:)];

	pool = [[OFAutoreleasePool alloc] init];
	cArray = [self cArray];

	pool2 = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count - 1; i++) {
		append(ret, @selector(appendString:), [cArray[i] description]);
		append(ret, @selector(appendString:), separator);

		[pool2 releaseObjects];
	}
	append(ret, @selector(appendString:), [cArray[i] description]);

	[ret makeImmutable];

	[pool release];

	return ret;
}

- (BOOL)isEqual: (id)object
{
	/* FIXME: Optimize (for example, buffer of 16 for each) */
	OFArray *otherArray;
	size_t i, count;

	if (![object isKindOfClass: [OFArray class]])
		return NO;

	otherArray = object;

	count = [self count];

	if (count != [otherArray count])
		return NO;

	for (i = 0; i < count; i++)
		if (![[self objectAtIndex: i] isEqual:
		    [otherArray objectAtIndex: i]])
			return NO;

	return YES;
}

- (uint32_t)hash
{
	id *cArray = [self cArray];
	size_t i, count = [self count];
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

	if ([self count] == 0)
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

	[ret makeImmutable];
	[ret autorelease];

	return ret;
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFAutoreleasePool *pool2;
	OFXMLElement *element;
	id <OFSerialization> *cArray = [self cArray];
	size_t i, count = [self count];

	if ([self isKindOfClass: [OFMutableArray class]])
		element = [OFXMLElement elementWithName: @"OFMutableArray"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFArray"
					      namespace: OF_SERIALIZATION_NS];

	pool2 = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count; i++) {
		[element addChild: [cArray[i] XMLElementBySerializing]];

		[pool2 releaseObjects];
	}

	[element retain];
	@try {
		[pool release];
	} @finally {
		[element autorelease];
	}

	return element;
}

- (void)makeObjectsPerformSelector: (SEL)selector
{
	id *cArray = [self cArray];
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		((void(*)(id, SEL))[cArray[i]
		    methodForSelector: selector])(cArray[i], selector);
}

- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (id)object
{
	id *cArray = [self cArray];
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		((void(*)(id, SEL, id))[cArray[i]
		    methodForSelector: selector])(cArray[i], selector, object);
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	/* FIXME: Use -[getObjects:inRange:] on the passed objects */
	size_t count = [self count];

	if (count > INT_MAX)
		@throw [OFOutOfRangeException newWithClass: isa];

	if (state->state >= count)
		return 0;

	state->state = count;
	state->itemsPtr = [self cArray];
	state->mutationsPtr = (unsigned long*)self;

	return (int)count;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFArrayEnumerator alloc] initWithArray: self
					    mutationsPtr: NULL] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	size_t i, count = [self count];
	BOOL stop = NO;

	for (i = 0; i < count && !stop; i++)
		block([self objectAtIndex: i], i, &stop);
}

- (OFArray*)mappedArrayUsingBlock: (of_array_map_block_t)block
{
	OFArray *ret;
	size_t count = [self count];
	id *tmp = [self allocMemoryForNItems: count
				    withSize: sizeof(id)];

	@try {
		[self enumerateObjectsUsingBlock: ^ (id object, size_t index,
		    BOOL *stop) {
			tmp[index] = block(object, index);
		}];

		ret = [OFArray arrayWithCArray: tmp
					length: count];
	} @finally {
		[self freeMemory: tmp];
	}

	return ret;
}

- (OFArray*)filteredArrayUsingBlock: (of_array_filter_block_t)block
{
	OFArray *ret;
	size_t count = [self count];
	id *tmp = [self allocMemoryForNItems: count
				    withSize: sizeof(id)];

	@try {
		__block size_t i = 0;

		[self enumerateObjectsUsingBlock: ^ (id object, size_t index,
		    BOOL *stop) {
			if (block(object, index))
				tmp[i++] = object;
		}];

		ret = [OFArray arrayWithCArray: tmp
					length: i];
	} @finally {
		[self freeMemory: tmp];
	}

	return ret;
}

- (id)foldUsingBlock: (of_array_fold_block_t)block
{
	size_t count = [self count];
	__block id current;

	if (count == 0)
		return nil;
	if (count == 1)
		return [[[self firstObject] retain] autorelease];

	[self enumerateObjectsUsingBlock: ^ (id object, size_t index,
	    BOOL *stop) {
		id new;

		if (index == 0) {
			current = [object retain];
			return;
		}

		@try {
			new = [block(current, object) retain];
		} @finally {
			[current release];
		}
		current = new;
	}];

	return [current autorelease];
}
#endif
@end

@implementation OFArrayEnumerator
- initWithArray: (OFArray*)array_
   mutationsPtr: (unsigned long*)mutationsPtr_
{
	self = [super init];

	array = [array_ retain];
	count = [array count];
	mutations = (mutationsPtr_ != NULL ? *mutationsPtr_ : 0);
	mutationsPtr = mutationsPtr_;

	return self;
}

- (void)dealloc
{
	[array release];

	[super dealloc];
}

- (id)nextObject
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa
							     object: array];

	if (position < count)
		return [array objectAtIndex: position++];

	return nil;
}

- (void)reset
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException newWithClass: isa
							     object: array];

	position = 0;
}
@end
