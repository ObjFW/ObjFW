/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFMutableDictionary_hashtable.h"
#import "OFArray.h"
#import "OFString.h"

static struct {
	Class isa;
} placeholder;

@interface OFMutableDictionary_placeholder: OFDictionary
@end

@implementation OFMutableDictionary_placeholder
- init
{
	return (id)[[OFMutableDictionary_hashtable alloc] init];
}

- initWithDictionary: (OFDictionary*)dictionary
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithDictionary: dictionary];
}

- initWithObject: (id)object
	  forKey: (id)key
{
	return (id)[[OFMutableDictionary_hashtable alloc] initWithObject: object
								  forKey: key];
}

- initWithObjects: (OFArray*)objects
	  forKeys: (OFArray*)keys
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithObjects: objects
		    forKeys: keys];
}

- initWithObjects: (id const*)objects
	  forKeys: (id const*)keys
	    count: (size_t)count
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithObjects: objects
		    forKeys: keys
		      count: count];
}

- initWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = (id)[[OFMutableDictionary_hashtable alloc]
	    initWithKey: firstKey
	      arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithKey: (id)firstKey
    arguments: (va_list)arguments
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithKey: firstKey
	      arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithSerialization: element];
}

- initWithCapacity: (size_t)capacity
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithCapacity: capacity];
}

- retain
{
	return self;
}

- autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	OF_UNRECOGNIZED_SELECTOR

	/* Get rid of a stupid warning */
	[super dealloc];
}
@end

@implementation OFMutableDictionary
+ (void)initialize
{
	if (self == [OFMutableDictionary class])
		placeholder.isa = [OFMutableDictionary_placeholder class];
}

+ alloc
{
	if (self == [OFMutableDictionary class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)dictionaryWithCapacity: (size_t)capacity
{
	return [[[self alloc] initWithCapacity: capacity] autorelease];
}

- init
{
	if (object_getClass(self) == [OFMutableDictionary class]) {
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

- initWithCapacity: (size_t)capacity
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
	[self setObject: object
		 forKey: key];
}

- (void)setValue: (id)value
	  forKey: (OFString*)key
{
	if ([key hasPrefix: @"@"]) {
		void *pool = objc_autoreleasePoolPush();

		key = [key substringWithRange: of_range(1, [key length] - 1)];
		[super setValue: value
			 forKey: key];

		objc_autoreleasePoolPop(pool);
		return;
	}

	[self setObject: value
		 forKey: key];
}

- (void)removeObjectForKey: (id)key
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeAllObjects
{
	void *pool = objc_autoreleasePoolPush();

	for (id key in [self allKeys])
		[self removeObjectForKey: key];

	objc_autoreleasePoolPop(pool);
}

- copy
{
	return [[OFDictionary alloc] initWithDictionary: self];
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
