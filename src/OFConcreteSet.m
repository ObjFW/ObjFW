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

#import "OFConcreteSet.h"
#import "OFArray.h"
#import "OFConcreteCountedSet.h"
#import "OFConcreteMutableSet.h"
#import "OFMapTable+Private.h"
#import "OFMapTable.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFEnumerationMutationException.h"

static void *
retain(void *object)
{
	return [(id)object retain];
}

static void
release(void *object)
{
	[(id)object release];
}

static unsigned long
hash(void *object)
{
	return [(id)object hash];
}

static bool
equal(void *object1, void *object2)
{
	return [(id)object1 isEqual: (id)object2];
}

static const OFMapTableFunctions keyFunctions = {
	.retain = retain,
	.release = release,
	.hash = hash,
	.equal = equal
};
static const OFMapTableFunctions objectFunctions = { NULL };

@implementation OFConcreteSet
- (instancetype)init
{
	return [self initWithCapacity: 0];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	self = [super init];

	@try {
		_mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions
				capacity: capacity];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSet: (OFSet *)set
{
	size_t count;

	if (set == nil)
		return [self init];

	@try {
		count = set.count;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCapacity: count];

	@try {
		for (id object in set)
			[_mapTable setObject: (void *)1 forKey: object];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithArray: (OFArray *)array
{
	size_t count;

	if (array == nil)
		return self;

	@try {
		count = array.count;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCapacity: count];

	@try {
		for (id object in array)
			[_mapTable setObject: (void *)1 forKey: object];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	self = [self initWithCapacity: count];

	@try {
		for (size_t i = 0; i < count; i++)
			[_mapTable setObject: (void *)1 forKey: objects[i]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	self = [super init];

	@try {
		id object;
		va_list argumentsCopy;
		size_t count;

		va_copy(argumentsCopy, arguments);

		for (count = 1; va_arg(argumentsCopy, id) != nil; count++);

		_mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions
				capacity: count];

		[_mapTable setObject: (void *)1 forKey: firstObject];

		while ((object = va_arg(arguments, id)) != nil)
			[_mapTable setObject: (void *)1 forKey: object];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_mapTable release];

	[super dealloc];
}

- (size_t)count
{
	return [_mapTable count];
}

- (bool)containsObject: (id)object
{
	if (object == nil)
		return false;

	return ([_mapTable objectForKey: object] != nil);
}

- (bool)isEqual: (id)object
{
	OFConcreteSet *set;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFConcreteSet class]] &&
	    ![object isKindOfClass: [OFConcreteMutableSet class]] &&
	    ![object isKindOfClass: [OFConcreteCountedSet class]])
		return [super isEqual: object];

	set = object;

	return [set->_mapTable isEqual: _mapTable];
}

- (id)anyObject
{
	void *pool = objc_autoreleasePoolPush();
	void **objectPtr;
	id object;

	objectPtr = [[_mapTable keyEnumerator] nextObject];

	if (objectPtr == NULL) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	object = [(id)*objectPtr retain];

	objc_autoreleasePoolPop(pool);

	return [object autorelease];
}

- (OFEnumerator *)objectEnumerator
{
	return [[[OFMapTableEnumeratorWrapper alloc]
	    initWithEnumerator: [_mapTable keyEnumerator]
			object: self] autorelease];
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	return [_mapTable countByEnumeratingWithState: state
					      objects: objects
						count: count];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (OFSetEnumerationBlock)block
{
	@try {
		[_mapTable enumerateKeysAndObjectsUsingBlock:
		    ^ (void *key, void *object, bool *stop) {
			block(key, stop);
		}];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithObject: self];
	}
}
#endif
@end
