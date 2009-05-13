/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <stdlib.h>

#import "OFAutoreleasePool.h"
#import "OFList.h"
#import "OFThread.h"
#import "OFExceptions.h"

static OFTLSKey *pool_list_key;

static void
release_list(void *list)
{
	of_list_object_t *first, *iter;
	IMP release;

	if ((first = [(OFList*)list first]) != NULL)
		release = [first->object methodFor: @selector(release)];

	for (iter = first; iter != NULL; iter = iter->next)
		release(iter->object, @selector(release));

	[(OFList*)list release];
}

@implementation OFAutoreleasePool
+ (void)initialize
{
	pool_list_key = [[OFTLSKey alloc] initWithDestructor: release_list];
}

+ (void)addToPool: (OFObject*)obj
{
	OFList *pool_list;

	@try {
		pool_list = [OFThread objectForTLSKey: pool_list_key];
	} @catch (OFNotInSetException *e) {
		[e dealloc];
		[[self alloc] init];
		pool_list = [OFThread objectForTLSKey: pool_list_key];
	}

	if ([pool_list last] == NULL)
		[[self alloc] init];

	if ([pool_list last] == NULL)
		@throw [OFInitializationFailedException newWithClass: self];

	[[pool_list last]->object addToPool: obj];
}

- init
{
	OFList *pool_list;

	self = [super init];

	objects = nil;

	@try {
		pool_list = [OFThread objectForTLSKey: pool_list_key];
	} @catch (OFNotInSetException *e) {
		[e dealloc];
		pool_list = [[OFList alloc] initWithoutRetainAndRelease];
		[OFThread setObject: pool_list
			  forTLSKey: pool_list_key];
		[pool_list release];
	}

	listobj = [pool_list append: self];

	return self;
}

- (void)dealloc
{
	/*
	 * FIXME:
	 * Maybe we should get the objects ourself, release them and then
	 * release the pool without calling its release method? This way,
	 * there wouldn't be a recursion.
	 */
	if (listobj->next != NULL)
		[listobj->next->object release];

	[[OFThread objectForTLSKey: pool_list_key] remove: listobj];

	[super dealloc];
}

- addToPool: (OFObject*)obj
{
	if (objects == nil)
		objects = [[OFArray alloc] init];

	[objects add: obj];
	[obj release];

	return self;
}

- release
{
	[self releaseObjects];

	return [super release];
}

- releaseObjects
{
	if (objects == nil)
		return self;

	[objects release];
	objects = nil;

	return self;
}

- retain
{
	// FIXME: Maybe another exception would be better here?
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- autorelease
{
	// FIXME: Maybe another exception would be better here?
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}
@end
