/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include <stdarg.h>

#import "OFConcreteArray.h"
#import "OFConcreteMutableArray.h"
#import "OFConcreteSubarray.h"
#import "OFData.h"
#import "OFString.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteArray
- (instancetype)init
{
	self = [super init];

	@try {
		_array = [[OFMutableData alloc] initWithItemSize: sizeof(id)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)object
{
	self = [self init];

	@try {
		if (object == nil)
			@throw [OFInvalidArgumentException exception];

		[_array addItem: &object];
		[object retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	self = [self init];

	@try {
		id object;

		[_array addItem: &firstObject];
		[firstObject retain];

		while ((object = va_arg(arguments, id)) != nil) {
			[_array addItem: &object];
			[object retain];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithArray: (OFArray *)array
{
	id const *objects;
	size_t count;

	self = [super init];

	if (array == nil)
		return self;

	@try {
		objects = array.objects;
		count = array.count;

		_array = [[OFMutableData alloc] initWithItemSize: sizeof(id)
							capacity: count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	@try {
		for (size_t i = 0; i < count; i++)
			[objects[i] retain];

		[_array addItems: objects count: count];
	} @catch (id e) {
		for (size_t i = 0; i < count; i++)
			[objects[i] release];

		/* Prevent double-release of objects */
		[_array release];
		_array = nil;

		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	self = [super init];

	@try {
		bool ok = true;

		for (size_t i = 0; i < count; i++) {
			if (objects[i] == nil)
				ok = false;

			[objects[i] retain];
		}

		if (!ok)
			@throw [OFInvalidArgumentException exception];

		_array = [[OFMutableData alloc] initWithItemSize: sizeof(id)
							capacity: count];
		[_array addItems: objects count: count];
	} @catch (id e) {
		for (size_t i = 0; i < count; i++)
			[objects[i] release];

		[self release];
		@throw e;
	}

	return self;
}

- (size_t)count
{
	return _array.count;
}

- (id const *)objects
{
	return _array.items;
}

- (id)objectAtIndex: (size_t)idx
{
	return *((id *)[_array itemAtIndex: idx]);
}

- (id)objectAtIndexedSubscript: (size_t)idx
{
	return *((id *)[_array itemAtIndex: idx]);
}

- (void)getObjects: (id *)buffer inRange: (OFRange)range
{
	id const *objects = _array.items;
	size_t count = _array.count;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > count)
		@throw [OFOutOfRangeException exception];

	for (size_t i = 0; i < range.length; i++)
		buffer[i] = objects[range.location + i];
}

- (size_t)indexOfObject: (id)object
{
	id const *objects;
	size_t count;

	if (object == nil)
		return OFNotFound;

	objects = _array.items;
	count = _array.count;

	for (size_t i = 0; i < count; i++)
		if ([objects[i] isEqual: object])
			return i;

	return OFNotFound;
}

- (size_t)indexOfObjectIdenticalTo: (id)object
{
	id const *objects;
	size_t count;

	if (object == nil)
		return OFNotFound;

	objects = _array.items;
	count = _array.count;

	for (size_t i = 0; i < count; i++)
		if (objects[i] == object)
			return i;

	return OFNotFound;
}


- (OFArray *)objectsInRange: (OFRange)range
{
	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length > _array.count)
		@throw [OFOutOfRangeException exception];

	if ([self isKindOfClass: [OFMutableArray class]])
		return [OFArray
		    arrayWithObjects: (id *)_array.items + range.location
			       count: range.length];

	return [[[OFConcreteSubarray alloc] initWithArray: self
						    range: range] autorelease];
}

- (bool)isEqual: (id)object
{
	OFArray *otherArray;
	id const *objects, *otherObjects;
	size_t count;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFConcreteArray class]] &&
	    ![object isKindOfClass: [OFConcreteMutableArray class]])
		return [super isEqual: object];

	otherArray = object;

	count = _array.count;

	if (count != otherArray.count)
		return false;

	objects = _array.items;
	otherObjects = otherArray.objects;

	for (size_t i = 0; i < count; i++)
		if (![objects[i] isEqual: otherObjects[i]])
			return false;

	return true;
}

- (unsigned long)hash
{
	id const *objects = _array.items;
	size_t count = _array.count;
	unsigned long hash;

	OFHashInit(&hash);

	for (size_t i = 0; i < count; i++)
		OFHashAddHash(&hash, [objects[i] hash]);

	OFHashFinalize(&hash);

	return hash;
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count_
{
	static unsigned long dummyMutations;
	size_t count = _array.count;

	if (count > INT_MAX)
		/*
		 * Use the implementation from OFArray, which is slower, but can
		 * enumerate in chunks.
		 */
		return [super countByEnumeratingWithState: state
						  objects: objects
						    count: count_];

	if (state->state >= count)
		return 0;

	state->state = (unsigned long)count;
	state->itemsPtr = (id *)_array.items;
	state->mutationsPtr = &dummyMutations;

	return (int)count;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (OFArrayEnumerationBlock)block
{
	id const *objects = _array.items;
	size_t count = _array.count;
	bool stop = false;

	for (size_t i = 0; i < count && !stop; i++)
		block(objects[i], i, &stop);
}
#endif

- (void)dealloc
{
	id const *objects = _array.items;
	size_t count = _array.count;

	for (size_t i = 0; i < count; i++)
		[objects[i] release];

	[_array release];

	[super dealloc];
}
@end
