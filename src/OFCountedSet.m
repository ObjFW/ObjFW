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

#import "OFCountedSet.h"
#import "OFCountedMapTableSet.h"
#import "OFNumber.h"
#import "OFString.h"
#import "OFXMLElement.h"

static struct {
	Class isa;
} placeholder;

@interface OFCountedSetPlaceholder: OFCountedSet
@end

@implementation OFCountedSetPlaceholder
- (instancetype)init
{
	return (id)[[OFCountedMapTableSet alloc] init];
}

- (instancetype)initWithSet: (OFSet *)set
{
	return (id)[[OFCountedMapTableSet alloc] initWithSet: set];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFCountedMapTableSet alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFCountedMapTableSet alloc] initWithObject: firstObject
						 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	return (id)[[OFCountedMapTableSet alloc] initWithObjects: objects
							   count: count];
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	return (id)[[OFCountedMapTableSet alloc] initWithObject: firstObject
						      arguments: arguments];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFCountedMapTableSet alloc]
	    initWithSerialization: element];
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

@implementation OFCountedSet
+ (void)initialize
{
	if (self == [OFCountedSet class])
		placeholder.isa = [OFCountedSetPlaceholder class];
}

+ (instancetype)alloc
{
	if (self == [OFCountedSet class])
		return (id)&placeholder;

	return [super alloc];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFCountedSet class]]) {
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
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
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

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: @"OFCountedSet"
				      namespace: OF_SERIALIZATION_NS];

	for (id <OFSerialization> object in self) {
		void *pool2 = objc_autoreleasePoolPush();

		OFXMLElement *objectElement;
		OFString *count;

		count =
		    [OFString stringWithFormat: @"%zu",
						[self countForObject: object]];

		objectElement = [OFXMLElement
		    elementWithName: @"object"
			  namespace: OF_SERIALIZATION_NS];
		[objectElement addAttributeWithName: @"count"
					stringValue: count];
		[objectElement addChild: object.XMLElementBySerializing];
		[element addChild: objectElement];

		objc_autoreleasePoolPop(pool2);
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsAndCountUsingBlock:
    (of_counted_set_enumeration_block_t)block
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
