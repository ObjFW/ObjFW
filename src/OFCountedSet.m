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

#include <stdlib.h>

#import "OFCountedSet.h"
#import "OFConcreteCountedSet.h"
#import "OFNumber.h"
#import "OFString.h"

static struct {
	Class isa;
} placeholder;

@interface OFPlaceholderCountedSet: OFCountedSet
@end

@implementation OFPlaceholderCountedSet
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)init
{
	return (id)[[OFConcreteCountedSet alloc] init];
}

- (instancetype)initWithSet: (OFSet *)set
{
	return (id)[[OFConcreteCountedSet alloc] initWithSet: set];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFConcreteCountedSet alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFConcreteCountedSet alloc] initWithObject: firstObject
						 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	return (id)[[OFConcreteCountedSet alloc] initWithObjects: objects
							   count: count];
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	return (id)[[OFConcreteCountedSet alloc] initWithObject: firstObject
						      arguments: arguments];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFCountedSet
+ (void)initialize
{
	if (self == [OFCountedSet class])
		object_setClass((id)&placeholder,
		    [OFPlaceholderCountedSet class]);
}

+ (instancetype)alloc
{
	if (self == [OFCountedSet class])
		return (id)&placeholder;

	return [super alloc];
}

- (size_t)countForObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)description
{
	OFMutableString *ret;
	void *pool;
	size_t i, count = self.count;

	if (count == 0)
		return @"{()}";

	ret = [OFMutableString stringWithString: @"{(\n"];

	pool = objc_autoreleasePoolPush();

	i = 0;
	for (id object in self) {
		void *pool2 = objc_autoreleasePoolPush();

		[ret appendString: object];
		[ret appendFormat: @": %zu", [self countForObject: object]];

		if (++i < count)
			[ret appendString: @",\n"];

		objc_autoreleasePoolPop(pool2);
	}
	[ret replaceOccurrencesOfString: @"\n" withString: @"\n\t"];
	[ret appendString: @"\n)}"];
	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (id)copy
{
	return [[OFCountedSet alloc] initWithSet: self];
}

- (id)mutableCopy
{
	return [[OFCountedSet alloc] initWithSet: self];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsAndCountUsingBlock: (OFCountedSetEnumerationBlock)block
{
	[self enumerateObjectsUsingBlock: ^ (id object, bool *stop) {
		block(object, [self countForObject: object], stop);
	}];
}
#endif

- (void)minusSet: (OFSet *)set
{
	void *pool = objc_autoreleasePoolPush();

	if ([set isKindOfClass: [OFCountedSet class]]) {
		OFCountedSet *countedSet = (OFCountedSet *)set;

		for (id object in countedSet) {
			size_t count = [countedSet countForObject: object];

			for (size_t i = 0; i < count; i++)
				[self removeObject: object];
		}
	} else
		for (id object in set)
			[self removeObject: object];

	objc_autoreleasePoolPop(pool);
}

- (void)unionSet: (OFSet *)set
{
	void *pool = objc_autoreleasePoolPush();

	if ([set isKindOfClass: [OFCountedSet class]]) {
		OFCountedSet *countedSet = (OFCountedSet *)set;

		for (id object in countedSet) {
			size_t count = [countedSet countForObject: object];

			for (size_t i = 0; i < count; i++)
				[self addObject: object];
		}
	} else
		for (id object in set)
			[self addObject: object];

	objc_autoreleasePoolPop(pool);
}

- (void)removeAllObjects
{
	void *pool = objc_autoreleasePoolPush();
	OFSet *copy = [[self copy] autorelease];

	for (id object in copy) {
		size_t count = [self countForObject: object];

		for (size_t i = 0; i < count; i++)
			[self removeObject: object];
	}

	objc_autoreleasePoolPop(pool);
}
@end
