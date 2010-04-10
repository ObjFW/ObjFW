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

#ifndef _WIN32
# include <unistd.h>
#else
# include <windows.h>
#endif

#import "OFThread.h"
#import "OFList.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#import "threading.h"

static OFList *tlskeys;
static of_tlskey_t thread_self;

static id
call_run(id obj)
{
	if (!of_tlskey_set(thread_self, obj))
		@throw [OFInitializationFailedException
		    newWithClass: [obj class]];

	/*
	 * Nasty workaround for thread implementations which can't return a
	 * value on join.
	 */
	((OFThread*)obj)->retval = [[obj run] retain];

	[obj handleTermination];

	((OFThread*)obj)->running = OF_THREAD_WAITING_FOR_JOIN;

	[OFTLSKey callAllDestructors];
	[OFAutoreleasePool releaseAll];

	[obj release];

	return 0;
}

@implementation OFThread
+ (void)initialize
{
	if (self != [OFThread class])
		return;

	if (!of_tlskey_new(&thread_self))
		@throw [OFInitializationFailedException newWithClass: self];
}

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

+ (OFThread*)currentThread
{
	return of_tlskey_get(thread_self);
}

+ (void)sleepForNMilliseconds: (unsigned int)msecs;
{
#ifndef _WIN32
	usleep(msecs * 1000);
#else
	Sleep(msecs);
#endif
}

+ (void)terminate
{
	[self terminateWithObject: nil];
}

+ (void)terminateWithObject: (id)obj
{
	OFThread *thread = of_tlskey_get(thread_self);

	if (thread != nil) {
		thread->retval = [obj retain];

		[thread handleTermination];

		thread->running = OF_THREAD_WAITING_FOR_JOIN;
	}

	[OFTLSKey callAllDestructors];
	[OFAutoreleasePool releaseAll];

	[thread release];

	of_thread_exit();
}

- init
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- initWithObject: (OFObject <OFCopying>*)obj
{
	self = [super init];

	object = [obj retain];

	return self;
}

- (id)run
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];

	return nil;
}

- (void)handleTermination
{
}

- start
{
	[self retain];

	if (!of_thread_new(&thread, call_run, self)) {
		[self release];
		@throw [OFThreadStartFailedException newWithClass: isa];
	}

	running = OF_THREAD_RUNNING;

	return self;
}

- (id)join
{
	if (running == OF_THREAD_NOT_RUNNING || !of_thread_join(thread))
		@throw [OFThreadJoinFailedException newWithClass: isa];

	running = OF_THREAD_NOT_RUNNING;

	return retval;
}

- (void)dealloc
{
	if (running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException newWithClass: isa];

	[object release];
	[retval release];

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

- (BOOL)tryLock
{
	return of_mutex_trylock(&mutex);
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
