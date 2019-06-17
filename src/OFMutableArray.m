/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFMutableAdjacentArray.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableArrayPlaceholder: OFMutableArray
@end

static of_comparison_result_t
compare(id left, id right, SEL selector)
{
	of_comparison_result_t (*comparator)(id, SEL, id) =
	    (of_comparison_result_t (*)(id, SEL, id))
	    [left methodForSelector: selector];

	return comparator(left, selector, right);
}

static void
quicksort(OFMutableArray *array, size_t left, size_t right, SEL selector,
    int options)
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
			while (compare([array objectAtIndex: i], pivot,
			    selector) != descending && i < right)
				i++;

			while (compare([array objectAtIndex: j], pivot,
			    selector) != ascending && j > left)
				j--;

			if (i < j)
				[array exchangeObjectAtIndex: i
					   withObjectAtIndex: j];
		} while (i < j);

		if (compare([array objectAtIndex: i], pivot, selector) ==
		    descending)
			[array exchangeObjectAtIndex: i
				   withObjectAtIndex: right];

		if (i > 0)
			quicksort(array, left, i - 1, selector, options);

		left = i + 1;
	}
}

#ifdef OF_HAVE_BLOCKS
static void
quicksortWithBlock(OFMutableArray *array, size_t left, size_t right,
    of_comparator_t comparator, int options)
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
			while (comparator([array objectAtIndex: i], pivot) !=
			    descending && i < right)
				i++;

			while (comparator([array objectAtIndex: j], pivot) !=
			    ascending && j > left)
				j--;

			if (i < j)
				[array exchangeObjectAtIndex: i
					   withObjectAtIndex: j];
		} while (i < j);

		if (comparator([array objectAtIndex: i], pivot) == descending)
			[array exchangeObjectAtIndex: i
				   withObjectAtIndex: right];

		if (i > 0)
			quicksortWithBlock(array, left, i - 1, comparator,
			    options);

		left = i + 1;
	}
}
#endif

@implementation OFMutableArrayPlaceholder
- (instancetype)init
{
	return (id)[[OFMutableAdjacentArray alloc] init];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	return (id)[[OFMutableAdjacentArray alloc] initWithCapacity: capacity];
}

- (instancetype)initWithObject: (id)object
{
	return (id)[[OFMutableAdjacentArray alloc] initWithObject: object];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFMutableAdjacentArray alloc] initWithObject: firstObject
						   arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	return (id)[[OFMutableAdjacentArray alloc] initWithObject: firstObject
							arguments: arguments];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFMutableAdjacentArray alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	return (id)[[OFMutableAdjacentArray alloc] initWithObjects: objects
							     count: count];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFMutableAdjacentArray alloc]
	    initWithSerialization: element];
}

- (instancetype)retain
{
	return self;
}

- (instancetype)autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	OF_DEALLOC_UNSUPPORTED
}
@end

@implementation OFMutableArray
+ (void)initialize
{
	if (self == [OFMutableArray class])
		placeholder.isa = [OFMutableArrayPlaceholder class];
}

+ (instancetype)alloc
{
	if (self == [OFMutableArray class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)arrayWithCapacity: (size_t)capacity
{
	return [[[self alloc] initWithCapacity: capacity] autorelease];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFMutableArray class]]) {
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

- (instancetype)initWithCapacity: (size_t)capacity
{
	OF_INVALID_INIT_METHOD
}

- (id)copy
{
	return [[OFArray alloc] initWithArray: self];
}

- (void)addObject: (id)object
{
	[self insertObject: object
		   atIndex: self.count];
}

- (void)addObjectsFromArray: (OFArray *)array
{
	[self insertObjectsFromArray: array
			     atIndex: self.count];
}

- (void)insertObject: (id)object
	     atIndex: (size_t)idx
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)insertObjectsFromArray: (OFArray *)array
		       atIndex: (size_t)idx
{
	size_t i = 0;

	for (id object in array)
		[self insertObject: object
			   atIndex: idx + i++];
}

- (void)replaceObjectAtIndex: (size_t)idx
		  withObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

-    (void)setObject: (id)object
  atIndexedSubscript: (size_t)idx
{
	[self replaceObjectAtIndex: idx
			withObject: object];
}

- (void)replaceObject: (id)oldObject
	   withObject: (id)newObject
{
	size_t count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	count = self.count;

	for (size_t i = 0; i < count; i++) {
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
	size_t count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	count = self.count;

	for (size_t i = 0; i < count; i++) {
		if ([self objectAtIndex: i] == oldObject) {
			[self replaceObjectAtIndex: i
					withObject: newObject];

			return;
		}
	}
}

- (void)removeObjectAtIndex: (size_t)idx
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeObject: (id)object
{
	size_t count;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	count = self.count;

	for (size_t i = 0; i < count; i++) {
		if ([[self objectAtIndex: i] isEqual: object]) {
			[self removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeObjectIdenticalTo: (id)object
{
	size_t count;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	count = self.count;

	for (size_t i = 0; i < count; i++) {
		if ([self objectAtIndex: i] == object) {
			[self removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeObjectsInRange: (of_range_t)range
{
	for (size_t i = 0; i < range.length; i++)
		[self removeObjectAtIndex: range.location];
}

- (void)removeLastObject
{
	size_t count = self.count;

	if (count == 0)
		return;

	[self removeObjectAtIndex: count - 1];
}

- (void)removeAllObjects
{
	[self removeObjectsInRange: of_range(0, self.count)];
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (of_array_replace_block_t)block
{
	[self enumerateObjectsUsingBlock: ^ (id object, size_t idx,
	    bool *stop) {
		id new = block(object, idx);

		if (new != object)
			[self replaceObjectAtIndex: idx
					withObject: new];
	}];
}
#endif

- (void)exchangeObjectAtIndex: (size_t)idx1
	    withObjectAtIndex: (size_t)idx2
{
	id object1 = [self objectAtIndex: idx1];
	id object2 = [self objectAtIndex: idx2];

	[object1 retain];
	@try {
		[self replaceObjectAtIndex: idx1
				withObject: object2];
		[self replaceObjectAtIndex: idx2
				withObject: object1];
	} @finally {
		[object1 release];
	}
}

- (void)sort
{
	[self sortUsingSelector: @selector(compare:)
			options: 0];
}

- (void)sortUsingSelector: (SEL)selector
		  options: (int)options
{
	size_t count = self.count;

	if (count == 0 || count == 1)
		return;

	quicksort(self, 0, count - 1, selector, options);
}

#ifdef OF_HAVE_BLOCKS
- (void)sortUsingComparator: (of_comparator_t)comparator
		    options: (int)options
{
	size_t count = self.count;

	if (count == 0 || count == 1)
		return;

	quicksortWithBlock(self, 0, count - 1, comparator, options);
}
#endif

- (void)reverse
{
	size_t i, j, count = self.count;

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
