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

#import "OFMutableMapTableDictionary.h"
#import "OFArray.h"
#import "OFString.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableDictionaryPlaceholder: OFDictionary
@end

@implementation OFMutableDictionaryPlaceholder
- (instancetype)init
{
	return (id)[[OFMutableMapTableDictionary alloc] init];
}

- (instancetype)initWithDictionary: (OFDictionary *)dictionary
{
	return (id)[[OFMutableMapTableDictionary alloc]
	    initWithDictionary: dictionary];
}

- (instancetype)initWithObject: (id)object
			forKey: (id)key
{
	return (id)[[OFMutableMapTableDictionary alloc] initWithObject: object
								forKey: key];
}

- (instancetype)initWithObjects: (OFArray *)objects
			forKeys: (OFArray *)keys
{
	return (id)[[OFMutableMapTableDictionary alloc] initWithObjects: objects
								forKeys: keys];
}

- (instancetype)initWithObjects: (id const *)objects
			forKeys: (id const *)keys
			  count: (size_t)count
{
	return (id)[[OFMutableMapTableDictionary alloc] initWithObjects: objects
								forKeys: keys
								  count: count];
}

- (instancetype)initWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = (id)[[OFMutableMapTableDictionary alloc] initWithKey: firstKey
							 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithKey: (id)firstKey
		  arguments: (va_list)arguments
{
	return (id)[[OFMutableMapTableDictionary alloc] initWithKey: firstKey
							  arguments: arguments];
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	return (id)[[OFMutableMapTableDictionary alloc]
	    initWithSerialization: element];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	return (id)[[OFMutableMapTableDictionary alloc]
	    initWithCapacity: capacity];
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

@implementation OFMutableDictionary
+ (void)initialize
{
	if (self == [OFMutableDictionary class])
		placeholder.isa = [OFMutableDictionaryPlaceholder class];
}

+ (instancetype)alloc
{
	if (self == [OFMutableDictionary class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)dictionaryWithCapacity: (size_t)capacity
{
	return [[[self alloc] initWithCapacity: capacity] autorelease];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFMutableDictionary class]]) {
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

- (instancetype)initWithCapacity: (size_t)capacity
{
	OF_INVALID_INIT_METHOD
}

- (void)setObject: (id)object
	   forKey: (id)key
{
	OF_UNRECOGNIZED_SELECTOR
}

-   (void)setObject: (id)object
  forKeyedSubscript: (id)key
{
	if (object != nil)
		[self setObject: object
			 forKey: key];
	else
		[self removeObjectForKey: key];
}

- (void)removeObjectForKey: (id)key
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeAllObjects
{
	void *pool = objc_autoreleasePoolPush();

	for (id key in self.allKeys)
		[self removeObjectForKey: key];

	objc_autoreleasePoolPop(pool);
}

- (id)copy
{
	return [[OFDictionary alloc] initWithDictionary: self];
}

- (void)addEntriesFromDictionary: (OFDictionary *)dictionary
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *keyEnumerator = [dictionary keyEnumerator];
	OFEnumerator *objectEnumerator = [dictionary objectEnumerator];
	id key, object;

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil)
		[self setObject: object
			 forKey: key];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (of_dictionary_replace_block_t)block
{
	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    bool *stop) {
		id new = block(key, object);

		if (new != object) {
			[self setObject: block(key, object)
				 forKey: key];
		}
	}];
}
#endif

- (void)makeImmutable
{
}
@end
