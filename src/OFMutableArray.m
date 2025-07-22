/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <stdlib.h>
#include <string.h>

#import "OFMutableArray.h"
#import "OFConcreteMutableArray.h"
#import "OFData.h"
#import "OFIndexSet.h"
#import "OFIndexSet+Private.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

static struct {
	Class isa;
} placeholder;

@interface OFPlaceholderMutableArray: OFMutableArray
@end

static void
quicksort(OFMutableArray *array, size_t left, size_t right,
    OFCompareFunction compare, void *context, OFArraySortOptions options)
{
	OFComparisonResult ascending, descending;

	if (options & OFArraySortDescending) {
		ascending = OFOrderedDescending;
		descending = OFOrderedAscending;
	} else {
		ascending = OFOrderedAscending;
		descending = OFOrderedDescending;
	}

	while (left < right) {
		size_t i = left;
		size_t j = right - 1;
		id pivot = [array objectAtIndex: right];

		do {
			while (compare([array objectAtIndex: i], pivot,
			    context) != descending && i < right)
				i++;

			while (compare([array objectAtIndex: j], pivot,
			    context) != ascending && j > left)
				j--;

			if (i < j)
				[array exchangeObjectAtIndex: i
					   withObjectAtIndex: j];
		} while (i < j);

		if (compare([array objectAtIndex: i], pivot, context) ==
		    descending)
			[array exchangeObjectAtIndex: i
				   withObjectAtIndex: right];

		if (i > 0)
			quicksort(array, left, i - 1, compare, context,
			    options);

		left = i + 1;
	}
}

@implementation OFPlaceholderMutableArray
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)init
{
	return (id)[[OFConcreteMutableArray alloc] init];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	return (id)[[OFConcreteMutableArray alloc] initWithCapacity: capacity];
}

- (instancetype)initWithObject: (id)object
{
	return (id)[[OFConcreteMutableArray alloc] initWithObject: object];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFConcreteMutableArray alloc] initWithObject: firstObject
						   arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	return (id)[[OFConcreteMutableArray alloc] initWithObject: firstObject
							arguments: arguments];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFConcreteMutableArray alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	return (id)[[OFConcreteMutableArray alloc] initWithObjects: objects
							     count: count];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFMutableArray
+ (void)initialize
{
	if (self == [OFMutableArray class])
		object_setClass((id)&placeholder,
		    [OFPlaceholderMutableArray class]);
}

+ (instancetype)alloc
{
	if (self == [OFMutableArray class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)arrayWithCapacity: (size_t)capacity
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithCapacity: capacity]);
}

- (instancetype)init
{
	return [super init];
}

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (id)copy
{
	return [[OFArray alloc] initWithArray: self];
}

- (void)addObject: (id)object
{
	[self insertObject: object atIndex: self.count];
}

- (void)addObjectsFromArray: (OFArray *)array
{
	[self insertObjectsFromArray: array atIndex: self.count];
}

- (void)insertObject: (id)object atIndex: (size_t)idx
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)insertObjectsFromArray: (OFArray *)array atIndex: (size_t)idx
{
	size_t i = 0;

	for (id object in array)
		[self insertObject: object atIndex: idx + i++];
}

- (void)insertObjects: (OFArray *)array atIndexes: (OFIndexSet *)indexes
{
	void *pool = objc_autoreleasePoolPush();
	const OFRange *ranges = indexes.of_ranges.items;
	size_t count = indexes.of_ranges.count;
	size_t arrayIndex = 0;

	for (size_t i = 0; i < count; i++) {
		void *pool2 = objc_autoreleasePoolPush();
		OFArray *objects = [array objectsInRange:
		    OFMakeRange(arrayIndex, ranges[i].length)];

		[self insertObjectsFromArray: objects
				     atIndex: ranges[i].location];

		arrayIndex += ranges[i].length;

		objc_autoreleasePoolPop(pool2);
	}

	objc_autoreleasePoolPop(pool);
}

- (void)replaceObjectAtIndex: (size_t)idx withObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setObject: (id)object atIndexedSubscript: (size_t)idx
{
	[self replaceObjectAtIndex: idx withObject: object];
}

- (void)replaceObject: (id)oldObject withObject: (id)newObject
{
	size_t count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	count = self.count;

	for (size_t i = 0; i < count; i++)
		if ([[self objectAtIndex: i] isEqual: oldObject])
			[self replaceObjectAtIndex: i withObject: newObject];
}

- (void)replaceObjectIdenticalTo: (id)oldObject withObject: (id)newObject
{
	size_t count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	count = self.count;

	for (size_t i = 0; i < count; i++)
		if ([self objectAtIndex: i] == oldObject)
			[self replaceObjectAtIndex: i withObject: newObject];
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

			i--;
			count--;
			continue;
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

			i--;
			count--;
			continue;
		}
	}
}

- (void)removeObjectsInRange: (OFRange)range
{
	for (size_t i = 0; i < range.length; i++)
		[self removeObjectAtIndex: range.location];
}

- (void)removeObjectsAtIndexes: (OFIndexSet *)indexes
{
	void *pool = objc_autoreleasePoolPush();
	const OFRange *ranges = indexes.of_ranges.items;
	size_t count = indexes.of_ranges.count;

	if (count == 0) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	for (size_t i = count; i > 0; i--)
		[self removeObjectsInRange: ranges[i - 1]];

	objc_autoreleasePoolPop(pool);
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
	[self removeObjectsInRange: OFMakeRange(0, self.count)];
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (OFArrayReplaceBlock)block
{
	[self enumerateObjectsUsingBlock: ^ (id object, size_t idx,
	    bool *stop) {
		id new = block(object, idx);

		if (new != object)
			[self replaceObjectAtIndex: idx withObject: new];
	}];
}
#endif

- (void)exchangeObjectAtIndex: (size_t)idx1 withObjectAtIndex: (size_t)idx2
{
	id object1 = [self objectAtIndex: idx1];
	id object2 = [self objectAtIndex: idx2];

	objc_retain(object1);
	@try {
		[self replaceObjectAtIndex: idx1 withObject: object2];
		[self replaceObjectAtIndex: idx2 withObject: object1];
	} @finally {
		objc_release(object1);
	}
}

- (void)sort
{
	[self sortUsingSelector: @selector(compare:) options: 0];
}

static OFComparisonResult
selectorCompare(id left, id right, void *context)
{
	SEL selector = context;
	OFComparisonResult (*comparator)(id, SEL, id) =
	    (OFComparisonResult (*)(id, SEL, id))
	    [left methodForSelector: selector];

	return comparator(left, selector, right);
}

- (void)sortUsingSelector: (SEL)selector
		  options: (OFArraySortOptions)options
{
	size_t count = self.count;

	if (count == 0 || count == 1)
		return;

	quicksort(self, 0, count - 1, selectorCompare, (void *)selector,
	    options);
}

- (void)sortUsingFunction: (OFCompareFunction)compare
		  context: (void *)context
		  options: (OFArraySortOptions)options
{
	size_t count = self.count;

	if (count == 0 || count == 1)
		return;

	quicksort(self, 0, count - 1, compare, context, options);
}

#ifdef OF_HAVE_BLOCKS
static OFComparisonResult
blockCompare(id left, id right, void *context)
{
	OFComparator block = (OFComparator)context;

	return block(left, right);
}

- (void)sortUsingComparator: (OFComparator)comparator
		    options: (OFArraySortOptions)options
{
	size_t count = self.count;

	if (count == 0 || count == 1)
		return;

	quicksort(self, 0, count - 1, blockCompare, comparator, options);
}
#endif

- (void)reverse
{
	size_t i, j, count = self.count;

	if (count == 0 || count == 1)
		return;

	for (i = 0, j = count - 1; i < j; i++, j--)
		[self exchangeObjectAtIndex: i withObjectAtIndex: j];
}

- (void)makeImmutable
{
}
@end
