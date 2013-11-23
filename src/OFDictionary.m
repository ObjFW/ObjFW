/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFDictionary.h"
#import "OFDictionary_hashtable.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFDataArray.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

#import "autorelease.h"
#import "macros.h"

static struct {
	Class isa;
} placeholder;

@interface OFDictionary_placeholder: OFDictionary
@end

@implementation OFDictionary_placeholder
- init
{
	return (id)[[OFDictionary_hashtable alloc] init];
}

- initWithDictionary: (OFDictionary*)dictionary
{
	return (id)[[OFDictionary_hashtable alloc]
	    initWithDictionary: dictionary];
}

- initWithObject: (id)object
	  forKey: (id)key
{
	return (id)[[OFDictionary_hashtable alloc] initWithObject: object
							   forKey: key];
}

- initWithObjects: (OFArray*)objects
	  forKeys: (OFArray*)keys
{
	return (id)[[OFDictionary_hashtable alloc] initWithObjects: objects
							   forKeys: keys];
}

- initWithObjects: (id const*)objects
	  forKeys: (id const*)keys
	    count: (size_t)count
{
	return (id)[[OFDictionary_hashtable alloc] initWithObjects: objects
							   forKeys: keys
							     count: count];
}

- initWithKeysAndObjects: (id <OFCopying>)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [[OFDictionary_hashtable alloc] initWithKey: firstKey
						arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithKey: (id <OFCopying>)firstKey
    arguments: (va_list)arguments
{
	return (id)[[OFDictionary_hashtable alloc] initWithKey: firstKey
						     arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFDictionary_hashtable alloc]
	    initWithSerialization: element];
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
	[self doesNotRecognizeSelector: _cmd];
	abort();

	/* Get rid of a stupid warning */
	[super dealloc];
}
@end

@implementation OFDictionary
+ (void)initialize
{
	if (self == [OFDictionary class])
		placeholder.isa = [OFDictionary_placeholder class];
}

+ alloc
{
	if (self == [OFDictionary class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)dictionary
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)dictionaryWithDictionary: (OFDictionary*)dictionary
{
	return [[[self alloc] initWithDictionary: dictionary] autorelease];
}

+ (instancetype)dictionaryWithObject: (id)object
			      forKey: (id)key
{
	return [[[self alloc] initWithObject: object
				      forKey: key] autorelease];
}

+ (instancetype)dictionaryWithObjects: (OFArray*)objects
			      forKeys: (OFArray*)keys
{
	return [[[self alloc] initWithObjects: objects
				      forKeys: keys] autorelease];
}

+ (instancetype)dictionaryWithObjects: (id const*)objects
			      forKeys: (id const*)keys
		  count: (size_t)count
{
	return [[[self alloc] initWithObjects: objects
				      forKeys: keys
					count: count] autorelease];
}

+ (instancetype)dictionaryWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [[[self alloc] initWithKey: firstKey
			       arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

- init
{
	if (object_getClass(self) == [OFDictionary class]) {
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

- initWithDictionary: (OFDictionary*)dictionary
{
	OF_INVALID_INIT_METHOD
}

- initWithObject: (id)object
	  forKey: (id)key
{
	if (key == nil || object == nil)
		@throw [OFInvalidArgumentException exception];

	return [self initWithKeysAndObjects: key, object, nil];
}

- initWithObjects: (OFArray*)objects_
	  forKeys: (OFArray*)keys_
{
	id *objects, *keys;
	size_t count;

	@try {
		count = [objects_ count];

		if (count != [keys_ count])
			@throw [OFInvalidArgumentException exception];

		objects = [objects_ objects];
		keys = [keys_ objects];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return [self initWithObjects: objects
			     forKeys: keys
			       count: count];
}

- initWithObjects: (id const*)objects
	  forKeys: (id const*)keys
	    count: (size_t)count
{
	OF_INVALID_INIT_METHOD
}

- initWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [self initWithKey: firstKey
		      arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithKey: (id)firstKey
    arguments: (va_list)arguments
{
	OF_INVALID_INIT_METHOD
}

- initWithSerialization: (OFXMLElement*)element
{
	OF_INVALID_INIT_METHOD
}

- (id)objectForKey: (id)key
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (id)objectForKeyedSubscript: (id)key
{
	return [self objectForKey: key];
}

- (size_t)count
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableDictionary alloc] initWithDictionary: self];
}

- (bool)isEqual: (id)object
{
	OFDictionary *otherDictionary;
	void *pool;
	OFEnumerator *enumerator;
	id key;

	if (![object isKindOfClass: [OFDictionary class]])
		return false;

	otherDictionary = object;

	if ([otherDictionary count] != [self count])
		return false;

	pool = objc_autoreleasePoolPush();

	enumerator = [self keyEnumerator];
	while ((key = [enumerator nextObject]) != nil) {
		id object = [otherDictionary objectForKey: key];

		if (object == nil ||
		    ![object isEqual: [self objectForKey: key]]) {
			objc_autoreleasePoolPop(pool);
			return false;
		}
	}

	objc_autoreleasePoolPop(pool);

	return true;
}

- (bool)containsObject: (id)object
{
	void *pool;
	OFEnumerator *enumerator;
	id currentObject;

	if (object == nil)
		return false;

	pool = objc_autoreleasePoolPush();
	enumerator = [self objectEnumerator];

	while ((currentObject = [enumerator nextObject]) != nil) {
		if ([currentObject isEqual: object]) {
			objc_autoreleasePoolPop(pool);
			return true;
		}
	}

	objc_autoreleasePoolPop(pool);

	return false;
}

- (bool)containsObjectIdenticalTo: (id)object
{
	void *pool;
	OFEnumerator *enumerator;
	id currentObject;

	if (object == nil)
		return false;

	pool = objc_autoreleasePoolPush();
	enumerator = [self objectEnumerator];

	while ((currentObject = [enumerator nextObject]) != nil) {
		if (currentObject == object) {
			objc_autoreleasePoolPop(pool);
			return true;
		}
	}

	objc_autoreleasePoolPop(pool);

	return false;
}

- (OFArray*)allKeys
{
	OFMutableArray *ret = [OFMutableArray arrayWithCapacity: [self count]];
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [self keyEnumerator];
	id key;

	while ((key = [enumerator nextObject]) != nil)
		[ret addObject: key];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFArray*)allObjects
{
	OFMutableArray *ret = [OFMutableArray arrayWithCapacity: [self count]];
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [self objectEnumerator];
	id object;

	while ((object = [enumerator nextObject]) != nil)
		[ret addObject: object];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFEnumerator*)objectEnumerator
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (OFEnumerator*)keyEnumerator
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

#if defined(OF_HAVE_BLOCKS) && defined(OF_HAVE_FAST_ENUMERATION)
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_dictionary_enumeration_block_t)block
{
	bool stop = false;

	for (id key in self) {
		block(key, [self objectForKey: key], &stop);

		if (stop)
			break;
	}
}
#endif

#ifdef OF_HAVE_BLOCKS
- (OFDictionary*)mappedDictionaryUsingBlock: (of_dictionary_map_block_t)block
{
	OFMutableDictionary *new = [OFMutableDictionary dictionary];

	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    bool *stop) {
		[new setObject: block(key, object)
			forKey: key];
	}];

	[new makeImmutable];

	return new;
}

- (OFDictionary*)filteredDictionaryUsingBlock:
    (of_dictionary_filter_block_t)block
{
	OFMutableDictionary *new = [OFMutableDictionary dictionary];

	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    bool *stop) {
		if (block(key, object))
			[new setObject: object
				forKey: key];
	}];

	[new makeImmutable];

	return new;
}
#endif

- (uint32_t)hash
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [self keyEnumerator];
	id key;
	uint32_t hash = 0;

	while ((key = [enumerator nextObject]) != nil) {
		hash += [key hash];
		hash += [[self objectForKey: key] hash];
	}

	objc_autoreleasePoolPop(pool);

	return hash;
}

- (OFString*)description
{
	OFMutableString *ret;
	void *pool;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	id key, object;
	size_t i, count = [self count];

	if (count == 0)
		return @"{}";

	ret = [OFMutableString stringWithString: @"{\n"];
	pool = objc_autoreleasePoolPush();
	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];

	i = 0;
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();

		[ret appendString: [key description]];
		[ret appendString: @" = "];
		[ret appendString: [object description]];

		if (++i < count)
			[ret appendString: @";\n"];

		objc_autoreleasePoolPop(pool2);
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendString: @";\n}"];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	id key, object;

	if ([self isKindOfClass: [OFMutableDictionary class]])
		element = [OFXMLElement elementWithName: @"OFMutableDictionary"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFDictionary"
					      namespace: OF_SERIALIZATION_NS];

	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	       (object = [objectEnumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();
		OFXMLElement *keyElement, *objectElement;

		keyElement = [OFXMLElement
		    elementWithName: @"key"
			  namespace: OF_SERIALIZATION_NS];
		[keyElement addChild: [key XMLElementBySerializing]];

		objectElement = [OFXMLElement
		    elementWithName: @"object"
			  namespace: OF_SERIALIZATION_NS];
		[objectElement addChild: [object XMLElementBySerializing]];

		[element addChild: keyElement];
		[element addChild: objectElement];

		objc_autoreleasePoolPop(pool2);
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (OFString*)JSONRepresentation
{
	OFMutableString *JSON = [OFMutableString stringWithString: @"{"];
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *keyEnumerator = [self keyEnumerator];
	OFEnumerator *objectEnumerator = [self objectEnumerator];
	size_t i = 0, count = [self count];
	OFString *key;
	OFString *object;

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();

		[JSON appendString: [key JSONRepresentation]];
		[JSON appendString: @":"];
		[JSON appendString: [object JSONRepresentation]];

		if (++i < count)
			[JSON appendString: @","];

		objc_autoreleasePoolPop(pool2);
	}

	[JSON appendString: @"}"];
	[JSON makeImmutable];

	objc_autoreleasePoolPop(pool);

	return JSON;
}

- (OFDataArray*)messagePackRepresentation
{
	OFDataArray *data;
	size_t i, count;
	void *pool;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	id key, object;

	data = [OFDataArray dataArray];
	count = [self count];

	if (count <= 15) {
		uint8_t tmp = 0x80 | ((uint8_t)count & 0xF);
		[data addItem: &tmp];
	} else if (count <= UINT16_MAX) {
		uint8_t type = 0xDE;
		uint16_t tmp = OF_BSWAP16_IF_LE((uint16_t)count);

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else if (count <= UINT32_MAX) {
		uint8_t type = 0xDF;
		uint32_t tmp = OF_BSWAP32_IF_LE((uint32_t)count);

		[data addItem: &type];
		[data addItems: &tmp
			 count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	i = 0;
	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();
		OFDataArray *child;

		i++;

		child = [key messagePackRepresentation];
		[data addItems: [child items]
			 count: [child count]];

		child = [object messagePackRepresentation];
		[data addItems: [child items]
			 count: [child count]];

		objc_autoreleasePoolPop(pool2);
	}

	assert(i == count);

	objc_autoreleasePoolPop(pool);

	return data;
}
@end
