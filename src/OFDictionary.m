/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include <stdlib.h>

#import "OFDictionary.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFConcreteDictionary.h"
#import "OFData.h"
#import "OFEnumerator.h"
#import "OFJSONRepresentationPrivate.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"
#import "OFUndefinedKeyException.h"

@interface OFDictionary () <OFJSONRepresentationPrivate>
@end

@interface OFPlaceholderDictionary: OFDictionary
@end

@interface OFConcreteDictionarySingleton: OFConcreteDictionary
@end

OF_DIRECT_MEMBERS
@interface OFDictionaryObjectEnumerator: OFEnumerator
{
	OFDictionary *_dictionary;
	OFEnumerator *_keyEnumerator;
}

- (instancetype)initWithDictionary: (OFDictionary *)dictionary;
@end

static struct {
	Class isa;
} placeholder;

static OFConcreteDictionarySingleton *emptyDictionary;

static void
emptyDictionaryInit(void)
{
	emptyDictionary = [[OFConcreteDictionarySingleton alloc] init];
}

@implementation OFPlaceholderDictionary
#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)init
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, emptyDictionaryInit);
	return (id)emptyDictionary;
}

- (instancetype)initWithDictionary: (OFDictionary *)dictionary
{
	return (id)[[OFConcreteDictionary alloc]
	    initWithDictionary: dictionary];
}

- (instancetype)initWithObject: (id)object forKey: (id)key
{
	return (id)[[OFConcreteDictionary alloc] initWithObject: object
							 forKey: key];
}

- (instancetype)initWithObjects: (OFArray *)objects forKeys: (OFArray *)keys
{
	return (id)[[OFConcreteDictionary alloc] initWithObjects: objects
							 forKeys: keys];
}

- (instancetype)initWithObjects: (id const *)objects
			forKeys: (id const *)keys
			  count: (size_t)count
{
	return (id)[[OFConcreteDictionary alloc] initWithObjects: objects
							 forKeys: keys
							   count: count];
}

- (instancetype)initWithKeysAndObjects: (id <OFCopying>)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [[OFConcreteDictionary alloc] initWithKey: firstKey
					      arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithKey: (id <OFCopying>)firstKey
		  arguments: (va_list)arguments
{
	return (id)[[OFConcreteDictionary alloc] initWithKey: firstKey
						   arguments: arguments];
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

OF_SINGLETON_METHODS
@end

@implementation OFConcreteDictionarySingleton
OF_SINGLETON_METHODS
@end

@implementation OFDictionary
+ (void)initialize
{
	if (self == [OFDictionary class])
		object_setClass((id)&placeholder,
		    [OFPlaceholderDictionary class]);
}

+ (instancetype)alloc
{
	if (self == [OFDictionary class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)dictionary
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

+ (instancetype)dictionaryWithDictionary: (OFDictionary *)dictionary
{
	return objc_autoreleaseReturnValue(
	    [(OFDictionary *)[self alloc] initWithDictionary: dictionary]);
}

+ (instancetype)dictionaryWithObject: (id)object forKey: (id)key
{
	return objc_autoreleaseReturnValue([[self alloc] initWithObject: object
								 forKey: key]);
}

+ (instancetype)dictionaryWithObjects: (OFArray *)objects
			      forKeys: (OFArray *)keys
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithObjects: objects
				  forKeys: keys]);
}

+ (instancetype)dictionaryWithObjects: (id const *)objects
			      forKeys: (id const *)keys
				count: (size_t)count
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithObjects: objects
				  forKeys: keys
				    count: count]);
}

+ (instancetype)dictionaryWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [[self alloc] initWithKey: firstKey arguments: arguments];
	va_end(arguments);

	return objc_autoreleaseReturnValue(ret);
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFDictionary class]] ||
	    [self isMemberOfClass: [OFMutableDictionary class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (instancetype)initWithDictionary: (OFDictionary *)dictionary
{
	void *pool = objc_autoreleasePoolPush();
	id const *objects, *keys;
	size_t count;

	@try {
		OFArray *objects_ = [dictionary.objectEnumerator allObjects];
		OFArray *keys_ = [dictionary.keyEnumerator allObjects];

		count = dictionary.count;

		if (count != keys_.count || count != objects_.count)
			@throw [OFInvalidArgumentException exception];

		objects = objects_.objects;
		keys = keys_.objects;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	@try {
		self = [self initWithObjects: objects
				     forKeys: keys
				       count: count];
	} @finally {
		objc_autoreleasePoolPop(pool);
	}

	return self;
}

- (instancetype)initWithObject: (id)object forKey: (id)key
{
	@try {
		if (key == nil || object == nil)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return [self initWithObjects: &object forKeys: &key count: 1];
}

- (instancetype)initWithObjects: (OFArray *)objects_ forKeys: (OFArray *)keys_
{
	void *pool = objc_autoreleasePoolPush();
	id const *objects, *keys;
	size_t count;

	@try {
		count = objects_.count;

		if (count != keys_.count)
			@throw [OFInvalidArgumentException exception];

		objects = objects_.objects;
		keys = keys_.objects;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithObjects: objects forKeys: keys count: count];

	objc_autoreleasePoolPop(pool);

	return self;
}

#ifdef __clang__
/* We intentionally don't call into super, so silence the warning. */
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#endif
- (instancetype)initWithObjects: (id const *)objects
			forKeys: (id const *)keys
			  count: (size_t)count
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (instancetype)initWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [self initWithKey: firstKey arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithKey: (id)firstKey arguments: (va_list)arguments
{
	size_t count = 1;
	id *objects = NULL, *keys = NULL;
	va_list argumentsCopy;

	if (firstKey == nil)
		return [self init];

	va_copy(argumentsCopy, arguments);
	while (va_arg(argumentsCopy, id) != nil)
		count++;

	@try {
		size_t i = 0;
		id key, object;

		if (count % 2 != 0)
			@throw [OFInvalidArgumentException exception];

		count /= 2;

		objects = OFAllocMemory(count, sizeof(id));
		keys = OFAllocMemory(count, sizeof(id));

		keys[i] = firstKey;
		objects[i] = va_arg(arguments, id);

		if (objects[i] == nil)
			@throw [OFInvalidArgumentException exception];

		i++;

		while ((key = va_arg(arguments, id)) != nil &&
		    (object = va_arg(arguments, id)) != nil) {
			OFEnsure(i < count);

			objects[i] = object;
			keys[i] = key;

			i++;
		}
	} @catch (id e) {
		OFFreeMemory(objects);
		OFFreeMemory(keys);

		objc_release(self);
		@throw e;
	}

	@try {
		self = [self initWithObjects: objects
				     forKeys: keys
				       count: count];
	} @finally {
		OFFreeMemory(objects);
		OFFreeMemory(keys);
	}

	return self;
}

- (id)objectForKey: (id)key
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)objectForKeyedSubscript: (id)key
{
	return [self objectForKey: key];
}

- (id)valueForKey: (OFString *)key
{
	if ([key isEqual: @"@count"])
		return [super valueForKey: @"count"];

	return [self objectForKey: key];
}

- (void)setValue: (id)value forKey: (OFString *)key
{
	if (![self isKindOfClass: [OFMutableDictionary class]])
		@throw [OFUndefinedKeyException exceptionWithObject: self
								key: key
							      value: value];

	[(OFMutableDictionary *)self setObject: value forKey: key];
}

- (size_t)count
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id)copy
{
	return objc_retain(self);
}

- (id)mutableCopy
{
	return [[OFMutableDictionary alloc] initWithDictionary: self];
}

- (bool)isEqual: (id)object
{
	OFDictionary *otherDictionary;
	void *pool;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	id key;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFDictionary class]])
		return false;

	otherDictionary = object;

	if (otherDictionary.count != self.count)
		return false;

	pool = objc_autoreleasePoolPush();

	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		id otherObject = [otherDictionary objectForKey: key];

		if (otherObject == nil || ![otherObject isEqual: object]) {
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

- (OFArray *)allKeys
{
	OFMutableArray *ret = [OFMutableArray arrayWithCapacity: self.count];

	for (id key in self)
		[ret addObject: key];

	[ret makeImmutable];

	return ret;
}

- (OFArray *)allObjects
{
	OFMutableArray *ret = [OFMutableArray arrayWithCapacity: self.count];
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *enumerator = [self objectEnumerator];
	id object;

	while ((object = [enumerator nextObject]) != nil)
		[ret addObject: object];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (OFEnumerator *)keyEnumerator
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFEnumerator *)objectEnumerator
{
	return objc_autoreleaseReturnValue(
	    [[OFDictionaryObjectEnumerator alloc] initWithDictionary: self]);
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state
			   objects: (id *)objects
			     count: (int)count
{
	static unsigned long dummyMutations;
	OFEnumerator *enumerator;
	int i;

	memcpy(&enumerator, state->extra, sizeof(enumerator));

	if (enumerator == nil) {
		enumerator = [self keyEnumerator];
		memcpy(state->extra, &enumerator, sizeof(enumerator));
	}

	state->itemsPtr = objects;
	state->mutationsPtr = &dummyMutations;

	for (i = 0; i < count; i++) {
		id object = [enumerator nextObject];

		if (object == nil)
			return i;

		objects[i] = object;
	}

	return i;
}

#ifdef OF_HAVE_BLOCKS
- (void)enumerateKeysAndObjectsUsingBlock: (OFDictionaryEnumerationBlock)block
{
	bool stop = false;

	for (id key in self) {
		block(key, [self objectForKey: key], &stop);

		if (stop)
			break;
	}
}

- (OFDictionary *)mappedDictionaryUsingBlock: (OFDictionaryMapBlock)block
{
	OFMutableDictionary *new = [OFMutableDictionary dictionary];

	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    bool *stop) {
		[new setObject: block(key, object) forKey: key];
	}];

	[new makeImmutable];

	return new;
}

- (OFDictionary *)filteredDictionaryUsingBlock: (OFDictionaryFilterBlock)block
{
	OFMutableDictionary *new = [OFMutableDictionary dictionary];

	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    bool *stop) {
		if (block(key, object))
			[new setObject: object forKey: key];
	}];

	[new makeImmutable];

	return new;
}
#endif

- (unsigned long)hash
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator *keyEnumerator = [self keyEnumerator];
	OFEnumerator *objectEnumerator = [self objectEnumerator];
	id key, object;
	unsigned long hash = 0;

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		hash ^= [key hash];
		hash ^= [object hash];
	}

	objc_autoreleasePoolPop(pool);

	return hash;
}

- (OFString *)description
{
	OFMutableString *ret;
	void *pool;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFObject *key, *object;
	size_t i, count = self.count;

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

		[ret appendString: key.description];
		[ret appendString: @" = "];
		[ret appendString: object.description];

		if (++i < count)
			[ret appendString: @";\n"];

		objc_autoreleasePoolPop(pool2);
	}
	[ret replaceOccurrencesOfString: @"\n" withString: @"\n\t"];
	[ret appendString: @";\n}"];

	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
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
	OFMutableString *JSON = [OFMutableString stringWithString: @"{"];
	void *pool = objc_autoreleasePoolPush();
	OFArray *keys = self.allKeys;
	size_t i, count = self.count;

	if (options & OFJSONRepresentationOptionSorted)
		keys = keys.sortedArray;

	if (options & OFJSONRepresentationOptionPretty) {
		OFMutableString *indentation = [OFMutableString string];

		for (i = 0; i < depth; i++)
			[indentation appendString: @"\t"];

		[JSON appendString: @"\n"];

		i = 0;
		for (id key in keys) {
			void *pool2 = objc_autoreleasePoolPush();
			id object = [self objectForKey: key];
			int identifierOptions =
			    options | OFJSONRepresentationOptionIsIdentifier;

			if (![key isKindOfClass: [OFString class]])
				@throw [OFInvalidArgumentException exception];

			[JSON appendString: indentation];
			[JSON appendString: @"\t"];
			[JSON appendString: [key
			    of_JSONRepresentationWithOptions: identifierOptions
						       depth: depth + 1]];
			[JSON appendString: @": "];
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
		for (id key in keys) {
			void *pool2 = objc_autoreleasePoolPush();
			id object = [self objectForKey: key];
			int identifierOptions =
			    options | OFJSONRepresentationOptionIsIdentifier;

			if (![key isKindOfClass: [OFString class]])
				@throw [OFInvalidArgumentException exception];

			[JSON appendString: [key
			    of_JSONRepresentationWithOptions: identifierOptions
						       depth: depth + 1]];
			[JSON appendString: @":"];
			[JSON appendString: [object
			    of_JSONRepresentationWithOptions: options
						       depth: depth + 1]];

			if (++i < count)
				[JSON appendString: @","];

			objc_autoreleasePoolPop(pool2);
		}
	}

	[JSON appendString: @"}"];
	[JSON makeImmutable];

	objc_autoreleasePoolPop(pool);

	return JSON;
}

- (OFData *)messagePackRepresentation
{
	OFMutableData *data;
	size_t i, count;
	void *pool;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	id <OFMessagePackRepresentation> key, object;

	data = [OFMutableData data];
	count = self.count;

	if (count <= 15) {
		uint8_t tmp = 0x80 | ((uint8_t)count & 0xF);
		[data addItem: &tmp];
	} else if (count <= UINT16_MAX) {
		uint8_t type = 0xDE;
		uint16_t tmp = OFToBigEndian16((uint16_t)count);

		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else if (count <= UINT32_MAX) {
		uint8_t type = 0xDF;
		uint32_t tmp = OFToBigEndian32((uint32_t)count);

		[data addItem: &type];
		[data addItems: &tmp count: sizeof(tmp)];
	} else
		@throw [OFOutOfRangeException exception];

	pool = objc_autoreleasePoolPush();

	i = 0;
	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		void *pool2 = objc_autoreleasePoolPush();
		OFData *child;

		i++;

		child = key.messagePackRepresentation;
		[data addItems: child.items count: child.count];

		child = object.messagePackRepresentation;
		[data addItems: child.items count: child.count];

		objc_autoreleasePoolPop(pool2);
	}

	OFAssert(i == count);

	[data makeImmutable];

	objc_autoreleasePoolPop(pool);

	return data;
}
@end

@implementation OFDictionaryObjectEnumerator
- (instancetype)initWithDictionary: (OFDictionary *)dictionary
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_dictionary = objc_retain(dictionary);
		_keyEnumerator = objc_retain([_dictionary keyEnumerator]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_dictionary);
	objc_release(_keyEnumerator);

	[super dealloc];
}

- (id)nextObject
{
	id key = [_keyEnumerator nextObject];
	id object;

	if (key == nil)
		return nil;

	if ((object = [_dictionary objectForKey: key]) == nil)
		@throw [OFInvalidArgumentException exception];

	return object;
}
@end
