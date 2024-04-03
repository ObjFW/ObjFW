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

#include <stdarg.h>
#include <stdlib.h>

#import "OFArray.h"
#import "OFArray+Private.h"
#import "OFConcreteArray.h"
#import "OFData.h"
#import "OFNull.h"
#import "OFString.h"
#import "OFSubarray.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

static struct {
	Class isa;
} placeholder;

@interface OFArray ()
- (OFString *)
    of_JSONRepresentationWithOptions: (OFJSONRepresentationOptions)options
			       depth: (size_t)depth;
@end

@interface OFPlaceholderArray: OFArray
@end

@implementation OFPlaceholderArray
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)init
{
	return (id)[[OFConcreteArray alloc] init];
}

- (instancetype)initWithObject: (id)object
{
	return (id)[[OFConcreteArray alloc] initWithObject: object];
}

- (instancetype)initWithObjects: (id)firstObject, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstObject);
	ret = [[OFConcreteArray alloc] initWithObject: firstObject
					    arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithObject: (id)firstObject
		     arguments: (va_list)arguments
{
	return (id)[[OFConcreteArray alloc] initWithObject: firstObject
						 arguments: arguments];
}

- (instancetype)initWithArray: (OFArray *)array
{
	return (id)[[OFConcreteArray alloc] initWithArray: array];
}

- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	return (id)[[OFConcreteArray alloc] initWithObjects: objects
						      count: count];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFArray
+ (void)initialize
{
	if (self == [OFArray class])
		object_setClass((id)&placeholder, [OFPlaceholderArray class]);
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
	if ([self isMemberOfClass: [OFArray class]] ||
	    [self isMemberOfClass: [OFMutableArray class]]) {
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
	return [self initWithObjects: &object count: 1];
}

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

- (instancetype)initWithArray: (OFArray *)array
{
	id *objects;
	size_t count;

	@try {
		count = array.count;
		objects = OFAllocMemory(count, sizeof(id));

		[array getObjects: objects
			  inRange: OFMakeRange(0, count)];
	} @catch (id e) {
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

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithObjects: (id const *)objects
			  count: (size_t)count
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)getObjects: (id *)buffer inRange: (OFRange)range
{
	for (size_t i = 0; i < range.length; i++)
		buffer[i] = [self objectAtIndex: range.location + i];
}

- (id const *)objects
{
	size_t count = self.count;
	id *buffer = OFAllocMemory(count, sizeof(id));
	id const *ret;

	@try {
		[self getObjects: buffer inRange: OFMakeRange(0, count)];

		ret = [[OFData dataWithItemsNoCopy: buffer
					     count: count
					  itemSize: sizeof(id)
				      freeWhenDone: true] items];
	} @catch (id e) {
		OFFreeMemory(buffer);
		@throw e;
	}

	return ret;
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

- (void)setValue: (id)value forKey: (OFString *)key
{
	for (id object in self)
		[object setValue: value forKey: key];
}

- (size_t)indexOfObject: (id)object
{
	size_t i = 0;

	if (object == nil)
		return OFNotFound;

	for (id objectIter in self) {
		if ([objectIter isEqual: object])
			return i;

		i++;
	}

	return OFNotFound;
}

- (size_t)indexOfObjectIdenticalTo: (id)object
{
	size_t i = 0;

	if (object == nil)
		return OFNotFound;

	for (id objectIter in self) {
		if (objectIter == object)
			return i;

		i++;
	}

	return OFNotFound;
}

- (bool)containsObject: (id)object
{
	return ([self indexOfObject: object] != OFNotFound);
}

- (bool)containsObjectIdenticalTo: (id)object
{
	return ([self indexOfObjectIdenticalTo: object] != OFNotFound);
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

- (OFArray *)objectsInRange: (OFRange)range
{
	OFArray *ret;
	id *buffer;

	if (range.length > SIZE_MAX - range.location ||
	    range.location + range.length < self.count)
		@throw [OFOutOfRangeException exception];

	if (![self isKindOfClass: [OFMutableArray class]])
		return [[[OFSubarray alloc] initWithArray: self
						    range: range] autorelease];

	buffer = OFAllocMemory(range.length, sizeof(*buffer));
	@try {
		[self getObjects: buffer inRange: range];

		ret = [OFArray arrayWithObjects: buffer count: range.length];
	} @finally {
		OFFreeMemory(buffer);
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
			       options: (OFArrayJoinOptions)options
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
			       options: (OFArrayJoinOptions)options
{
	OFMutableString *ret;

	if (separator == nil)
		@throw [OFInvalidArgumentException exception];

	if (self.count == 0)
		return @"";

	if (self.count == 1) {
		OFString *component =
		    [[self objectAtIndex: 0] performSelector: selector];

		if (component == nil)
			@throw [OFInvalidArgumentException exception];

		return component;
	}

	ret = [OFMutableString string];

	if (options & OFArraySkipEmptyComponents) {
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

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	for (id object in self)
		OFHashAddHash(&hash, [object hash]);

	OFHashFinalize(&hash);

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
		[ret insertString: @"(\n" atIndex: 0];
		[ret replaceOccurrencesOfString: @"\n" withString: @"\n\t"];
		[ret appendString: @"\n)"];
	} @catch (id e) {
		[ret release];
		@throw e;
	}

	objc_autoreleasePoolPop(pool);

	[ret makeImmutable];

	return [ret autorelease];
}

- (OFString *)JSONRepresentation
{
	return [self of_JSONRepresentationWithOptions: 0 depth: 0];
}

- (OFString *)JSONRepresentationWithOptions:
    (OFJSONRepresentationOptions)options
{
	return [self of_JSONRepresentationWithOptions: options depth: 0];
}

- (OFString *)
    of_JSONRepresentationWithOptions: (OFJSONRepresentationOptions)options
			       depth: (size_t)depth
{
	OFMutableString *JSON = [OFMutableString stringWithString: @"["];
	void *pool = objc_autoreleasePoolPush();
	size_t i, count = self.count;

	if (options & OFJSONRepresentationOptionPretty) {
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
		uint16_t tmp = OFToBigEndian16((uint16_t)count);

		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else if (count <= UINT32_MAX) {
		uint8_t type = 0xDD;
		uint32_t tmp = OFToBigEndian32((uint32_t)count);

		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	i = 0;
	for (id object in self) {
		void *pool2 = objc_autoreleasePoolPush();
		OFData *child;

		i++;

		child = [object messagePackRepresentation];
		[data addItems: child.items count: child.count];

		objc_autoreleasePoolPop(pool2);
	}

	OFAssert(i == count);

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
		[objectIter performSelector: selector withObject: object];
}

- (OFArray *)sortedArray
{
	OFMutableArray *new = [[self mutableCopy] autorelease];
	[new sort];
	[new makeImmutable];
	return new;
}

- (OFArray *)sortedArrayUsingSelector: (SEL)selector
			      options: (OFArraySortOptions)options
{
	OFMutableArray *new = [[self mutableCopy] autorelease];
	[new sortUsingSelector: selector options: options];
	[new makeImmutable];
	return new;
}

- (OFArray *)sortedArrayUsingFunction: (OFCompareFunction)compare
			      context: (void *)context
			      options: (OFArraySortOptions)options
{
	OFMutableArray *new = [[self mutableCopy] autorelease];
	[new sortUsingFunction: compare context: context options: options];
	[new makeImmutable];
	return new;
}

#ifdef OF_HAVE_BLOCKS
- (OFArray *)sortedArrayUsingComparator: (OFComparator)comparator
				options: (OFArraySortOptions)options
{
	OFMutableArray *new = [[self mutableCopy] autorelease];
	[new sortUsingComparator: comparator options: options];
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

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	static unsigned long dummyMutations;
	OFRange range = OFMakeRange(state->state, count);

	if (range.length > SIZE_MAX - range.location)
		@throw [OFOutOfRangeException exception];

	if (range.location + range.length > self.count)
		range.length = self.count - range.location;

	[self getObjects: objects inRange: range];

	if (range.location + range.length > ULONG_MAX)
		@throw [OFOutOfRangeException exception];

	state->state = (unsigned long)(range.location + range.length);
	state->itemsPtr = objects;
	state->mutationsPtr = &dummyMutations;

	return (int)range.length;
}

- (OFEnumerator *)objectEnumerator
{
	return [[[OFArrayEnumerator alloc] initWithArray: self
					    mutationsPtr: NULL] autorelease];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateObjectsUsingBlock: (OFArrayEnumerationBlock)block
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

#ifdef OF_HAVE_BLOCKS
- (OFArray *)mappedArrayUsingBlock: (OFArrayMapBlock)block
{
	OFArray *ret;
	size_t count = self.count;
	id *tmp = OFAllocMemory(count, sizeof(id));

	@try {
		[self enumerateObjectsUsingBlock: ^ (id object, size_t idx,
		    bool *stop) {
			tmp[idx] = block(object, idx);
		}];

		ret = [OFArray arrayWithObjects: tmp count: count];
	} @finally {
		OFFreeMemory(tmp);
	}

	return ret;
}

- (OFArray *)filteredArrayUsingBlock: (OFArrayFilterBlock)block
{
	OFArray *ret;
	size_t count = self.count;
	id *tmp = OFAllocMemory(count, sizeof(id));

	@try {
		__block size_t i = 0;

		[self enumerateObjectsUsingBlock: ^ (id object, size_t idx,
		    bool *stop) {
			if (block(object, idx))
				tmp[i++] = object;
		}];

		ret = [OFArray arrayWithObjects: tmp count: i];
	} @finally {
		OFFreeMemory(tmp);
	}

	return ret;
}

- (id)foldUsingBlock: (OFArrayFoldBlock)block
{
	size_t count = self.count;
	__block id current;

	if (count == 0)
		return nil;
	if (count == 1)
		return [[[self objectAtIndex: 0] retain] autorelease];

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
