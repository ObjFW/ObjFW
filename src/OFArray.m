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

#include <stdarg.h>
#include <stdlib.h>

#include <assert.h>

#import "OFArray.h"
#import "OFAdjacentArray.h"
#import "OFData.h"
#import "OFNull.h"
#import "OFString.h"
#import "OFSubarray.h"
#import "OFXMLElement.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

static struct {
	Class isa;
} placeholder;

@interface OFArray ()
- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth;
@end

@interface OFPlaceholderArray: OFArray
@end

@implementation OFPlaceholderArray
- (instancetype)init
{
	return (id)[[OFAdjacentArray alloc] init];
}

- (instancetype)initWithObject: (id)object
{
	return (id)[[OFAdjacentArray alloc] initWithObject: object];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFAdjacentArray alloc] initWithObject: firstObject
					    arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	return (id)[[OFAdjacentArray alloc] initWithObject: firstObject
						 arguments: arguments];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFAdjacentArray alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	return (id)[[OFAdjacentArray alloc] initWithObjects: objects
						      count: count];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFAdjacentArray alloc] initWithSerialization: element];
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

@implementation OFArray
+ (void)initialize
{
	if (self == [OFArray class])
		placeholder.isa = [OFPlaceholderArray class];
}

+ (instancetype)alloc
{
	if (self == [OFArray class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)array
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)arrayWithObject: (id)object
{
	return [[[self alloc] initWithObject: object] autorelease];
}

+ (instancetype)arrayWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[[self alloc] initWithObject: firstObject
				  arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

+ (instancetype)arrayWithArray: (OFArray *)array
{
	return [[[self alloc] initWithArray: array] autorelease];
}

+ (instancetype)arrayWithObjects: (id const *)objects
			   count: (size_t)count
{
	return [[[self alloc] initWithObjects: objects
					count: count] autorelease];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFArray class]]) {
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

- (instancetype)initWithObject: (id)object
{
	if (object == nil) {
		[self release];
		@throw [OFInvalidArgumentException exception];
	}

	return [self initWithObjects: object, nil];
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

- (instancetype)initWithArray: (OFArray *)array
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
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

- (void)getObjects: (id *)buffer
	   inRange: (of_range_t)range
{
	for (size_t i = 0; i < range.length; i++)
		buffer[i] = [self objectAtIndex: range.location + i];
}

- (id const *)objects
{
	OFObject *container;
	size_t count;
	id *buffer;

	container = [[[OFObject alloc] init] autorelease];
	count = self.count;
	buffer = [container allocMemoryWithSize: sizeof(*buffer)
					  count: count];

	[self getObjects: buffer
		 inRange: of_range(0, count)];

	return buffer;
}

- (id)copy
{
	return [self retain];
}

- (id)mutableCopy
{
	return [[OFMutableArray alloc] initWithArray: self];
}

- (id)objectAtIndex: (size_t)idx
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)objectAtIndexedSubscript: (size_t)idx
{
	return [self objectAtIndex: idx];
}

- (id)valueForKey: (OFString *)key
{
	id ret;

	if ([key isEqual: @"@count"])
		return [super valueForKey: @"count"];

	ret = [OFMutableArray arrayWithCapacity: self.count];

	for (id object in self) {
		id value = [object valueForKey: key];

		if (value == nil)
			value = [OFNull null];

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

- (size_t)indexOfObject: (id)object
{
	size_t i = 0;

	if (object == nil)
		return OF_NOT_FOUND;

	for (id objectIter in self) {
		if ([objectIter isEqual: object])
			return i;

		i++;
	}

	return OF_NOT_FOUND;
}

- (size_t)indexOfObjectIdenticalTo: (id)object
{
	size_t i = 0;

	if (object == nil)
		return OF_NOT_FOUND;

	for (id objectIter in self) {
		if (objectIter == object)
			return i;

		i++;
	}

	return OF_NOT_FOUND;
}

- (bool)containsObject: (id)object
{
	return ([self indexOfObject: object] != OF_NOT_FOUND);
}

- (bool)containsObjectIdenticalTo: (id)object
{
	return ([self indexOfObjectIdenticalTo: object] != OF_NOT_FOUND);
}

- (id)firstObject
{
	if (self.count > 0)
		return [self objectAtIndex: 0];

	return nil;
}

- (id)lastObject
{
	size_t count = self.count;

	if (count > 0)
		return [self objectAtIndex: count - 1];

	return nil;
}

- (OFArray *)objectsInRange: (of_range_t)range
{
	OFArray *ret;
	id *buffer;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length < self.count)
		@throw [OFOutOfRangeException exception];

	if (![self isKindOfClass: [OFMutableArray class]])
		return [OFSubarray arrayWithArray: self
					    range: range];

	buffer = [self allocMemoryWithSize: sizeof(*buffer)
				     count: range.length];

	@try {
		[self getObjects: buffer
			 inRange: range];

		ret = [OFArray arrayWithObjects: buffer
					  count: range.length];
	} @finally {
		[self freeMemory: buffer];
	}

	return ret;
}

- (OFString *)componentsJoinedByString: (OFString *)separator
{
	return [self componentsJoinedByString: separator
				usingSelector: @selector(description)
				      options: 0];
}

- (OFString *)componentsJoinedByString: (OFString *)separator
			       options: (int)options
{
	return [self componentsJoinedByString: separator
				usingSelector: @selector(description)
				      options: options];
}

- (OFString *)componentsJoinedByString: (OFString *)separator
			 usingSelector: (SEL)selector
{
	return [self componentsJoinedByString: separator
				usingSelector: selector
				      options: 0];
}

- (OFString *)componentsJoinedByString: (OFString *)separator
			 usingSelector: (SEL)selector
			       options: (int)options
{
	OFMutableString *ret;

	if (separator == nil)
		@throw [OFInvalidArgumentException exception];

	if (self.count == 0)
		return @"";

	if (self.count == 1) {
		OFString *component =
		    [[self firstObject] performSelector: selector];

		if (component == nil)
			@throw [OFInvalidArgumentException exception];

		return component;
	}

	ret = [OFMutableString string];

	if (options & OF_ARRAY_SKIP_EMPTY) {
		for (id object in self) {
			void *pool = objc_autoreleasePoolPush();
			OFString *component =
			    [object performSelector: selector];

			if (component == nil)
				@throw [OFInvalidArgumentException exception];

			if (component.length > 0) {
				if (ret.length > 0)
					[ret appendString: separator];
				[ret appendString: component];
			}

			objc_autoreleasePoolPop(pool);
		}
	} else {
		bool first = true;

		for (id object in self) {
			void *pool = objc_autoreleasePoolPush();
			OFString *component =
			    [object performSelector: selector];

			if (component == nil)
				@throw [OFInvalidArgumentException exception];

			if OF_UNLIKELY (first)
				first = false;
			else
				[ret appendString: separator];

			[ret appendString: component];

			objc_autoreleasePoolPop(pool);
		}
	}

	[ret makeImmutable];

	return ret;
}

- (bool)isEqual: (id)object
{
	/* FIXME: Optimize (for example, buffer of 16 for each) */
	OFArray *otherArray;
	size_t count;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFArray class]])
		return false;

	otherArray = object;

	count = self.count;

	if (count != otherArray.count)
		return false;

	for (size_t i = 0; i < count; i++)
		if (![[self objectAtIndex: i] isEqual:
		    [otherArray objectAtIndex: i]])
			return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	for (id object in self)
		OF_HASH_ADD_HASH(hash, [object hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)description
{
	void *pool;
	OFMutableString *ret;

	if (self.count == 0)
		return @"()";

	pool = objc_autoreleasePoolPush();
	ret = [[self componentsJoinedByString: @",\n"] mutableCopy];

	@try {
		[ret prependString: @"(\n"];
		[ret replaceOccurrencesOfString: @"\n"
				     withString: @"\n\t"];
		[ret appendString: @"\n)"];
	} @catch (id e) {
		[ret release];
		@throw e;
	}

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return [ret autorelease];
}

- (OFXMLElement *)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	if ([self isKindOfClass: [OFMutableArray class]])
		element = [OFXMLElement elementWithName: @"OFMutableArray"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFArray"
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

- (OFString *)JSONRepresentation
{
	return [self of_JSONRepresentationWithOptions: 0
						depth: 0];
}

- (OFString *)JSONRepresentationWithOptions: (int)options
{
	return [self of_JSONRepresentationWithOptions: options
						depth: 0];
}

- (OFString *)of_JSONRepresentationWithOptions: (int)options
					 depth: (size_t)depth
{
	OFMutableString *JSON = [OFMutableString stringWithString: @"["];
	void *pool = objc_autoreleasePoolPush();
	size_t i, count = self.count;

	if (options & OF_JSON_REPRESENTATION_PRETTY) {
		OFMutableString *indentation = [OFMutableString string];

		for (i = 0; i < depth; i++)
			[indentation appendString: @"\t"];

		[JSON appendString: @"\n"];

		i = 0;
		for (id object in self) {
			void *pool2 = objc_autoreleasePoolPush();

			[JSON appendString: indentation];
			[JSON appendString: @"\t"];
			[JSON appendString: [object
			    of_JSONRepresentationWithOptions: options
						       depth: depth + 1]];

			if (++i < count)
				[JSON appendString: @",\n"];
			else
				[JSON appendString: @"\n"];

			objc_autoreleasePoolPop(pool2);
		}

		[JSON appendString: indentation];
	} else {
		i = 0;
		for (id object in self) {
			void *pool2 = objc_autoreleasePoolPush();

			[JSON appendString: [object
			    of_JSONRepresentationWithOptions: options
						       depth: depth + 1]];

			if (++i < count)
				[JSON appendString: @","];

			objc_autoreleasePoolPop(pool2);
		}
	}

	[JSON appendString: @"]"];
	[JSON makeImmutable];

	objc_autoreleasePoolPop(pool);

	return JSON;
}

- (OFData *)messagePackRepresentation
{
	OFMutableData *data;
	size_t i, count;
	void *pool;

	data = [OFMutableData data];
	count = self.count;

	if (count <= 15) {
		uint8_t tmp = 0x90 | ((uint8_t)count & 0xF);
		[data addItem: &tmp];
	} else if (count <= UINT16_MAX) {
		uint8_t type = 0xDC;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)count);

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (count <= UINT32_MAX) {
		uint8_t type = 0xDD;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)count);

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	i = 0;
	for (id object in self) {
		void *pool2 = objc_autoreleasePoolPush();
		OFData *child;

		i++;

		child = [object messagePackRepresentation];
		[data addItems: child.items
			 count: child.count];

		objc_autoreleasePoolPop(pool2);
	}

	assert(i == count);

	[data makeImmutable];

	objc_autoreleasePoolPop(pool);

	return data;
}

- (void)makeObjectsPerformSelector: (SEL)selector
{
	for (id object in self)
		[object performSelector: selector];
}

- (void)makeObjectsPerformSelector: (SEL)selector
			withObject: (id)object
{
	for (id objectIter in self)
		[objectIter performSelector: selector
				 withObject: object];
}

- (OFArray *)sortedArray
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new sort];

	[new makeImmutable];

	return new;
}

- (OFArray *)sortedArrayUsingSelector: (SEL)selector
			      options: (int)options
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new sortUsingSelector: selector
		       options: options];

	[new makeImmutable];

	return new;
}

#ifdef OF_HAVE_BLOCKS
- (OFArray *)sortedArrayUsingComparator: (of_comparator_t)comparator
				options: (int)options
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new sortUsingComparator: comparator
			 options: options];

	[new makeImmutable];

	return new;
}
#endif

- (OFArray *)reversedArray
{
	OFMutableArray *new = [[self mutableCopy] autorelease];

	[new reverse];

	[new makeImmutable];

	return new;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	of_range_t range = of_range(state->state, count);

	if (range.length > SIZE_MAX - range.location)
		@throw [OFOutOfRangeException exception];

	if (range.location + range.length > self.count)
		range.length = self.count - range.location;

	[self getObjects: objects
		 inRange: range];

	if (range.location + range.length > ULONG_MAX)
		@throw [OFOutOfRangeException exception];

	state->state = (unsigned long)(range.location + range.length);
	state->itemsPtr = objects;
	state->mutationsPtr = (unsigned long *)self;

	return (int)range.length;
}

- (OFEnumerator *)objectEnumerator
{
	return [[[OFArrayEnumerator alloc] initWithArray: self
					    mutationsPtr: NULL] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (of_array_enumeration_block_t)block
{
	size_t i = 0;
	bool stop = false;

	for (id object in self) {
		block(object, i++, &stop);

		if (stop)
			break;
	}
}
#endif

- (OFArray *)arrayByAddingObject: (id)object
{
	OFMutableArray *ret;

	if (object == nil)
		@throw [OFInvalidArgumentException exception];

	ret = [[self mutableCopy] autorelease];

	[ret addObject: object];
	[ret makeImmutable];

	return ret;
}

- (OFArray *)arrayByAddingObjectsFromArray: (OFArray *)array
{
	OFMutableArray *ret = [[self mutableCopy] autorelease];

	[ret addObjectsFromArray: array];
	[ret makeImmutable];

	return ret;
}

- (OFArray *)arrayByRemovingObject: (id)object
{
	OFMutableArray *ret = [[self mutableCopy] autorelease];

	[ret removeObject: object];
	[ret makeImmutable];

	return ret;
}

#ifdef OF_HAVE_BLOCKS
- (OFArray *)mappedArrayUsingBlock: (of_array_map_block_t)block
{
	OFArray *ret;
	size_t count = self.count;
	id *tmp = [self allocMemoryWithSize: sizeof(id)
				      count: count];

	@try {
		[self enumerateObjectsUsingBlock: ^ (id object, size_t idx,
		    bool *stop) {
			tmp[idx] = block(object, idx);
		}];

		ret = [OFArray arrayWithObjects: tmp
					  count: count];
	} @finally {
		[self freeMemory: tmp];
	}

	return ret;
}

- (OFArray *)filteredArrayUsingBlock: (of_array_filter_block_t)block
{
	OFArray *ret;
	size_t count = self.count;
	id *tmp = [self allocMemoryWithSize: sizeof(id)
				      count: count];

	@try {
		__block size_t i = 0;

		[self enumerateObjectsUsingBlock: ^ (id object, size_t idx,
		    bool *stop) {
			if (block(object, idx))
				tmp[i++] = object;
		}];

		ret = [OFArray arrayWithObjects: tmp
					  count: i];
	} @finally {
		[self freeMemory: tmp];
	}

	return ret;
}

- (id)foldUsingBlock: (of_array_fold_block_t)block
{
	size_t count = self.count;
	__block id current;

	if (count == 0)
		return nil;
	if (count == 1)
		return [[[self firstObject] retain] autorelease];

	[self enumerateObjectsUsingBlock: ^ (id object, size_t idx,
	    bool *stop) {
		id new;

		if (idx == 0) {
			current = [object retain];
			return;
		}

		@try {
			new = [block(current, object) retain];
		} @finally {
			[current release];
		}
		current = new;
	}];

	return [current autorelease];
}
#endif
@end

@implementation OFArrayEnumerator
- (instancetype)initWithArray: (OFArray *)array
		 mutationsPtr: (unsigned long *)mutationsPtr
{
	self = [super init];

	_array = [array retain];
	_count = [array count];
	_mutations = (mutationsPtr != NULL ? *mutationsPtr : 0);
	_mutationsPtr = mutationsPtr;

	return self;
}

- (void)dealloc
{
	[_array release];

	[super dealloc];
}

- (id)nextObject
{
	if (_mutationsPtr != NULL && *_mutationsPtr != _mutations)
		@throw [OFEnumerationMutationException
		    exceptionWithObject: _array];

	if (_position < _count)
		return [_array objectAtIndex: _position++];

	return nil;
}
@end
