/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFConcreteDictionary.h"
#import "OFArray.h"
#import "OFConcreteMutableDictionary.h"
#import "OFMapTable+Private.h"
#import "OFMapTable.h"
#import "OFString.h"

#import "OFEnumerationMutationException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

static void *
copy(void *object)
{
	return [(id)object copy];
}

static unsigned long
hash(void *object)
{
	return [(id)object hash];
}

static bool
equal(void *object1, void *object2)
{
	return [(id)object1 isEqual: (id)object2];
}

static const OFMapTableFunctions keyFunctions = {
	.retain = copy,
	.release = (void (*)(void *))objc_release,
	.hash = hash,
	.equal = equal
};
static const OFMapTableFunctions objectFunctions = {
	.retain = (void *(*)(void *))objc_retain,
	.release = (void (*)(void *))objc_release,
	.hash = hash,
	.equal = equal
};

@implementation OFConcreteDictionary
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
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithDictionary: (OFDictionary *)dictionary
{
	size_t count;

	if (dictionary == nil)
		return [self init];

	if ([dictionary isKindOfClass: [OFConcreteDictionary class]] ||
	    [dictionary isKindOfClass: [OFConcreteMutableDictionary class]]) {
		self = [super init];

		@try {
			OFConcreteDictionary *dictionary_ =
			    (OFConcreteDictionary *)dictionary;

			_mapTable = [dictionary_->_mapTable copy];
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}

		return self;
	}

	@try {
		count = dictionary.count;
	} @catch (id e) {
		objc_release(self);
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
			[_mapTable setObject: object forKey: key];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithObject: (id)object forKey: (id)key
{
	self = [self initWithCapacity: 1];

	@try {
		[_mapTable setObject: object forKey: key];
	} @catch (id e) {
		objc_release(self);
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
			[_mapTable setObject: objects[i] forKey: keys[i]];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithKey: (id)firstKey arguments: (va_list)arguments
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

		[_mapTable setObject: object forKey: key];

		for (i = 1; i < count; i++) {
			key = va_arg(arguments, id);
			object = va_arg(arguments, id);

			if (key == nil || object == nil)
				@throw [OFInvalidArgumentException exception];

			[_mapTable setObject: object forKey: key];
		}
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_mapTable);

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
	OFConcreteDictionary *dictionary;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFConcreteDictionary class]] &&
	    ![object isKindOfClass: [OFConcreteMutableDictionary class]])
		return [super isEqual: object];

	dictionary = (OFConcreteDictionary *)object;

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
	keys = OFAllocMemory(count, sizeof(*keys));

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMapTableEnumerator *enumerator;
		void **keyPtr;
		size_t i;

		i = 0;
		enumerator = [_mapTable keyEnumerator];
		while ((keyPtr = [enumerator nextObject]) != NULL) {
			OFAssert(i < count);

			keys[i++] = (id)*keyPtr;
		}

		objc_autoreleasePoolPop(pool);

		ret = [OFArray arrayWithObjects: keys count: count];
	} @finally {
		OFFreeMemory(keys);
	}

	return ret;
}

- (OFArray *)allObjects
{
	OFArray *ret;
	id *objects;
	size_t count;

	count = _mapTable.count;
	objects = OFAllocMemory(count, sizeof(*objects));

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMapTableEnumerator *enumerator;
		void **objectPtr;
		size_t i;

		i = 0;
		enumerator = [_mapTable objectEnumerator];
		while ((objectPtr = [enumerator nextObject]) != NULL) {
			OFAssert(i < count);

			objects[i++] = (id)*objectPtr;
		}

		objc_autoreleasePoolPop(pool);

		ret = [OFArray arrayWithObjects: objects count: count];
	} @finally {
		OFFreeMemory(objects);
	}

	return ret;
}

- (OFEnumerator *)keyEnumerator
{
	return objc_autoreleaseReturnValue([[OFMapTableEnumeratorWrapper alloc]
	    initWithEnumerator: [_mapTable keyEnumerator]
			object: self]);
}

- (OFEnumerator *)objectEnumerator
{
	return objc_autoreleaseReturnValue([[OFMapTableEnumeratorWrapper alloc]
	    initWithEnumerator: [_mapTable objectEnumerator]
			object: self]);
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	return [_mapTable countByEnumeratingWithState: state
					      objects: objects
						count: count];
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateKeysAndObjectsUsingBlock: (OFDictionaryEnumerationBlock)block
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

- (unsigned long)hash
{
	return _mapTable.hash;
}
@end
