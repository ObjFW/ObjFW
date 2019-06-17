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

#import "OFMapTableSet.h"
#import "OFArray.h"
#import "OFCountedMapTableSet.h"
#import "OFMapTable.h"
#import "OFMapTable+Private.h"
#import "OFMutableMapTableSet.h"
#import "OFString.h"
#import "OFXMLElement.h"

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

static uint32_t
hash(void *object)
{
	return [(id)object hash];
}

static bool
equal(void *object1, void *object2)
{
	return [(id)object1 isEqual: (id)object2];
}

static const of_map_table_functions_t keyFunctions = {
	.retain = retain,
	.release = release,
	.hash = hash,
	.equal = equal
};
static const of_map_table_functions_t objectFunctions = { NULL };

@implementation OFMapTableSet
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
			[_mapTable setObject: (void *)1
				      forKey: object];
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
			[_mapTable setObject: (void *)1
				      forKey: object];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	self = [self initWithCapacity: count];

	@try {
		for (size_t i = 0; i < count; i++)
			[_mapTable setObject: (void *)1
				      forKey: objects[i]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
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

		[_mapTable setObject: (void *)1
			      forKey: firstObject];

		while ((object = va_arg(arguments, id)) != nil)
			[_mapTable setObject: (void *)1
				      forKey: object];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	self = [self init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if ((![element.name isEqual: @"OFSet"] &&
		    ![element.name isEqual: @"OFMutableSet"]) ||
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		for (OFXMLElement *child in
		    [element elementsForNamespace: OF_SERIALIZATION_NS]) {
			void *pool2  = objc_autoreleasePoolPush();

			[_mapTable setObject: (void *)1
				      forKey: [child objectByDeserializing]];

			objc_autoreleasePoolPop(pool2);
		}

		objc_autoreleasePoolPop(pool);
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
	OFMapTableSet *set;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFMapTableSet class]] &&
	    ![object isKindOfClass: [OFMutableMapTableSet class]] &&
	    ![object isKindOfClass: [OFCountedMapTableSet class]])
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

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	return [_mapTable countByEnumeratingWithState: state
					      objects: objects
						count: count];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
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
