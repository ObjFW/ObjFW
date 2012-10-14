/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
#import "OFArray_subarray.h"
#import "OFArray_adjacent.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#import "autorelease.h"
#import "macros.h"

static struct {
	Class isa;
} placeholder;

@interface OFArray_placeholder: OFArray
@end

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

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	return (id)[[OFArray_adjacent alloc] initWithObjects: objects
						       count: count];
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
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}
@end

@implementation OFArray
+ (void)initialize
{
	if (self == [OFArray class])
		object_setClass((id)&placeholder, [OFArray_placeholder class]);
}

+ alloc
{
	if (self == [OFArray class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)array
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)arrayWithObject: (id)object
{
	return [[[self alloc] initWithObject: object] autorelease];
}

+ (instancetype)arrayWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[[self alloc] initWithObject: firstObject
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ (instancetype)arrayWithArray: (OFArray*)array
{
	return [[[self alloc] initWithArray: array] autorelease];
}

+ (instancetype)arrayWithObjects: (id const*)objects
			   count: (size_t)count
{
	return [[[self alloc] initWithObjects: objects
					count: count] autorelease];
}

- init
{
	if (object_getClass(self) == [OFArray class]) {
		Class c = [self class];
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
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
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithArray: (OFArray*)array
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithSerialization: (OFXMLElement*)element
{
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- (size_t)count
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (void)getObjects: (id*)buffer
	   inRange: (of_range_t)range
{
	size_t i;

	for (i = 0; i < range.length; i++)
		buffer[i] = [self objectAtIndex: range.location + i];
}

- (id*)objects
{
	OFObject *container;
	size_t count;
	id *buffer;

	container = [[[OFObject alloc] init] autorelease];
	count = [self count];
	buffer = [container allocMemoryWithSize: sizeof(*buffer)
					  count: [self count]];

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
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- (id)objectAtIndexedSubscript: (size_t)index
{
	return [self objectAtIndex: index];
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
	id *buffer;

	if (![self isKindOfClass: [OFMutableArray class]])
		return [OFArray_subarray arrayWithArray: self
						  range: range];

	buffer = [self allocMemoryWithSize: sizeof(*buffer)
				     count: range.length];

	@try {
		[self getObjects: buffer
			 inRange: range];

		ret = [OFArray arrayWithObjects: buffer
					  count: range.length];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString*)componentsJoinedByString: (OFString*)separator
{
	return [self componentsJoinedByString: separator
				usingSelector: @selector(description)];
}

- (OFString*)componentsJoinedByString: (OFString*)separator
			usingSelector: (SEL)selector
{
	void *pool;
	OFMutableString *ret;
	id *objects;
	size_t i, count = [self count];
	IMP append;

	if (count == 0)
		return @"";
	if (count == 1)
		return [[self firstObject] performSelector: selector];

	ret = [OFMutableString string];
	append = [ret methodForSelector: @selector(appendString:)];

	pool = objc_autoreleasePoolPush();
	objects = [self objects];

	for (i = 0; i < count - 1; i++) {
		void *pool2 = objc_autoreleasePoolPush();

		append(ret, @selector(appendString:),
		    [objects[i] performSelector: selector]);
		append(ret, @selector(appendString:), separator);

		objc_autoreleasePoolPop(pool2);
	}
	append(ret, @selector(appendString:),
	    [objects[i] performSelector: selector]);

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

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
	id *objects = [self objects];
	size_t i, count = [self count];
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < count; i++) {
		uint32_t h = [objects[i] hash];

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
	void *pool;
	OFMutableString *ret;

	if ([self count] == 0)
		return @"()";

	pool = objc_autoreleasePoolPush();
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

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return [ret autorelease];
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;
	id <OFSerialization> *objects = [self objects];
	size_t i, count = [self count];

	if ([self isKindOfClass: [OFMutableArray class]])
		element = [OFXMLElement elementWithName: @"OFMutableArray"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFArray"
					      namespace: OF_SERIALIZATION_NS];

	for (i = 0; i < count; i++) {
		void *pool2 = objc_autoreleasePoolPush();

		[element addChild: [objects[i] XMLElementBySerializing]];

		objc_autoreleasePoolPop(pool2);
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFString*)JSONRepresentation
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableString *JSON;

	JSON = [[self componentsJoinedByString: @","
				 usingSelector: @selector(JSONRepresentation)]
	    mutableCopy];

	[JSON prependString: @"["];
	[JSON appendString: @"]"];

	[JSON makeImmutable];

	objc_autoreleasePoolPop(pool);

	return [JSON autorelease];
}

- (void)makeObjectsPerformSelector: (SEL)selector
{
	id *objects = [self objects];
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		((void(*)(id, SEL))[objects[i]
		    methodForSelector: selector])(objects[i], selector);
}

- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (id)object
{
	id *objects = [self objects];
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		((void(*)(id, SEL, id))[objects[i]
		    methodForSelector: selector])(objects[i], selector, object);
}

- (OFArray*)sortedArray
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new sort];

	[new makeImmutable];

	return new;
}

- (OFArray*)reversedArray
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new reverse];

	[new makeImmutable];

	return new;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	/* FIXME: Use -[getObjects:inRange:] on the passed objects */
	size_t count = [self count];

	if (count > INT_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	if (state->state >= count)
		return 0;

	state->state = count;
	state->itemsPtr = [self objects];
	state->mutationsPtr = (unsigned long*)self;

	return (int)count;
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFArrayEnumerator alloc] initWithArray: self
					    mutationsPtr: NULL] autorelease];
}

#if defined(OF_HAVE_BLOCKS) && defined(OF_HAVE_FAST_ENUMERATION)
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	size_t i = 0;
	BOOL stop = NO;

	for (id object in self) {
		block(object, i++, &stop);

		if (stop)
			break;
	}
}
#endif

- (OFArray*)arrayByAddingObject: (id)object
{
	OFMutableArray *ret = [[self mutableCopy] autorelease];

	[ret addObject: object];
	[ret makeImmutable];

	return ret;
}

- (OFArray*)arrayByAddingObjectsFromArray: (OFArray*)array
{
	OFMutableArray *ret = [[self mutableCopy] autorelease];

	[ret addObjectsFromArray: array];
	[ret makeImmutable];

	return ret;
}

- (OFArray*)arrayByRemovingObject: (id)object
{
	OFMutableArray *ret = [[self mutableCopy] autorelease];

	[ret removeObject: object];
	[ret makeImmutable];

	return ret;
}

#ifdef OF_HAVE_BLOCKS
- (OFArray*)mappedArrayUsingBlock: (of_array_map_block_t)block
{
	OFArray *ret;
	size_t count = [self count];
	id *tmp = [self allocMemoryWithSize: sizeof(id)
				      count: count];

	@try {
		[self enumerateObjectsUsingBlock: ^ (id object, size_t index,
		    BOOL *stop) {
			tmp[index] = block(object, index);
		}];

		ret = [OFArray arrayWithObjects: tmp
					  count: count];
	} @finally {
		[self freeMemory: tmp];
	}

	return ret;
}

- (OFArray*)filteredArrayUsingBlock: (of_array_filter_block_t)block
{
	OFArray *ret;
	size_t count = [self count];
	id *tmp = [self allocMemoryWithSize: sizeof(id)
				      count: count];

	@try {
		__block size_t i = 0;

		[self enumerateObjectsUsingBlock: ^ (id object, size_t index,
		    BOOL *stop) {
			if (block(object, index))
				tmp[i++] = object;
		}];

		ret = [OFArray arrayWithObjects: tmp
					  count: i];
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
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [self class]
				object: array];

	if (position < count)
		return [array objectAtIndex: position++];

	return nil;
}

- (void)reset
{
	if (mutationsPtr != NULL && *mutationsPtr != mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [self class]
				object: array];

	position = 0;
}
@end
