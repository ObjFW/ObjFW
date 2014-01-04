/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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
#include <stdlib.h>

#include <assert.h>

#import "OFArray.h"
#import "OFArray_subarray.h"
#import "OFArray_adjacent.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFDataArray.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
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
	OF_UNRECOGNIZED_SELECTOR

	/* Get rid of a stupid warning */
	[super dealloc];
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
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- initWithObject: (id)object
{
	if (object == nil) {
		[self release];
		@throw [OFInvalidArgumentException exception];
	}

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
	OF_INVALID_INIT_METHOD
}

- initWithArray: (OFArray*)array
{
	OF_INVALID_INIT_METHOD
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	OF_INVALID_INIT_METHOD
}

- initWithSerialization: (OFXMLElement*)element
{
	OF_INVALID_INIT_METHOD
}

- (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
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
	OF_UNRECOGNIZED_SELECTOR
}

- (id)objectAtIndexedSubscript: (size_t)index
{
	return [self objectAtIndex: index];
}

- (size_t)indexOfObject: (id)object
{
	size_t i, count;

	if (object == nil)
		return OF_NOT_FOUND;

	count = [self count];

	for (i = 0; i < count; i++)
		if ([[self objectAtIndex: i] isEqual: object])
			return i;

	return OF_NOT_FOUND;
}

- (size_t)indexOfObjectIdenticalTo: (id)object
{
	size_t i, count;

	if (object == nil)
		return OF_NOT_FOUND;

	count = [self count];

	for (i = 0; i < count; i++)
		if ([self objectAtIndex: i] == object)
			return i;

	return OF_NOT_FOUND;
}

- (bool)containsObject: (id)object
{
	return ([self indexOfObject: object] != OF_NOT_FOUND);
}

- (bool)containsObjectIdenticalTo: (id)object
{
	return ([self indexOfObjectIdenticalTo: object] != OF_NOT_FOUND);
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

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length < [self count])
		@throw [OFOutOfRangeException exception];

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
				usingSelector: @selector(description)
				      options: 0];
}

- (OFString*)componentsJoinedByString: (OFString*)separator
			      options: (int)options
{
	return [self componentsJoinedByString: separator
				usingSelector: @selector(description)
				      options: options];
}

- (OFString*)componentsJoinedByString: (OFString*)separator
			usingSelector: (SEL)selector
{
	return [self componentsJoinedByString: separator
				usingSelector: selector
				      options: 0];
}

- (OFString*)componentsJoinedByString: (OFString*)separator
			usingSelector: (SEL)selector
			      options: (int)options
{
	void *pool;
	OFMutableString *ret;
	id *objects;
	size_t i, count;

	if (separator == nil)
		@throw [OFInvalidArgumentException exception];

	count = [self count];

	if (count == 0)
		return @"";
	if (count == 1)
		return [[self firstObject] performSelector: selector];

	ret = [OFMutableString string];

	pool = objc_autoreleasePoolPush();
	objects = [self objects];

	if (options & OF_ARRAY_SKIP_EMPTY) {
		for (i = 0; i < count; i++) {
			void *pool2 = objc_autoreleasePoolPush();
			OFString *component =
			    [objects[i] performSelector: selector];

			if ([component length] > 0) {
				if ([ret length] > 0)
					[ret appendString: separator];
				[ret appendString: component];
			}

			objc_autoreleasePoolPop(pool2);
		}
	} else {
		for (i = 0; i < count - 1; i++) {
			void *pool2 = objc_autoreleasePoolPush();

			[ret appendString:
			    [objects[i] performSelector: selector]];
			[ret appendString: separator];

			objc_autoreleasePoolPop(pool2);
		}
		[ret appendString: [objects[i] performSelector: selector]];
	}

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)isEqual: (id)object
{
	/* FIXME: Optimize (for example, buffer of 16 for each) */
	OFArray *otherArray;
	size_t i, count;

	if (![object isKindOfClass: [OFArray class]])
		return false;

	otherArray = object;

	count = [self count];

	if (count != [otherArray count])
		return false;

	for (i = 0; i < count; i++)
		if (![[self objectAtIndex: i] isEqual:
		    [otherArray objectAtIndex: i]])
			return false;

	return true;
}

- (uint32_t)hash
{
	id *objects = [self objects];
	size_t i, count = [self count];
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (i = 0; i < count; i++)
		OF_HASH_ADD_HASH(hash, [objects[i] hash]);

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

- (OFDataArray*)messagePackRepresentation
{
	OFDataArray *data;
	size_t i, count;
	void *pool;
	OFEnumerator *enumerator;
	id object;

	data = [OFDataArray dataArray];
	count = [self count];

	if (count <= 15) {
		uint8_t tmp = 0x90 | ((uint8_t)count & 0xF);
		[data addItem: &tmp];
	} else if (count <= UINT16_MAX) {
		uint8_t type = 0xDC;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)count);

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (count <= UINT32_MAX) {
		uint8_t type = 0xDC;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)count);

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	i = 0;
	enumerator = [self objectEnumerator];
	while ((object = [enumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();
		OFDataArray *child;

		i++;

		child = [object messagePackRepresentation];
		[data addItems: [child items]
			 count: [child count]];

		objc_autoreleasePoolPop(pool2);
	}

	assert(i == count);

	objc_autoreleasePoolPop(pool);

	return data;
}

- (void)makeObjectsPerformSelector: (SEL)selector
{
	id *objects = [self objects];
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		[objects[i] performSelector: selector];
}

- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (id)object
{
	id *objects = [self objects];
	size_t i, count = [self count];

	for (i = 0; i < count; i++)
		[objects[i] performSelector: selector
				 withObject: object];
}

- (OFArray*)sortedArray
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new sort];

	[new makeImmutable];

	return new;
}

- (OFArray*)sortedArrayWithOptions: (int)options
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new sortWithOptions: options];

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
			     count: (int)count
{
	of_range_t range = of_range(state->state, count);

	if (range.length > SIZE_MAX - range.location)
		@throw [OFOutOfRangeException exception];

	if (range.location + range.length > [self count])
		range.length = [self count] - range.location;

	[self getObjects: objects
		 inRange: range];

	state->state = range.location + range.length;
	state->itemsPtr = objects;
	state->mutationsPtr = (unsigned long*)self;

	return (int)range.length;
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
	bool stop = false;

	for (id object in self) {
		block(object, i++, &stop);

		if (stop)
			break;
	}
}
#endif

- (OFArray*)arrayByAddingObject: (id)object
{
	OFMutableArray *ret;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	ret = [[self mutableCopy] autorelease];

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
		    bool *stop) {
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
		    bool *stop) {
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
	    bool *stop) {
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
- initWithArray: (OFArray*)array
   mutationsPtr: (unsigned long*)mutationsPtr
{
	self = [super init];

	_array = [array retain];
	_count = [array count];
	_mutations = (mutationsPtr != NULL ? *mutationsPtr : 0);
	_mutationsPtr = mutationsPtr;

	return self;
}

- (void)dealloc
{
	[_array release];

	[super dealloc];
}

- (id)nextObject
{
	if (_mutationsPtr != NULL && *_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithObject: _array];

	if (_position < _count)
		return [_array objectAtIndex: _position++];

	return nil;
}

- (void)reset
{
	if (_mutationsPtr != NULL && *_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithObject: _array];

	_position = 0;
}
@end
