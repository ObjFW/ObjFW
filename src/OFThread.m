/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#ifndef _WIN32
# include <unistd.h>
# include <sched.h>
#else
# include <windows.h>
#endif

#import "OFThread.h"
#import "OFList.h"
#import "OFDate.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

#import "threading.h"

static OFList *tlskeys;
static of_tlskey_t thread_self;

static id
call_main(id obj)
{
	if (!of_tlskey_set(thread_self, obj))
		@throw [OFInitializationFailedException
		    newWithClass: [obj class]];

	/*
	 * Nasty workaround for thread implementations which can't return a
	 * value on join.
	 */
	((OFThread*)obj)->retval = [[obj main] retain];

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

+ thread
{
	return [[[self alloc] init] autorelease];
}

+ threadWithObject: (id)obj
{
	return [[[self alloc] initWithObject: obj] autorelease];
}

+ (void)setObject: (id)obj
	forTLSKey: (OFTLSKey*)key
{
	id old = of_tlskey_get(key->key);

	if (!of_tlskey_set(key->key, [obj retain]))
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	[old release];
}

+ (id)objectForTLSKey: (OFTLSKey*)key
{
	return [[of_tlskey_get(key->key) retain] autorelease];
}

+ (OFThread*)currentThread
{
	return [[of_tlskey_get(thread_self) retain] autorelease];
}

+ (void)sleepForTimeInterval: (int64_t)sec
{
	if (sec < 0)
		@throw [OFOutOfRangeException newWithClass: self];

#ifndef _WIN32
	sleep(sec);
#else
	Sleep(sec * 1000);
#endif
}

+ (void)sleepForTimeInterval: (int64_t)sec
		microseconds: (uint32_t)usec
{
	if (sec < 0)
		@throw [OFOutOfRangeException newWithClass: self];

#ifndef _WIN32
	sleep(sec);
	usleep(usec);
#else
	Sleep(sec * 1000 + usec / 1000);
#endif
}

+ (void)sleepUntilDate: (OFDate*)date
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFDate *now = [OFDate date];
	int64_t sec;
	uint32_t usec;

	if ((sec = [date timeIntervalSinceDate: now]) < 0)
		@throw [OFOutOfRangeException newWithClass: self];

	usec = [date microsecondsOfTimeIntervalSinceDate: now];

	[pool release];

#ifndef _WIN32
	sleep(sec);
	usleep(usec);
#else
	Sleep(sec * 1000 + usec / 1000);
#endif
}

+ (void)yield
{
#ifdef OF_HAVE_SCHED_YIELD
	sched_yield();
#else
	[self sleepForTimeInterval: 0];
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

- initWithObject: (id)obj
{
	self = [super init];

	@try {
		object = [obj retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (id)main
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];

	return nil;
}

- (void)handleTermination
{
}

- (void)start
{
	if (running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException newWithClass: isa];

	[self retain];

	if (!of_thread_new(&thread, call_main, self)) {
		[self release];
		@throw [OFThreadStartFailedException newWithClass: isa];
	}

	running = OF_THREAD_RUNNING;
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

+ TLSKey
{
	return [[[self alloc] init] autorelease];
}

+ TLSKeyWithDestructor: (void(*)(id))destructor
{
	return [[[self alloc] initWithDestructor: destructor] autorelease];
}

+ (void)callAllDestructors
{
	of_list_object_t *iter;

	@synchronized (tlskeys) {
		for (iter = [tlskeys firstListObject]; iter != NULL;
		    iter = iter->next) {
			OFTLSKey *key = (OFTLSKey*)iter->object;

			if (key->destructor != NULL)
				key->destructor(iter->object);
		}
	}
}

- init
{
	self = [super init];

	@try {
		if (!of_tlskey_new(&key))
			@throw [OFInitializationFailedException
			    newWithClass: isa];

		initialized = YES;

		@synchronized (tlskeys) {
			listobj = [tlskeys appendObject: self];
		}
	} @catch (id e) {
		[self release];
		@throw e;
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

	if (initialized)
		of_tlskey_free(key);

	/* In case we called [self release] in init */
	if (listobj != NULL) {
		@synchronized (tlskeys) {
			[tlskeys removeListObject: listobj];
		}
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
		[self release];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	initialized = YES;

	return self;
}

- (void)lock
{
	if (!of_mutex_lock(&mutex))
		@throw [OFMutexLockFailedException newWithClass: isa];
}

- (BOOL)tryLock
{
	return of_mutex_trylock(&mutex);
}

- (void)unlock
{
	if (!of_mutex_unlock(&mutex))
		@throw [OFMutexUnlockFailedException newWithClass: isa];
}

- (void)dealloc
{
	if (initialized)
		of_mutex_free(&mutex);

	[super dealloc];
}
@end
