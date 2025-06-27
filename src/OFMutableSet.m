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

#import "OFMutableSet.h"
#import "OFConcreteMutableSet.h"
#import "OFString.h"

static struct {
	Class isa;
} placeholder;

@interface OFPlaceholderMutableSet: OFMutableSet
@end

@implementation OFPlaceholderMutableSet
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)init
{
	return (id)[[OFConcreteMutableSet alloc] init];
}

- (instancetype)initWithSet: (OFSet *)set
{
	return (id)[[OFConcreteMutableSet alloc] initWithSet: set];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFConcreteMutableSet alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFConcreteMutableSet alloc] initWithObject: firstObject
						 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	return (id)[[OFConcreteMutableSet alloc] initWithObjects: objects
							   count: count];
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	return (id)[[OFConcreteMutableSet alloc] initWithObject: firstObject
						      arguments: arguments];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	return (id)[[OFConcreteMutableSet alloc] initWithCapacity: capacity];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFMutableSet
+ (void)initialize
{
	if (self == [OFMutableSet class])
		object_setClass((id)&placeholder,
		    [OFPlaceholderMutableSet class]);
}

+ (instancetype)alloc
{
	if (self == [OFMutableSet class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)setWithCapacity: (size_t)capacity
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
- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
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
	return [[OFSet alloc] initWithSet: self];
}

- (void)addObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)minusSet: (OFSet *)set
{
	for (id object in set)
		[self removeObject: object];
}

- (void)intersectSet: (OFSet *)set
{
	void *pool = objc_autoreleasePoolPush();
	size_t count = self.count;
	id *cArray;

	cArray = OFAllocMemory(count, sizeof(id));
	@try {
		size_t i;

		i = 0;
		for (id object in self) {
			OFAssert(i < count);
			cArray[i++] = object;
		}

		for (i = 0; i < count; i++)
			if (![set containsObject: cArray[i]])
				[self removeObject: cArray[i]];
	} @finally {
		OFFreeMemory(cArray);
	}

	objc_autoreleasePoolPop(pool);
}

- (void)unionSet: (OFSet *)set
{
	for (id object in set)
		[self addObject: object];
}

- (void)removeAllObjects
{
	void *pool = objc_autoreleasePoolPush();
	OFSet *copy = objc_autorelease([self copy]);

	for (id object in copy)
		[self removeObject: object];

	objc_autoreleasePoolPop(pool);
}

- (void)makeImmutable
{
}
@end
