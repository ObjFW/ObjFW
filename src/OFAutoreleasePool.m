/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFAutoreleasePool.h"
#import "OFArray.h"

#import "OFInitializationFailedException.h"
#import "OFNotImplementedException.h"

#ifdef OF_THREADS
# import "threading.h"
static of_tlskey_t firstKey, lastKey;
#else
static OFAutoreleasePool *firstPool = nil, *lastPool = nil;
#endif

#define GROW_SIZE 16

@implementation OFAutoreleasePool
#ifdef OF_THREADS
+ (void)initialize
{
	if (self != [OFAutoreleasePool class])
		return;

	if (!of_tlskey_new(&firstKey) || !of_tlskey_new(&lastKey))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}
#endif

+ (void)addObject: (id)object
{
#ifdef OF_THREADS
	id lastPool = of_tlskey_get(lastKey);
#endif

	if (lastPool == nil) {
		@try {
			[[self alloc] init];
		} @catch (id e) {
			[object release];
			@throw e;
		}

#ifdef OF_THREADS
		lastPool = of_tlskey_get(lastKey);
#endif
	}

	if (lastPool == nil) {
		[object release];
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
	}

	@try {
		[lastPool _addObject: object];
	} @catch (id e) {
		[object release];
		@throw e;
	}
}

+ (void)_releaseAll
{
#ifdef OF_THREADS
	[of_tlskey_get(firstKey) release];
#else
	[firstPool release];
#endif
}

- init
{
	self = [super init];

	@try {
#ifdef OF_THREADS
		id firstPool = of_tlskey_get(firstKey);
		previousPool = of_tlskey_get(lastKey);

		if (!of_tlskey_set(lastKey, self))
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];
#else
		previousPool = lastPool;
		lastPool = self;
#endif

		if (firstPool == nil) {
#ifdef OF_THREADS
			if (!of_tlskey_set(firstKey, self)) {
				of_tlskey_set(lastKey, previousPool);
				@throw [OFInitializationFailedException
				    exceptionWithClass: [self class]];
			}
#else
			firstPool = self;
#endif
		}

		if (previousPool != nil)
			previousPool->nextPool = self;

		size = GROW_SIZE;
		objects = [self allocMemoryWithSize: sizeof(id)
					      count: GROW_SIZE];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)_addObject: (id)object
{
	if (count + 1 > size) {
		objects = [self resizeMemory: objects
					size: sizeof(id)
				       count: size + GROW_SIZE];
		size += GROW_SIZE;
	}

	objects[count] = object;
	count++;
}

- (void)releaseObjects
{
	size_t i;

	[nextPool releaseObjects];

	for (i = 0; i < count; i++)
		[objects[i] release];

	count = 0;
}

- (void)release
{
	[self dealloc];
}

- (void)drain
{
	[self dealloc];
}

- (void)dealloc
{
	size_t i;

	[nextPool dealloc];

	for (i = 0; i < count; i++)
		[objects[i] release];

	/*
	 * If of_tlskey_set fails, this is a real problem. The best we can do
	 * is to not change the pool below the current pool and stop
	 * deallocation. This way, new objects will be added to the current
	 * pool, but released when the pool below gets released - and maybe
	 * the pool itself will be released as well then, because maybe
	 * of_tlskey_set will work this time.
	 */
#ifdef OF_THREADS
	if (!of_tlskey_set(lastKey, previousPool))
		return;
#else
	lastPool = previousPool;
#endif

	if (previousPool != nil)
		previousPool->nextPool = nil;

	/*
	 * If of_tlskey_set fails here, this is even worse, as this will
	 * definitely be a memory leak. But this should never happen anyway.
	 */
#ifdef OF_THREADS
	if (of_tlskey_get(firstKey) == self)
		if (!of_tlskey_set(firstKey, nil))
			return;
#else
	if (firstPool == self)
		firstPool = nil;
#endif

	[super dealloc];
}

- retain
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}

- autorelease
{
	@throw [OFNotImplementedException exceptionWithClass: [self class]
						    selector: _cmd];
}
@end
