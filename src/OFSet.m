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

#import "OFSet.h"
#import "OFArray.h"
#import "OFMapTableSet.h"
#import "OFNull.h"
#import "OFString.h"
#import "OFXMLElement.h"

static struct {
	Class isa;
} placeholder;

@interface OFSetPlaceholder: OFSet
@end

@implementation OFSetPlaceholder
- (instancetype)init
{
	return (id)[[OFMapTableSet alloc] init];
}

- (instancetype)initWithSet: (OFSet *)set
{
	return (id)[[OFMapTableSet alloc] initWithSet: set];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFMapTableSet alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFMapTableSet alloc] initWithObject: firstObject
					  arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	return (id)[[OFMapTableSet alloc] initWithObjects: objects
						    count: count];
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	return (id)[[OFMapTableSet alloc] initWithObject: firstObject
					       arguments: arguments];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFMapTableSet alloc] initWithSerialization: element];
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

@implementation OFSet
+ (void)initialize
{
	if (self == [OFSet class])
		placeholder.isa = [OFSetPlaceholder class];
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

+ (instancetype)setWithObjects: (id const *)objects
			 count: (size_t)count
{
	return [[[self alloc] initWithObjects: objects
					count: count] autorelease];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFSet class]]) {
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
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithArray: (OFArray *)array
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [self initWithObject: firstObject
			 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	OF_INVALID_INIT_METHOD
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

- (void)setValue: (id)value
	  forKey: (OFString *)key
{
	for (id object in self)
		[object setValue: value
			  forKey: key];
}

- (bool)containsObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFEnumerator *)objectEnumerator
{
	OF_UNRECOGNIZED_SELECTOR
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	OFEnumerator *enumerator;
	int i;

	memcpy(&enumerator, state->extra, sizeof(enumerator));

	if (enumerator == nil) {
		enumerator = [self objectEnumerator];
		memcpy(state->extra, &enumerator, sizeof(enumerator));
	}

	state->itemsPtr = objects;
	state->mutationsPtr = (unsigned long *)self;

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

- (uint32_t)hash
{
	void *pool = objc_autoreleasePoolPush();
	uint32_t hash = 0;

	for (id object in self)
		hash += [object hash];

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
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
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

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	if ([self isKindOfClass: [OFMutableSet class]])
		element = [OFXMLElement elementWithName: @"OFMutableSet"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFSet"
					      namespace: OF_SERIALIZATION_NS];

	for (id <OFSerialization> object in self) {
		void *pool2 = objc_autoreleasePoolPush();

		[element addChild: object.XMLElementBySerializing];

		objc_autoreleasePoolPop(pool2);
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFSet *)setBySubtractingSet: (OFSet *)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new minusSet: set];

	[new makeImmutable];

	return new;
}

- (OFSet *)setByIntersectingWithSet: (OFSet *)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
	[new intersectSet: set];

	[new makeImmutable];

	return new;
}

- (OFSet *)setByAddingSet: (OFSet *)set
{
	OFMutableSet *new;

	new = [[self mutableCopy] autorelease];
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
- (void)enumerateObjectsUsingBlock: (of_set_enumeration_block_t)block
{
	bool stop = false;

	for (id object in self) {
		block(object, &stop);

		if (stop)
			break;
	}
}

- (OFSet *)filteredSetUsingBlock: (of_set_filter_block_t)block
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
