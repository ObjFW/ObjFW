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

#include <string.h>

#import "OFMutableArray.h"
#import "OFMutableArray_adjacent.h"
#import "OFAutoreleasePool.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"

#import "macros.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableArray_placeholder: OFMutableArray
@end

static void
quicksort(OFMutableArray *array, size_t left, size_t right)
{
	size_t i, j;
	id pivot;

	if (left >= right)
		return;

	i = left;
	j = right - 1;
	pivot = [array objectAtIndex: right];

	do {
		while ([[array objectAtIndex: i] compare: pivot] !=
		    OF_ORDERED_DESCENDING && i < right)
			i++;

		while ([[array objectAtIndex: j] compare: pivot] !=
		    OF_ORDERED_ASCENDING && j > left)
			j--;

		if (i < j)
			[array swapObjectAtIndex: i
			       withObjectAtIndex: j];
	} while (i < j);

	if ([[array objectAtIndex: i] compare: pivot] == OF_ORDERED_DESCENDING)
		[array swapObjectAtIndex: i
		       withObjectAtIndex: right];

	if (i > 0)
		quicksort(array, left, i - 1);
	quicksort(array, i + 1, right);
}

@implementation OFMutableArray_placeholder
- init
{
	return (id)[[OFMutableArray_adjacent alloc] init];
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

- initWithCArray: (id*)objects
{
	return (id)[[OFMutableArray_adjacent alloc] initWithCArray: objects];
}

- initWithCArray: (id*)objects
	  length: (size_t)length
{
	return (id)[[OFMutableArray_adjacent alloc] initWithCArray: objects
							    length: length];
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
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
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

- init
{
	if (isa == [OFMutableArray class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
							    selector: _cmd];
	}

	return [super init];
}

- copy
{
	return [[OFArray alloc] initWithArray: self];
}

- (void)addObject: (id)object
{
	[self addObject: object
		atIndex: [self count]];
}

- (void)addObject: (id)object
	  atIndex: (size_t)index
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)replaceObjectAtIndex: (size_t)index
		  withObject: (id)object
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)replaceObject: (id)oldObject
	   withObject: (id)newObject
{
	size_t i, count = [self count];

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
	size_t i, count = [self count];

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
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (void)removeObject: (id)object
{
	size_t i, count = [self count];

	for (i = 0; i < count; i++) {
		if ([[self objectAtIndex: i] isEqual: object]) {
			[self removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeObjectIdenticalTo: (id)object
{
	size_t i, count = [self count];

	for (i = 0; i < count; i++) {
		if ([self objectAtIndex: i] == object) {
			[self removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeNObjects: (size_t)nObjects
{
	size_t count = [self count];

	[self removeObjectsInRange: of_range(count - nObjects, nObjects)];
}

- (void)removeObjectsInRange: (of_range_t)range
{
	size_t i;

	for (i = 0; i < range.length; i++)
		[self removeObjectAtIndex: range.start];
}

- (void)removeLastObject
{
	[self removeNObjects: 1];
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (of_array_replace_block_t)block
{
	[self enumerateObjectsUsingBlock: ^ (id object, size_t index,
	    BOOL *stop) {
		[self replaceObjectAtIndex: index
				withObject: block(object, index, stop)];
	}];
}
#endif

- (void)swapObjectAtIndex: (size_t)index1
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
	size_t count = [self count];

	if (count == 0 || count == 1)
		return;

	quicksort(self, 0, count - 1);
}

- (void)reverse
{
	size_t i, j, count = [self count];

	if (count == 0 || count == 1)
		return;

	for (i = 0, j = count - 1; i < j; i++, j--)
		[self swapObjectAtIndex: i
		      withObjectAtIndex: j];
}

- (void)makeImmutable
{
}
@end
