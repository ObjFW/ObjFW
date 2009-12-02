/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#import "OFThread.h"
#import "OFList.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#import "threading.h"

static OFList *tlskeys;

static id
call_main(id obj)
{
	/*
	 * Nasty workaround for thread implementations which can't return a
	 * value on join.
	 */
	((OFThread*)obj)->retval = [obj main];

	[OFTLSKey callAllDestructors];
	[OFAutoreleasePool releaseAll];

	return 0;
}

@implementation OFThread
+ threadWithObject: (OFObject <OFCopying>*)obj
{
	return [[[self alloc] initWithObject: obj] autorelease];
}

+ setObject: (OFObject*)obj
  forTLSKey: (OFTLSKey*)key
{
	id old = of_tlskey_get(key->key);

	if (!of_tlskey_set(key->key, [obj retain]))
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

- initWithObject: (OFObject <OFCopying>*)obj
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
+ (void)initialize
{
	if (self == [OFTLSKey class])
		tlskeys = [[OFList alloc] init];
}

+ tlsKey
{
	return [[[self alloc] init] autorelease];
}

+ tlsKeyWithDestructor: (void(*)(id))destructor
{
	return [[[self alloc] initWithDestructor: destructor] autorelease];
}

+ (void)callAllDestructors
{
	of_list_object_t *iter;

	@synchronized (tlskeys) {
		for (iter = [tlskeys first]; iter != NULL; iter = iter->next)
			((OFTLSKey*)iter->object)->destructor(iter->object);
	}
}

- init
{
	self = [super init];

	if (!of_tlskey_new(&key)) {
		Class c = isa;
		[super dealloc];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	destructor = NULL;

	@synchronized (tlskeys) {
		@try {
			listobj = [tlskeys append: self];
		} @catch (OFException *e) {
			/*
			 * We can't use [super dealloc] on OS X here.
			 * Compiler bug? Anyway, [self dealloc] will do here
			 * as we check listobj != NULL in dealloc.
			 */
			listobj = NULL;
			[self dealloc];
			@throw e;
		}
	}

	return self;
}

- initWithDestructor: (void(*)(id))destructor_
{
	self = [self init];

	destructor = destructor_;

	return self;
}

- (void)dealloc
{
	if (destructor != NULL)
		destructor(self);

	of_tlskey_free(key);

	@synchronized (tlskeys) {
		/* In case we called [self dealloc] in init */
		if (listobj != NULL)
			[tlskeys remove: listobj];
	}

	[super dealloc];
}
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
	if (!of_mutex_lock(&mutex))
		@throw [OFMutexLockFailedException newWithClass: isa];

	return self;
}

- unlock
{
	if (!of_mutex_unlock(&mutex))
		@throw [OFMutexUnlockFailedException newWithClass: isa];

	return self;
}

- (void)dealloc
{
	of_mutex_free(&mutex);

	[super dealloc];
}
@end
