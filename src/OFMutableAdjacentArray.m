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

#include <string.h>

#import "OFMutableAdjacentArray.h"
#import "OFAdjacentArray.h"
#import "OFData.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFMutableAdjacentArray
+ (void)initialize
{
	if (self == [OFMutableAdjacentArray class])
		[self inheritMethodsFromClass: [OFAdjacentArray class]];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	self = [super init];

	@try {
		_array = [[OFMutableData alloc] initWithItemSize: sizeof(id)
							capacity: capacity];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)addObject: (id)object
{
	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	[_array addItem: &object];
	[object retain];

	_mutations++;
}

- (void)insertObject: (id)object
	     atIndex: (size_t)idx
{
	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	@try {
		[_array insertItem: &object
			   atIndex: idx];
	} @catch (OFOutOfRangeException *e) {
		@throw [OFOutOfRangeException exception];
	}
	[object retain];

	_mutations++;
}

- (void)insertObjectsFromArray: (OFArray *)array
		       atIndex: (size_t)idx
{
	id const *objects = array.objects;
	size_t count = array.count;

	@try {
		[_array insertItems: objects
			    atIndex: idx
			      count: count];
	} @catch (OFOutOfRangeException *e) {
		@throw [OFOutOfRangeException exception];
	}

	for (size_t i = 0; i < count; i++)
		[objects[i] retain];

	_mutations++;
}

- (void)replaceObject: (id)oldObject
	   withObject: (id)newObject
{
	id *objects;
	size_t count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	objects = _array.mutableItems;
	count = _array.count;

	for (size_t i = 0; i < count; i++) {
		if ([objects[i] isEqual: oldObject]) {
			[newObject retain];
			[objects[i] release];
			objects[i] = newObject;

			return;
		}
	}
}

- (void)replaceObjectAtIndex: (size_t)idx
		  withObject: (id)object
{
	id *objects;
	id oldObject;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	objects = _array.mutableItems;

	if (idx >= _array.count)
		@throw [OFOutOfRangeException exception];

	oldObject = objects[idx];
	objects[idx] = [object retain];
	[oldObject release];
}

- (void)replaceObjectIdenticalTo: (id)oldObject
		      withObject: (id)newObject
{
	id *objects;
	size_t count;

	if (oldObject == nil || newObject == nil)
		@throw [OFInvalidArgumentException exception];

	objects = _array.mutableItems;
	count = _array.count;

	for (size_t i = 0; i < count; i++) {
		if (objects[i] == oldObject) {
			[newObject retain];
			[objects[i] release];
			objects[i] = newObject;

			return;
		}
	}
}

- (void)removeObject: (id)object
{
	id const *objects;
	size_t count;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	objects = _array.items;
	count = _array.count;

	for (size_t i = 0; i < count; i++) {
		if ([objects[i] isEqual: object]) {
			object = objects[i];

			[_array removeItemAtIndex: i];
			_mutations++;

			[object release];

			return;
		}
	}
}

- (void)removeObjectIdenticalTo: (id)object
{
	id const *objects;
	size_t count;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	objects = _array.items;
	count = _array.count;

	for (size_t i = 0; i < count; i++) {
		if (objects[i] == object) {
			[_array removeItemAtIndex: i];
			_mutations++;

			[object release];

			return;
		}
	}
}

- (void)removeObjectAtIndex: (size_t)idx
{
#ifndef __clang_analyzer__
	id object = [self objectAtIndex: idx];
	[_array removeItemAtIndex: idx];
	[object release];

	_mutations++;
#endif
}

- (void)removeAllObjects
{
	id const *objects = _array.items;
	size_t count = _array.count;

	for (size_t i = 0; i < count; i++)
		[objects[i] release];

	[_array removeAllItems];
}

- (void)removeObjectsInRange: (of_range_t)range
{
	id const *objects = _array.items;
	size_t count = _array.count;
	id *copy;

	if (range.length > SIZE_MAX - range.location ||
	    range.location >= count || range.length > count - range.location)
		@throw [OFOutOfRangeException exception];

	copy = [self allocMemoryWithSize: sizeof(*copy)
				   count: range.length];
	memcpy(copy, objects + range.location, range.length * sizeof(id));

	@try {
		[_array removeItemsInRange: range];
		_mutations++;

		for (size_t i = 0; i < range.length; i++)
			[copy[i] release];
	} @finally {
		[self freeMemory: copy];
	}
}

- (void)removeLastObject
{
#ifndef __clang_analyzer__
	size_t count = _array.count;
	id object;

	if (count == 0)
		return;

	object = [self objectAtIndex: count - 1];
	[_array removeLastItem];
	[object release];

	_mutations++;
#endif
}

- (void)exchangeObjectAtIndex: (size_t)idx1
	    withObjectAtIndex: (size_t)idx2
{
	id *objects = _array.mutableItems;
	size_t count = _array.count;
	id tmp;

	if (idx1 >= count || idx2 >= count)
		@throw [OFOutOfRangeException exception];

	tmp = objects[idx1];
	objects[idx1] = objects[idx2];
	objects[idx2] = tmp;
}

- (void)reverse
{
	id *objects = _array.mutableItems;
	size_t i, j, count = _array.count;

	if (count == 0 || count == 1)
		return;

	for (i = 0, j = count - 1; i < j; i++, j--) {
		id tmp = objects[i];
		objects[i] = objects[j];
		objects[j] = tmp;
	}
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count_
{
	size_t count = _array.count;

	if (count > INT_MAX) {
		/*
		 * Use the implementation from OFArray (OFMutableArray does not
		 * have one), which is slower, but can enumerate in chunks, and
		 * set the mutations pointer.
		 */
		int ret = [super countByEnumeratingWithState: state
						     objects: objects
						       count: count_];
		state->mutationsPtr = &_mutations;
		return ret;
	}

	if (state->state >= count)
		return 0;

	state->state = (unsigned long)count;
	state->itemsPtr = _array.items;
	state->mutationsPtr = &_mutations;

	return (int)count;
}

- (OFEnumerator *)objectEnumerator
{
	return [[[OFArrayEnumerator alloc]
	    initWithArray: self
	     mutationsPtr: &_mutations] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	id const *objects = _array.items;
	size_t count = _array.count;
	bool stop = false;
	unsigned long mutations = _mutations;

	for (size_t i = 0; i < count && !stop; i++) {
		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithObject: self];

		block(objects[i], i, &stop);
	}
}

- (void)replaceObjectsUsingBlock: (of_array_replace_block_t)block
{
	id *objects = _array.mutableItems;
	size_t count = _array.count;
	unsigned long mutations = _mutations;

	for (size_t i = 0; i < count; i++) {
		id new;

		if (_mutations != mutations)
			@throw [OFEnumerationMutationException
			    exceptionWithObject: self];

		new = block(objects[i], i);

		if (new == nil)
			@throw [OFInvalidArgumentException exception];

		if (new != objects[i]) {
			[objects[i] release];
			objects[i] = [new retain];
		}
	}
}
#endif

- (void)makeImmutable
{
	object_setClass(self, [OFAdjacentArray class]);
}
@end
