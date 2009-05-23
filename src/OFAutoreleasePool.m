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
	if (self != [OFAutoreleasePool class])
		return;

	pool_list_key = [[OFTLSKey alloc] initWithDestructor: release_list];
}

+ (void)addObjectToTopmostPool: (OFObject*)obj
{
	OFList *pool_list = [OFThread objectForTLSKey: pool_list_key];

	if (pool_list == nil || [pool_list last] == NULL) {
		@try {
			[[self alloc] init];
			pool_list = [OFThread objectForTLSKey: pool_list_key];
		} @catch (OFException *e) {
			[obj release];
			@throw e;
		}
	}

	if (pool_list == nil || [pool_list last] == NULL) {
		[obj release];
		@throw [OFInitializationFailedException newWithClass: self];
	}

	@try {
		[[pool_list last]->object addObject: obj];
	} @catch (OFException *e) {
		[obj release];
		@throw e;
	}
}

- init
{
	OFList *pool_list;

	self = [super init];

	if ((pool_list = [OFThread objectForTLSKey: pool_list_key]) == nil) {
		@try {
			pool_list = [[OFList alloc]
			    initWithoutRetainAndRelease];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		}

		@try {
			[OFThread setObject: pool_list
				  forTLSKey: pool_list_key];
		} @catch (OFException *e) {
			[self dealloc];
			@throw e;
		} @finally {
			[pool_list release];
		}
	}

	@try {
		listobj = [pool_list append: self];
	} @catch (OFException *e) {
		[self dealloc];
		@throw e;
	}

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

	[self releaseObjects];

	[[OFThread objectForTLSKey: pool_list_key] remove: listobj];

	[super dealloc];
}

- addObject: (OFObject*)obj
{
	if (objects == nil)
		objects = [[OFMutableArray alloc] init];

	[objects addObject: obj];
	[obj release];

	return self;
}

- (void)release
{
	[self releaseObjects];
	[super release];
}

- releaseObjects
{
	if (listobj->next != NULL)
		[listobj->next->object releaseObjects];

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
