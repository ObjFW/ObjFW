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

#include <stdlib.h>

#import "OFConcreteMutableDictionary.h"
#import "OFArray.h"
#import "OFString.h"

static struct {
	Class isa;
} placeholder;

@interface OFPlaceholderMutableDictionary: OFDictionary
@end

@implementation OFPlaceholderMutableDictionary
- (instancetype)init
{
	return (id)[[OFConcreteMutableDictionary alloc] init];
}

- (instancetype)initWithDictionary: (OFDictionary *)dictionary
{
	return (id)[[OFConcreteMutableDictionary alloc]
	    initWithDictionary: dictionary];
}

- (instancetype)initWithObject: (id)object forKey: (id)key
{
	return (id)[[OFConcreteMutableDictionary alloc] initWithObject: object
								forKey: key];
}

- (instancetype)initWithObjects: (OFArray *)objects forKeys: (OFArray *)keys
{
	return (id)[[OFConcreteMutableDictionary alloc] initWithObjects: objects
								forKeys: keys];
}

- (instancetype)initWithObjects: (id const *)objects
			forKeys: (id const *)keys
			  count: (size_t)count
{
	return (id)[[OFConcreteMutableDictionary alloc] initWithObjects: objects
								forKeys: keys
								  count: count];
}

- (instancetype)initWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = (id)[[OFConcreteMutableDictionary alloc] initWithKey: firstKey
							 arguments: arguments];
	va_end(arguments);

	return ret;
}

- (instancetype)initWithKey: (id)firstKey arguments: (va_list)arguments
{
	return (id)[[OFConcreteMutableDictionary alloc] initWithKey: firstKey
							  arguments: arguments];
}

- (instancetype)initWithCapacity: (size_t)capacity
{
	return (id)[[OFConcreteMutableDictionary alloc]
	    initWithCapacity: capacity];
}

OF_SINGLETON_METHODS
@end

@implementation OFMutableDictionary
+ (void)initialize
{
	if (self == [OFMutableDictionary class])
		object_setClass((id)&placeholder,
		    [OFPlaceholderMutableDictionary class]);
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
	return [super init];
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

- (instancetype)initWithCapacity: (size_t)capacity
{
	OF_INVALID_INIT_METHOD
}
#ifdef __clang__
# pragma clang diagnostic pop
#endif

- (void)setObject: (id)object forKey: (id)key
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setObject: (id)object forKeyedSubscript: (id)key
{
	if (object != nil)
		[self setObject: object forKey: key];
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
		[self setObject: object forKey: key];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (OFDictionaryReplaceBlock)block
{
	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    bool *stop) {
		id new = block(key, object);

		if (new != object) {
			[self setObject: block(key, object) forKey: key];
		}
	}];
}
#endif

- (void)makeImmutable
{
}
@end
