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

#include <assert.h>

#import "OFMapTableDictionary.h"
#import "OFArray.h"
#import "OFMapTable+Private.h"
#import "OFMapTable.h"
#import "OFMutableMapTableDictionary.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

static void *
copy(void *object)
{
	return [(id)object copy];
}

static void *
retain(void *object)
{
	return [(id)object retain];
}

static void
release(void *object)
{
	[(id)object release];
}

static uint32_t
hash(void *object)
{
	return [(id)object hash];
}

static bool
equal(void *object1, void *object2)
{
	return [(id)object1 isEqual: (id)object2];
}

static const of_map_table_functions_t keyFunctions = {
	.retain = copy,
	.release = release,
	.hash = hash,
	.equal = equal
};
static const of_map_table_functions_t objectFunctions = {
	.retain = retain,
	.release = release,
	.hash = hash,
	.equal = equal
};

@implementation OFMapTableDictionary
- (instancetype)init
{
	return [self initWithCapacity: 0];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	self = [super init];

	@try {
		_mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions
				capacity: capacity];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithDictionary: (OFDictionary *)dictionary
{
	size_t count;

	if (dictionary == nil)
		return [self init];

	if ([dictionary isKindOfClass: [OFMapTableDictionary class]] ||
	    [dictionary isKindOfClass: [OFMutableMapTableDictionary class]]) {
		self = [super init];

		@try {
			OFMapTableDictionary *dictionary_ =
			    (OFMapTableDictionary *)dictionary;

			_mapTable = [dictionary_->_mapTable copy];
		} @catch (id e) {
			[self release];
			@throw e;
		}

		return self;
	}

	@try {
		count = dictionary.count;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [self initWithCapacity: count];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFEnumerator *keyEnumerator, *objectEnumerator;
		id key, object;

		keyEnumerator = [dictionary keyEnumerator];
		objectEnumerator = [dictionary objectEnumerator];
		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[_mapTable setObject: object
				      forKey: key];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)object
			forKey: (id)key
{
	self = [self initWithCapacity: 1];

	@try {
		[_mapTable setObject: object
			      forKey: key];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithObjects: (id const *)objects
			forKeys: (id const *)keys
			  count: (size_t)count
{
	self = [self initWithCapacity: count];

	@try {
		size_t i;

		for (i = 0; i < count; i++)
			[_mapTable setObject: objects[i]
				      forKey: keys[i]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithKey: (id)firstKey
		  arguments: (va_list)arguments
{
	self = [super init];

	@try {
		va_list argumentsCopy;
		id key, object;
		size_t i, count;

		va_copy(argumentsCopy, arguments);

		if (firstKey == nil)
			@throw [OFInvalidArgumentException exception];

		key = firstKey;

		if ((object = va_arg(arguments, id)) == nil)
			@throw [OFInvalidArgumentException exception];

		count = 1;
		for (; va_arg(argumentsCopy, id) != nil; count++);

		if (count % 2 != 0)
			@throw [OFInvalidArgumentException exception];

		count /= 2;

		_mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions
				capacity: count];

		[_mapTable setObject: object
			      forKey: key];

		for (i = 1; i < count; i++) {
			key = va_arg(arguments, id);
			object = va_arg(arguments, id);

			if (key == nil || object == nil)
				@throw [OFInvalidArgumentException exception];

			[_mapTable setObject: object
				      forKey: key];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFArray *keys, *objects;
		OFEnumerator *keyEnumerator, *objectEnumerator;
		OFXMLElement *keyElement, *objectElement;

		keys = [element elementsForName: @"key"
				      namespace: OF_SERIALIZATION_NS];
		objects = [element elementsForName: @"object"
					 namespace: OF_SERIALIZATION_NS];

		if (keys.count != objects.count)
			@throw [OFInvalidFormatException exception];

		_mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: keyFunctions
			 objectFunctions: objectFunctions
				capacity: keys.count];

		keyEnumerator = [keys objectEnumerator];
		objectEnumerator = [objects objectEnumerator];
		while ((keyElement = [keyEnumerator nextObject]) != nil &&
		    (objectElement = [objectEnumerator nextObject]) != nil) {
			void *pool2 = objc_autoreleasePoolPush();
			OFXMLElement *key, *object;

			key = [keyElement elementsForNamespace:
			    OF_SERIALIZATION_NS].firstObject;
			object = [objectElement elementsForNamespace:
			    OF_SERIALIZATION_NS].firstObject;

			if (key == nil || object == nil)
				@throw [OFInvalidFormatException exception];

			[_mapTable setObject: object.objectByDeserializing
				      forKey: key.objectByDeserializing];

			objc_autoreleasePoolPop(pool2);
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_mapTable release];

	[super dealloc];
}

- (id)objectForKey: (id)key
{
	return [_mapTable objectForKey: key];
}

- (size_t)count
{
	return _mapTable.count;
}

- (bool)isEqual: (id)object
{
	OFMapTableDictionary *dictionary;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFMapTableDictionary class]] &&
	    ![object isKindOfClass: [OFMutableMapTableDictionary class]])
		return [super isEqual: object];

	dictionary = (OFMapTableDictionary *)object;

	return [dictionary->_mapTable isEqual: _mapTable];
}

- (bool)containsObject: (id)object
{
	return [_mapTable containsObject: object];
}

- (bool)containsObjectIdenticalTo: (id)object
{
	return [_mapTable containsObjectIdenticalTo: object];
}

- (OFArray *)allKeys
{
	OFArray *ret;
	id *keys;
	size_t count;

	count = _mapTable.count;
	keys = [self allocMemoryWithSize: sizeof(*keys)
				   count: count];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMapTableEnumerator *enumerator;
		void **keyPtr;
		size_t i;

		i = 0;
		enumerator = [_mapTable keyEnumerator];
		while ((keyPtr = [enumerator nextObject]) != NULL) {
			assert(i < count);

			keys[i++] = (id)*keyPtr;
		}

		objc_autoreleasePoolPop(pool);

		ret = [OFArray arrayWithObjects: keys
					  count: count];
	} @finally {
		[self freeMemory: keys];
	}

	return ret;
}

- (OFArray *)allObjects
{
	OFArray *ret;
	id *objects;
	size_t count;

	count = _mapTable.count;
	objects = [self allocMemoryWithSize: sizeof(*objects)
				      count: count];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMapTableEnumerator *enumerator;
		void **objectPtr;
		size_t i;

		i = 0;
		enumerator = [_mapTable objectEnumerator];
		while ((objectPtr = [enumerator nextObject]) != NULL) {
			assert(i < count);

			objects[i++] = (id)*objectPtr;
		}

		objc_autoreleasePoolPop(pool);

		ret = [OFArray arrayWithObjects: objects
					  count: count];
	} @finally {
		[self freeMemory: objects];
	}

	return ret;
}

- (OFEnumerator *)keyEnumerator
{
	return [[[OFMapTableEnumeratorWrapper alloc]
	    initWithEnumerator: [_mapTable keyEnumerator]
			object: self] autorelease];
}

- (OFEnumerator *)objectEnumerator
{
	return [[[OFMapTableEnumeratorWrapper alloc]
	    initWithEnumerator: [_mapTable objectEnumerator]
			object: self] autorelease];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id *)objects
			     count: (int)count
{
	return [_mapTable countByEnumeratingWithState: state
					      objects: objects
						count: count];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_dictionary_enumeration_block_t)block
{
	@try {
		[_mapTable enumerateKeysAndObjectsUsingBlock:
		    ^ (void *key, void *object, bool *stop) {
			block(key, object, stop);
		}];
	} @catch (OFEnumerationMutationException *e) {
		@throw [OFEnumerationMutationException
		    exceptionWithObject: self];
	}
}
#endif

- (uint32_t)hash
{
	return _mapTable.hash;
}
@end
