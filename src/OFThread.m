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

#import "OFThread.h"
#import "OFExceptions.h"

#import "threading.h"

static id
call_main(id obj)
{
	/*
	 * Nasty workaround for thread implementations which can't return a
	 * value on join.
	 */
	((OFThread*)obj)->retval = [obj main];

	return 0;
}

@implementation OFThread
+ threadWithObject: (id)obj
{
	return [[[self alloc] initWithObject: obj] autorelease];
}

+ setObject: (id)obj
  forTLSKey: (OFTLSKey*)key
{
	id old = of_tlskey_get(key->key);

	if (!of_tlskey_set(key->key, [obj retain]))
		/* FIXME: Maybe another exception would be better */
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	[old release];

	return self;
}

+ (id)objectForTLSKey: (OFTLSKey*)key
{
	return [[of_tlskey_get(key->key) retain] autorelease];
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithObject: (id)obj
{
	self = [super init];
	object = [obj copy];

	if (!of_thread_new(&thread, call_main, self)) {
		Class c = isa;
		[object release];
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	running = YES;

	return self;
}

- main
{
	return nil;
}

- join
{
	of_thread_join(thread);
	running = NO;

	return retval;
}

- (void)dealloc
{
	/*
	 * No need to handle errors - if canceling the thread fails, we can't
	 * do anything anyway. Most likely, it finished already or was already
	 * canceled.
	 */
	if (running)
		of_thread_cancel(thread);

	[object release];
	[super dealloc];
}
@end

@implementation OFTLSKey
+ tlsKey
{
	return [[[self alloc] init] autorelease];
}

+ tlsKeyWithDestructor: (void(*)(id))destructor
{
	return [[[self alloc] initWithDestructor: destructor] autorelease];
}

- init
{
	self = [super init];

	if (!of_tlskey_new(&key, NULL)) {
		Class c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	return self;
}

- initWithDestructor: (void(*)(id))destructor
{
	self = [super init];

	/* FIXME: Call destructor on Win32 */
	if (!of_tlskey_new(&key, destructor)) {
		Class c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	return self;
}

/* FIXME: Add dealloc! */
@end

@implementation OFMutex
+ mutex
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	if (!of_mutex_new(&mutex)) {
		Class c = isa;
		[self dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	return self;
}

- lock
{
	/* FIXME: Add error-handling */
	of_mutex_lock(&mutex);

	return self;
}

- unlock
{
	/* FIXME: Add error-handling */
	of_mutex_unlock(&mutex);

	return self;
}

- (void)dealloc
{
	/* FIXME: Add error-handling */
	of_mutex_free(&mutex);

	[super dealloc];
}
@end
