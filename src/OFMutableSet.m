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

#include <stdlib.h>

#include <assert.h>

#import "OFMutableSet.h"
#import "OFMutableMapTableSet.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableSetPlaceholder: OFMutableSet
@end

@implementation OFMutableSetPlaceholder
- (instancetype)init
{
	return (id)[[OFMutableMapTableSet alloc] init];
}

- (instancetype)initWithSet: (OFSet *)set
{
	return (id)[[OFMutableMapTableSet alloc] initWithSet: set];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFMutableMapTableSet alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFMutableMapTableSet alloc] initWithObject: firstObject
						 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	return (id)[[OFMutableMapTableSet alloc] initWithObjects: objects
							   count: count];
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	return (id)[[OFMutableMapTableSet alloc] initWithObject: firstObject
						      arguments: arguments];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFMutableMapTableSet alloc]
	    initWithSerialization: element];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	return (id)[[OFMutableMapTableSet alloc] initWithCapacity: capacity];
}

- (instancetype)retain
{
	return self;
}

- (instancetype)autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	OF_DEALLOC_UNSUPPORTED
}
@end

@implementation OFMutableSet
+ (void)initialize
{
	if (self == [OFMutableSet class])
		placeholder.isa = [OFMutableSetPlaceholder class];
}

+ (instancetype)alloc
{
	if (self == [OFMutableSet class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)setWithCapacity: (size_t)capacity
{
	return [[[self alloc] initWithCapacity: capacity] autorelease];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFMutableSet class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
			abort();
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	return [super init];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	OF_INVALID_INIT_METHOD
}

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

	cArray = [self allocMemoryWithSize: sizeof(id)
				     count: count];

	@try {
		size_t i;

		i = 0;
		for (id object in self) {
			assert(i < count);
			cArray[i++] = object;
		}

		for (i = 0; i < count; i++)
			if (![set containsObject: cArray[i]])
			      [self removeObject: cArray[i]];
	} @finally {
		[self freeMemory: cArray];
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
	OFSet *copy = [[self copy] autorelease];

	for (id object in copy)
		[self removeObject: object];

	objc_autoreleasePoolPop(pool);
}

- (void)makeImmutable
{
}
@end
