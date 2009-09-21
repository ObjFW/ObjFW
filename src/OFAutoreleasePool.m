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

#include "config.h"

#include <stdlib.h>

#import "OFAutoreleasePool.h"
#import "OFList.h"
#import "OFThread.h"
#import "OFExceptions.h"

#import "threading.h"

/*
 * Pay special attention to NULL and nil in this file, they might be different!
 * Use NULL for TLS values and nil for instance variables.
 */

static of_tlskey_t first_key, last_key;

#ifndef _WIN32 /* Not used on Win32 yet */
static void
release_all(id obj)
{
	[of_tlskey_get(first_key) release];
}
#endif

@implementation OFAutoreleasePool
+ (void)initialize
{
	if (self != [OFAutoreleasePool class])
		return;

	if (!of_tlskey_new(&first_key, release_all) ||
	    !of_tlskey_new(&last_key, NULL))
		@throw [OFInitializationFailedException newWithClass: self];
}

+ (void)addObjectToTopmostPool: (OFObject*)obj
{
	id last = of_tlskey_get(last_key);

	if (last == nil) {
		@try {
			[[self alloc] init];
		} @catch (OFException *e) {
			[obj release];
			@throw e;
		}

		last = of_tlskey_get(last_key);
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

- init
{
	id first;

	self = [super init];

	first = of_tlskey_get(first_key);
	prev = of_tlskey_get(last_key);

	if (!of_tlskey_set(last_key, self)) {
		Class c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	if (first == nil) {
		if (!of_tlskey_set(first_key, self)) {
			Class c = isa;

			of_tlskey_set(last_key, prev);

			[super dealloc];
			@throw [OFInitializationFailedException
			    newWithClass: c];
		}
	}

	if (prev != nil)
		prev->next = self;

	return self;
}

- (void)dealloc
{
	[next dealloc];

	if (prev != nil)
		prev->next = nil;

	/* FIXME: Add exception? */
	of_tlskey_set(last_key, prev);
	if (of_tlskey_get(first_key) == self)
		of_tlskey_set(first_key, nil);

	[objects release];

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

- releaseObjects
{
	[next releaseObjects];

	if (objects == nil)
		return self;

	[objects release];
	objects = nil;

	return self;
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
