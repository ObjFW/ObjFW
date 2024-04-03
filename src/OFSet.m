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

#import "OFSet.h"
#import "OFArray.h"
#import "OFConcreteSet.h"
#import "OFCountedSet.h"
#import "OFNull.h"
#import "OFString.h"

static struct {
	Class isa;
} placeholder;

@interface OFPlaceholderSet: OFSet
@end

@implementation OFPlaceholderSet
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)init
{
	return (id)[[OFConcreteSet alloc] init];
}

- (instancetype)initWithSet: (OFSet *)set
{
	return (id)[[OFConcreteSet alloc] initWithSet: set];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFConcreteSet alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFConcreteSet alloc] initWithObject: firstObject
					  arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObjects: (id const *)objects count: (size_t)count
{
	return (id)[[OFConcreteSet alloc] initWithObjects: objects
						    count: count];
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	return (id)[[OFConcreteSet alloc] initWithObject: firstObject
					       arguments: arguments];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFSet
+ (void)initialize
{
	if (self == [OFSet class])
		object_setClass((id)&placeholder, [OFPlaceholderSet class]);
}

+ (instancetype)alloc
{
	if (self == [OFSet class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)set
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)setWithSet: (OFSet *)set
{
	return [[[self alloc] initWithSet: set] autorelease];
}

+ (instancetype)setWithArray: (OFArray *)array
{
	return [[[self alloc] initWithArray: array] autorelease];
}

+ (instancetype)setWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[[self alloc] initWithObject: firstObject
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ (instancetype)setWithObjects: (id const *)objects count: (size_t)count
{
	return [[[self alloc] initWithObjects: objects
					count: count] autorelease];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFSet class]] ||
	    [self isMemberOfClass: [OFMutableSet class]] ||
	    [self isMemberOfClass: [OFCountedSet class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (instancetype)initWithSet: (OFSet *)set
{
	id *objects = NULL;
	size_t count;

	@try {
		void *pool = objc_autoreleasePoolPush();
		size_t i = 0;

		count = set.count;
		objects = OFAllocMemory(count, sizeof(id));

		for (id object in set) {
			OFEnsure(i < count);
			objects[i++] = object;
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		OFFreeMemory(objects);

		[self release];
		@throw e;
	}

	@try {
		self = [self initWithObjects: objects count: count];
	} @finally {
		OFFreeMemory(objects);
	}

	return self;
}

- (instancetype)initWithArray: (OFArray *)array
{
	void *pool = objc_autoreleasePoolPush();
	size_t count;
	const id *objects;

	@try {
		count = array.count;
		objects = array.objects;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithObjects: objects count: count];

	objc_autoreleasePoolPop(pool);

	return self;
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
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [self initWithObject: firstObject arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObject: (id)firstObject arguments: (va_list)arguments
{
	size_t count = 1;
	va_list argumentsCopy;
	id *objects;

	if (firstObject == nil)
		return [self init];

	va_copy(argumentsCopy, arguments);
	while (va_arg(argumentsCopy, id) != nil)
		count++;

	@try {
		objects = OFAllocMemory(count, sizeof(id));
	} @catch (id e) {
		[self release];
		@throw e;
	}

	@try {
		objects[0] = firstObject;

		for (size_t i = 1; i < count; i++) {
			objects[i] = va_arg(arguments, id);
			OFEnsure(objects[i] != nil);
		}

		self = [self initWithObjects: objects count: count];
	} @finally {
		OFFreeMemory(objects);
	}

	return self;
}

- (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)valueForKey: (OFString *)key
{
	id ret;

	if ([key isEqual: @"@count"])
		return [super valueForKey: @"count"];

	ret = [OFMutableSet setWithCapacity: self.count];

	for (id object in self) {
		id value = [object valueForKey: key];

		if (value != nil)
			[ret addObject: value];
	}

	[ret makeImmutable];

	return ret;
}

- (void)setValue: (id)value forKey: (OFString *)key
{
	for (id object in self)
		[object setValue: value forKey: key];
}

- (bool)containsObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFEnumerator *)objectEnumerator
{
	OF_UNRECOGNIZED_SELECTOR
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	static unsigned long dummyMutations;
	OFEnumerator *enumerator;
	int i;

	memcpy(&enumerator, state->extra, sizeof(enumerator));

	if (enumerator == nil) {
		enumerator = [self objectEnumerator];
		memcpy(state->extra, &enumerator, sizeof(enumerator));
	}

	state->itemsPtr = objects;
	state->mutationsPtr = &dummyMutations;

	for (i = 0; i < count; i++) {
		id object = [enumerator nextObject];

		if (object == nil)
			return i;

		objects[i] = object;
	}

	return i;
}

- (bool)isEqual: (id)object
{
	OFSet *set;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFSet class]])
		return false;

	set = object;

	if (set.count != self.count)
		return false;

	return [set isSubsetOfSet: self];
}

- (unsigned long)hash
{
	void *pool = objc_autoreleasePoolPush();
	unsigned long hash = 0;

	for (id object in self)
		hash ^= [object hash];

	objc_autoreleasePoolPop(pool);

	return hash;
}

- (OFString *)description
{
	void *pool;
	OFMutableString *ret;
	size_t i, count = self.count;

	if (count == 0)
		return @"{()}";

	ret = [OFMutableString stringWithString: @"{(\n"];

	pool = objc_autoreleasePoolPush();

	i = 0;
	for (id object in self) {
		void *pool2 = objc_autoreleasePoolPush();

		[ret appendString: [object description]];

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
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableSet alloc] initWithSet: self];
}

- (bool)isSubsetOfSet: (OFSet *)set
{
	for (id object in self)
		if (![set containsObject: object])
			return false;

	return true;
}

- (bool)intersectsSet: (OFSet *)set
{
	for (id object in self)
		if ([set containsObject: object])
			return true;

	return false;
}

- (OFSet *)setByAddingObjectsFromSet: (OFSet *)set
{
	OFMutableSet *new = [[self mutableCopy] autorelease];
	[new unionSet: set];
	[new makeImmutable];
	return new;
}

- (OFArray *)allObjects
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *ret = [[[self objectEnumerator] allObjects] retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

- (id)anyObject
{
	void *pool = objc_autoreleasePoolPush();
	id ret = [[[self objectEnumerator] nextObject] retain];
	objc_autoreleasePoolPop(pool);
	return [ret autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (OFSetEnumerationBlock)block
{
	bool stop = false;

	for (id object in self) {
		block(object, &stop);

		if (stop)
			break;
	}
}

- (OFSet *)filteredSetUsingBlock: (OFSetFilterBlock)block
{
	OFMutableSet *ret = [OFMutableSet set];

	[self enumerateObjectsUsingBlock: ^ (id object, bool *stop) {
		if (block(object))
			[ret addObject: object];
	}];

	[ret makeImmutable];

	return ret;
}
#endif
@end
