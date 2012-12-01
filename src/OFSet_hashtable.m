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

#import "OFSet_hashtable.h"
#import "OFMutableSet_hashtable.h"
#import "OFCountedSet_hashtable.h"
#import "OFMapTable.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"
#import "OFEnumerationMutationException.h"

#import "autorelease.h"

static void*
retain(void *value)
{
	return [(id)value retain];
}

static void
release(void *value)
{
	[(id)value release];
}

static uint32_t
hash(void *value)
{
	return [(id)value hash];
}

static BOOL
equal(void *value1, void *value2)
{
	return [(id)value1 isEqual: (id)value2];
}

static of_map_table_functions_t keyFunctions = {
	.retain = retain,
	.release = release,
	.hash = hash,
	.equal = equal
};
static of_map_table_functions_t valueFunctions = {};

@implementation OFSet_hashtable
- init
{
	return [self initWithCapacity: 0];
}

- initWithCapacity: (size_t)capacity
{
	self = [super init];

	@try {
		mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			  valueFunctions: valueFunctions
				capacity: capacity];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSet: (OFSet*)set
{
	size_t count;

	if (set == nil)
		return [self init];

	@try {
		count = [set count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCapacity: count];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFEnumerator *enumerator;
		id object;

		enumerator = [set objectEnumerator];
		while ((object = [enumerator nextObject]) != nil)
			[mapTable setValue: (void*)1
				    forKey: object];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithArray: (OFArray*)array
{
	size_t count;

	if (array == nil)
		return self;

	@try {
		count = [array count];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCapacity: count];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFEnumerator *enumerator;
		id object;

		enumerator = [array objectEnumerator];
		while ((object = [enumerator nextObject]) != nil)
			[mapTable setValue: (void*)1
				    forKey: object];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObjects: (id const*)objects
	    count: (size_t)count
{
	self = [self initWithCapacity: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			[mapTable setValue: (void*)1
				    forKey: objects[i]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithObject: (id)firstObject
       arguments: (va_list)arguments
{
	self = [super init];

	@try {
		id object;
		va_list argumentsCopy;
		size_t count;

		va_copy(argumentsCopy, arguments);

		for (count = 1; va_arg(argumentsCopy, id) != nil; count++);

		mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			  valueFunctions: valueFunctions
				capacity: count];

		[mapTable setValue: (void*)1
			    forKey: firstObject];

		while ((object = va_arg(arguments, id)) != nil)
			[mapTable setValue: (void*)1
				    forKey: object];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [self init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFEnumerator *enumerator;
		OFXMLElement *child;

		if ((![[element name] isEqual: @"OFSet"] &&
		    ![[element name] isEqual: @"OFMutableSet"]) ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		enumerator = [[element elementsForNamespace:
		    OF_SERIALIZATION_NS] objectEnumerator];
		while ((child = [enumerator nextObject]) != nil) {
			void *pool2  = objc_autoreleasePoolPush();

			[mapTable setValue: (void*)1
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
	[mapTable release];

	[super dealloc];
}

- (size_t)count
{
	return [mapTable count];
}

- (BOOL)containsObject: (id)object
{
	if (object == nil)
		return NO;

	return ([mapTable valueForKey: object] != nil);
}

- (BOOL)isEqual: (id)object
{
	OFSet_hashtable *otherSet;

	if (![object isKindOfClass: [OFSet_hashtable class]] &&
	    ![object isKindOfClass: [OFMutableSet_hashtable class]] &&
	    ![object isKindOfClass: [OFCountedSet_hashtable class]])
		return [super isEqual: object];

	otherSet = object;

	return [otherSet->mapTable isEqual: mapTable];
}

- (OFEnumerator*)objectEnumerator
{
	return [[[OFMapTableEnumeratorWrapper alloc]
	    initWithEnumerator: [mapTable keyEnumerator]
			object: self] autorelease];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	return [mapTable countByEnumeratingWithState: state
					     objects: objects
					       count: count];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
{
	@try {
		[mapTable enumerateKeysAndValuesUsingBlock:
		    ^ (void *key, void *value, BOOL *stop) {
			block(key, stop);
		}];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithClass: [self class]
				object: self];
	}
}
#endif
@end
