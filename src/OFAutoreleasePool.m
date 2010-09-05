/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdlib.h>

#import "OFAutoreleasePool.h"
#import "OFArray.h"
#import "OFExceptions.h"

#ifdef OF_THREADS
# import "threading.h"

#define GROW_SIZE 16

static of_tlskey_t first_key, last_key;
#else
static OFAutoreleasePool *first = nil, *last = nil;
#endif

@implementation OFAutoreleasePool
#ifdef OF_THREADS
+ (void)initialize
{
	if (self != [OFAutoreleasePool class])
		return;

	if (!of_tlskey_new(&first_key) || !of_tlskey_new(&last_key))
		@throw [OFInitializationFailedException newWithClass: self];
}
#endif

+ (void)addObjectToTopmostPool: (id)obj
{
#ifdef OF_THREADS
	id last = of_tlskey_get(last_key);
#endif

	if (last == nil) {
		@try {
			[[self alloc] init];
		} @catch (OFException *e) {
			[obj release];
			@throw e;
		}

#ifdef OF_THREADS
		last = of_tlskey_get(last_key);
#endif
	}

	if (last == nil) {
		[obj release];
		@throw [OFInitializationFailedException newWithClass: self];
	}

	@try {
		[last addObject: obj];
	} @catch (OFException *e) {
		[obj release];
		@throw e;
	}
}

+ (void)releaseAll
{
#ifdef OF_THREADS
	[of_tlskey_get(first_key) release];
#else
	[first release];
#endif
}

- init
{
#ifdef OF_THREADS
	id first;
#endif

	self = [super init];

#ifdef OF_THREADS
	first = of_tlskey_get(first_key);
	prev = of_tlskey_get(last_key);

	if (!of_tlskey_set(last_key, self)) {
		Class c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}
#else
	prev = last;
	last = self;
#endif

	if (first == nil) {
#ifdef OF_THREADS
		if (!of_tlskey_set(first_key, self)) {
			Class c = isa;

			of_tlskey_set(last_key, prev);

			[super dealloc];
			@throw [OFInitializationFailedException
			    newWithClass: c];
		}
#else
		first = self;
#endif
	}

	if (prev != nil)
		prev->next = self;

	size = GROW_SIZE;
	@try {
		objects = [self allocMemoryForNItems: GROW_SIZE
					    withSize: sizeof(id)];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

	return self;
}

- (void)addObject: (id)obj
{
	if (count + 1 > size) {
		objects = [self resizeMemory: objects
				    toNItems: size + GROW_SIZE
				    withSize: sizeof(id)];
		size += GROW_SIZE;
	}

	objects[count] = obj;
	count++;
}

- (void)releaseObjects
{
	size_t i;

	[next releaseObjects];

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

	[next dealloc];

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
	if (!of_tlskey_set(last_key, prev))
		return;
#else
	last = prev;
#endif

	if (prev != nil)
		prev->next = nil;

	/*
	 * If of_tlskey_set fails here, this is even worse, as this will
	 * definitely be a memory leak. But this should never happen anyway.
	 */
#ifdef OF_THREADS
	if (of_tlskey_get(first_key) == self)
		if (!of_tlskey_set(first_key, nil))
			return;
#else
	if (first == self)
		first = nil;
#endif

	[super dealloc];
}

- retain
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- autorelease
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}
@end
