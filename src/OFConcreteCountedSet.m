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

#import "OFConcreteCountedSet.h"
#import "OFArray.h"
#import "OFConcreteMutableSet.h"
#import "OFMapTable.h"
#import "OFString.h"
#import "OFXMLAttribute.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFEnumerationMutationException.h"
#import "OFOutOfRangeException.h"

@implementation OFConcreteCountedSet
+ (void)initialize
{
	if (self == [OFConcreteCountedSet class])
		[self inheritMethodsFromClass: [OFConcreteMutableSet class]];
}

- (instancetype)initWithSet: (OFSet *)set
{
	self = [self init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if ([set isKindOfClass: [OFCountedSet class]]) {
			OFCountedSet *countedSet = (OFCountedSet *)set;

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

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
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

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
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

- (size_t)countForObject: (id)object
{
	return (size_t)(uintptr_t)[_mapTable objectForKey: object];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsAndCountUsingBlock: (OFCountedSetEnumerationBlock)block
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

	[_mapTable setObject: (void *)(uintptr_t)(count + 1) forKey: object];
}

- (void)removeObject: (id)object
{
	size_t count = (size_t)(uintptr_t)[_mapTable objectForKey: object];

	if (count == 0)
		return;

	count--;

	if (count > 0)
		[_mapTable setObject: (void *)(uintptr_t)count forKey: object];
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
