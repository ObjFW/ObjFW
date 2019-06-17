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

#import "OFCountedMapTableSet.h"
#import "OFArray.h"
#import "OFMapTable.h"
#import "OFMutableMapTableSet.h"
#import "OFString.h"
#import "OFXMLAttribute.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFEnumerationMutationException.h"
#import "OFOutOfRangeException.h"

@implementation OFCountedMapTableSet
+ (void)initialize
{
	if (self == [OFCountedMapTableSet class])
		[self inheritMethodsFromClass: [OFMutableMapTableSet class]];
}

- (instancetype)initWithSet: (OFSet *)set
{
	self = [self init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if ([set isKindOfClass: [OFCountedSet class]]) {
			OFCountedSet *countedSet = (OFCountedSet *)countedSet;

			for (id object in countedSet) {
				size_t count =
				    [countedSet countForObject: object];

				for (size_t i = 0; i < count; i++)
					[self addObject: object];
			}
		} else
			for (id object in set)
				[self addObject: object];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithArray: (OFArray *)array
{
	self = [self init];

	@try {
		id const *objects = array.objects;
		size_t count = array.count;

		for (size_t i = 0; i < count; i++)
			[self addObject: objects[i]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	self = [self init];

	@try {
		for (size_t i = 0; i < count; i++)
			[self addObject: objects[i]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	self = [self init];

	@try {
		id object;

		[self addObject: firstObject];

		while ((object = va_arg(arguments, id)) != nil)
			[self addObject: object];
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

		if (![element.name isEqual: @"OFCountedSet"] ||
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		for (OFXMLElement *objectElement in
		    [element elementsForName: @"object"
				   namespace: OF_SERIALIZATION_NS]) {
			void *pool2 = objc_autoreleasePoolPush();
			OFXMLElement *object;
			OFXMLAttribute *countAttribute;
			intmax_t signedCount;
			uintmax_t count;

			object = [objectElement elementsForNamespace:
			    OF_SERIALIZATION_NS].firstObject;
			countAttribute =
			    [objectElement attributeForName: @"count"];

			if (object == nil || countAttribute == nil)
				@throw [OFInvalidFormatException exception];

			signedCount = countAttribute.decimalValue;
			if (signedCount < 0)
			       @throw [OFOutOfRangeException exception];

			count = signedCount;
			if (count > SIZE_MAX || count > UINTPTR_MAX)
				@throw [OFOutOfRangeException exception];

			[_mapTable setObject: (void *)(uintptr_t)count
				      forKey: object.objectByDeserializing];

			objc_autoreleasePoolPop(pool2);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)countForObject: (id)object
{
	return (size_t)(uintptr_t)[_mapTable objectForKey: object];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsAndCountUsingBlock:
    (of_counted_set_enumeration_block_t)block
{
	@try {
		[_mapTable enumerateKeysAndObjectsUsingBlock:
		    ^ (void *key, void *object, bool *stop) {
			block(key, (size_t)(uintptr_t)object, stop);
		}];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithObject: self];
	}
}
#endif

- (void)addObject: (id)object
{
	size_t count = (size_t)(uintptr_t)[_mapTable objectForKey: object];

	if (SIZE_MAX - count < 1 || UINTPTR_MAX - count < 1)
		@throw [OFOutOfRangeException exception];

	[_mapTable setObject: (void *)(uintptr_t)(count + 1)
		      forKey: object];
}

- (void)removeObject: (id)object
{
	size_t count = (size_t)(uintptr_t)[_mapTable objectForKey: object];

	if (count == 0)
		return;

	count--;

	if (count > 0)
		[_mapTable setObject: (void *)(uintptr_t)count
			      forKey: object];
	else
		[_mapTable removeObjectForKey: object];
}

- (void)removeAllObjects
{
	[_mapTable removeAllObjects];
}

- (void)makeImmutable
{
}
@end
