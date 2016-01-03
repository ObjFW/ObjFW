/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

#include <stdlib.h>
#include <string.h>

#include <assert.h>

#import "OFMutableArray.h"
#import "OFMutableArray_adjacent.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableArray_placeholder: OFMutableArray
@end

static void
quicksort(OFMutableArray *array, size_t left, size_t right, int options)
{
	of_comparison_result_t ascending, descending;

	if (options & OF_ARRAY_SORT_DESCENDING) {
		ascending = OF_ORDERED_DESCENDING;
		descending = OF_ORDERED_ASCENDING;
	} else {
		ascending = OF_ORDERED_ASCENDING;
		descending = OF_ORDERED_DESCENDING;
	}

	while (left < right) {
		size_t i = left;
		size_t j = right - 1;
		id pivot = [array objectAtIndex: right];

		do {
			while ([[array objectAtIndex: i] compare: pivot] !=
			    descending && i < right)
				i++;

			while ([[array objectAtIndex: j] compare: pivot] !=
			    ascending && j > left)
				j--;

			if (i < j)
				[array exchangeObjectAtIndex: i
					   withObjectAtIndex: j];
		} while (i < j);

		if ([[array objectAtIndex: i] compare: pivot] == descending)
			[array exchangeObjectAtIndex: i
				   withObjectAtIndex: right];

		if (i > 0)
			quicksort(array, left, i - 1, options);

		left = i + 1;
	}
}

@implementation OFMutableArray_placeholder
- init
{
	return (id)[[OFMutableArray_adjacent alloc] init];
}

- initWithCapacity: (size_t)capacity
{
	return (id)[[OFMutableArray_adjacent alloc] initWithCapacity: capacity];
}

- initWithObject: (id)object
{
	return (id)[[OFMutableArray_adjacent alloc] initWithObject: object];
}

- initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFMutableArray_adjacent alloc] initWithObject: firstObject
						    arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	return (id)[[OFMutableArray_adjacent alloc] initWithObject: firstObject
							 arguments: arguments];
}

- initWithArray: (OFArray*)array
{
	return (id)[[OFMutableArray_adjacent alloc] initWithArray: array];
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	return (id)[[OFMutableArray_adjacent alloc] initWithObjects: objects
							      count: count];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFMutableArray_adjacent alloc]
	    initWithSerialization: element];
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

@implementation OFMutableArray
+ (void)initialize
{
	if (self == [OFMutableArray class])
		placeholder.isa = [OFMutableArray_placeholder class];
}

+ alloc
{
	if (self == [OFMutableArray class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)arrayWithCapacity: (size_t)capacity
{
	return [[[self alloc] initWithCapacity: capacity] autorelease];
}

- init
{
	if (object_getClass(self) == [OFMutableArray class]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	return [super init];
}

- initWithCapacity: (size_t)capacity
{
	OF_INVALID_INIT_METHOD
}

- copy
{
	return [[OFArray alloc] initWithArray: self];
}

- (void)addObject: (id)object
{
	[self insertObject: object
		   atIndex: [self count]];
}

- (void)addObjectsFromArray: (OFArray*)array
{
	[self insertObjectsFromArray: array
			     atIndex: [self count]];
}

- (void)insertObject: (id)object
	     atIndex: (size_t)index
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)insertObjectsFromArray: (OFArray*)array
		       atIndex: (size_t)index
{
	size_t i = 0;

	for (id object in array)
		[self insertObject: object
			   atIndex: index + i++];
}

- (void)replaceObjectAtIndex: (size_t)index
		  withObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

-    (void)setObject: (id)object
  atIndexedSubscript: (size_t)index
{
	[self replaceObjectAtIndex: index
			withObject: object];
}

- (void)replaceObject: (id)oldObject
	   withObject: (id)newObject
{
	size_t i, count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	count = [self count];

	for (i = 0; i < count; i++) {
		if ([[self objectAtIndex: i] isEqual: oldObject]) {
			[self replaceObjectAtIndex: i
					withObject: newObject];
			return;
		}
	}
}

- (void)replaceObjectIdenticalTo: (id)oldObject
		      withObject: (id)newObject
{
	size_t i, count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	count = [self count];

	for (i = 0; i < count; i++) {
		if ([self objectAtIndex: i] == oldObject) {
			[self replaceObjectAtIndex: i
					withObject: newObject];

			return;
		}
	}
}

- (void)removeObjectAtIndex: (size_t)index
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeObject: (id)object
{
	size_t i, count;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	count = [self count];

	for (i = 0; i < count; i++) {
		if ([[self objectAtIndex: i] isEqual: object]) {
			[self removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeObjectIdenticalTo: (id)object
{
	size_t i, count;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	count = [self count];

	for (i = 0; i < count; i++) {
		if ([self objectAtIndex: i] == object) {
			[self removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeObjectsInRange: (of_range_t)range
{
	size_t i;

	for (i = 0; i < range.length; i++)
		[self removeObjectAtIndex: range.location];
}

- (void)removeLastObject
{
	size_t count = [self count];

	if (count == 0)
		return;

	[self removeObjectAtIndex: count - 1];
}

- (void)removeAllObjects
{
	[self removeObjectsInRange: of_range(0, [self count])];
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (of_array_replace_block_t)block
{
	[self enumerateObjectsUsingBlock: ^ (id object, size_t index,
	    bool *stop) {
		id new = block(object, index);

		if (new != object)
			[self replaceObjectAtIndex: index
					withObject: new];
	}];
}
#endif

- (void)exchangeObjectAtIndex: (size_t)index1
	    withObjectAtIndex: (size_t)index2
{
	id object1 = [self objectAtIndex: index1];
	id object2 = [self objectAtIndex: index2];

	[object1 retain];
	@try {
		[self replaceObjectAtIndex: index1
				withObject: object2];
		[self replaceObjectAtIndex: index2
				withObject: object1];
	} @finally {
		[object1 release];
	}
}

- (void)sort
{
	[self sortWithOptions: 0];
}

- (void)sortWithOptions: (int)options
{
	size_t count = [self count];

	if (count == 0 || count == 1)
		return;

	quicksort(self, 0, count - 1, options);
}

- (void)reverse
{
	size_t i, j, count = [self count];

	if (count == 0 || count == 1)
		return;

	for (i = 0, j = count - 1; i < j; i++, j--)
		[self exchangeObjectAtIndex: i
			  withObjectAtIndex: j];
}

- (void)makeImmutable
{
}
@end
