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

#if defined(OF_GNU_RUNTIME) || defined(OF_OLD_GNU_RUNTIME)
# import <objc/thr.h>
#endif

#import "OFThread.h"
#import "OFList.h"
#import "OFDate.h"
#import "OFAutoreleasePool.h"

#import "OFConditionBroadcastFailedException.h"
#import "OFConditionSignalFailedException.h"
#import "OFConditionStillWaitingException.h"
#import "OFConditionWaitFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFMutexLockFailedException.h"
#import "OFMutexStillLockedException.h"
#import "OFMutexUnlockFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"
#import "OFThreadJoinFailedException.h"
#import "OFThreadStartFailedException.h"
#import "OFThreadStillRunningException.h"

#import "threading.h"

static OFList *TLSKeys;
static of_tlskey_t threadSelf;

static id
call_main(id object)
{
	OFThread *thread = (OFThread*)object;

#if defined(OF_GNU_RUNTIME) || defined(OF_OLD_GNU_RUNTIME)
	objc_thread_add();
#endif

	if (!of_tlskey_set(threadSelf, thread))
		@throw [OFInitializationFailedException
		    newWithClass: [thread class]];

	/*
	 * Nasty workaround for thread implementations which can't return a
	 * value on join.
	 */
#ifdef OF_HAVE_BLOCKS
	if (thread->block != nil)
		thread->returnValue = [thread->block(thread->object) retain];
	else
		thread->returnValue = [[thread main] retain];
#else
	thread->returnValue = [[thread main] retain];
#endif

	[thread handleTermination];

	thread->running = OF_THREAD_WAITING_FOR_JOIN;

	[OFTLSKey callAllDestructors];
	[OFAutoreleasePool releaseAll];

	[thread release];

#if defined(OF_GNU_RUNTIME) || defined(OF_OLD_GNU_RUNTIME)
	objc_thread_remove();
#endif

	return 0;
}

@implementation OFThread
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
@synthesize block;
#endif

+ (void)initialize
{
	if (self != [OFThread class])
		return;

	if (!of_tlskey_new(&threadSelf))
		@throw [OFInitializationFailedException newWithClass: self];
}

+ thread
{
	return [[[self alloc] init] autorelease];
}

+ threadWithObject: (id)object
{
	return [[[self alloc] initWithObject: object] autorelease];
}

#ifdef OF_HAVE_BLOCKS
+ threadWithBlock: (of_thread_block_t)block
{
	return [[[self alloc] initWithBlock: block] autorelease];
}

+ threadWithBlock: (of_thread_block_t)block
	   object: (id)object
{
	return [[[self alloc] initWithBlock: block
				     object: object] autorelease];
}
#endif

+ (void)setObject: (id)object
	forTLSKey: (OFTLSKey*)key
{
	id oldObject = of_tlskey_get(key->key);

	if (!of_tlskey_set(key->key, [object retain]))
		@throw [OFInvalidArgumentException newWithClass: self
						       selector: _cmd];

	[oldObject release];
}

+ (id)objectForTLSKey: (OFTLSKey*)key
{
	return [[of_tlskey_get(key->key) retain] autorelease];
}

+ (OFThread*)currentThread
{
	return [[of_tlskey_get(threadSelf) retain] autorelease];
}

+ (void)sleepForTimeInterval: (int64_t)seconds
{
	if (seconds < 0)
		@throw [OFOutOfRangeException newWithClass: self];

#ifndef _WIN32
	if (seconds > UINT_MAX)
		@throw [OFOutOfRangeException newWithClass: self];

	sleep((unsigned int)seconds);
#else
	if (seconds * 1000 > UINT_MAX)
		@throw [OFOutOfRangeException newWithClass: self];

	Sleep((unsigned int)seconds * 1000);
#endif
}

+ (void)sleepForTimeInterval: (int64_t)seconds
		microseconds: (uint32_t)microseconds
{
	if (seconds < 0)
		@throw [OFOutOfRangeException newWithClass: self];

#ifndef _WIN32
	sleep((unsigned int)seconds);
	usleep(microseconds);
#else
	if (seconds * 1000 + microseconds / 1000 > UINT_MAX)
		@throw [OFOutOfRangeException newWithClass: self];

	Sleep((unsigned int)seconds * 1000 + microseconds / 1000);
#endif
}

+ (void)sleepUntilDate: (OFDate*)date
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFDate *now = [OFDate date];
	int64_t seconds;
	uint32_t microseconds;

	if ((seconds = [date timeIntervalSinceDate: now]) < 0)
		@throw [OFOutOfRangeException newWithClass: self];

	microseconds = [date microsecondsOfTimeIntervalSinceDate: now];

	[pool release];

#ifndef _WIN32
	if (seconds > UINT_MAX)
		@throw [OFOutOfRangeException newWithClass: self];

	sleep((unsigned int)seconds);
	usleep(microseconds);
#else
	if (seconds * 1000 + microseconds / 1000 > UINT_MAX)
		@throw [OFOutOfRangeException newWithClass: self];

	Sleep(seconds * 1000 + microseconds / 1000);
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

+ (void)terminateWithObject: (id)object
{
	OFThread *thread = of_tlskey_get(threadSelf);

	if (thread != nil) {
		thread->returnValue = [object retain];

		[thread handleTermination];

		thread->running = OF_THREAD_WAITING_FOR_JOIN;
	}

	[OFTLSKey callAllDestructors];
	[OFAutoreleasePool releaseAll];

	[thread release];

#if defined(OF_GNU_RUNTIME) || defined(OF_OLD_GNU_RUNTIME)
	objc_thread_remove();
#endif

	of_thread_exit();
}

- initWithObject: (id)object_
{
	self = [super init];

	@try {
		object = [object_ retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_BLOCKS
- initWithBlock: (of_thread_block_t)block_
{
	return [self initWithBlock: block_
			    object: nil];
}

- initWithBlock: (of_thread_block_t)block_
	 object: (id)object_
{
	self = [super init];

	@try {
		block = [block_ retain];
		object = [object_ retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

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
		@throw [OFThreadStillRunningException newWithClass: isa
							    thread: self];

	if (running == OF_THREAD_WAITING_FOR_JOIN) {
		of_thread_detach(thread);
		[returnValue release];
	}

	[self retain];

	if (!of_thread_new(&thread, call_main, self)) {
		[self release];
		@throw [OFThreadStartFailedException newWithClass: isa
							   thread: self];
	}

	running = OF_THREAD_RUNNING;
}

- (id)join
{
	if (running == OF_THREAD_NOT_RUNNING || !of_thread_join(thread))
		@throw [OFThreadJoinFailedException newWithClass: isa
							  thread: self];

	running = OF_THREAD_NOT_RUNNING;

	return returnValue;
}

- (void)dealloc
{
	if (running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException newWithClass: isa
							    thread: self];

	/*
	 * We should not be running anymore, but call detach in order to free
	 * the resources.
	 */
	if (running == OF_THREAD_WAITING_FOR_JOIN)
		of_thread_detach(thread);

	[object release];
	[returnValue release];

	[super dealloc];
}

- (void)finalize
{
	if (running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException newWithClass: isa
							    thread: self];

	/*
	 * We should not be running anymore, but call detach in order to free
	 * the resources.
	 */
	if (running == OF_THREAD_WAITING_FOR_JOIN)
		of_thread_detach(thread);

	[super finalize];
}
@end

@implementation OFTLSKey
+ (void)initialize
{
	if (self == [OFTLSKey class])
		TLSKeys = [[OFList alloc] init];
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

	@synchronized (TLSKeys) {
		for (iter = [TLSKeys firstListObject]; iter != NULL;
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

		@synchronized (TLSKeys) {
			listObject = [TLSKeys appendObject: self];
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
	if (listObject != NULL) {
		@synchronized (TLSKeys) {
			[TLSKeys removeListObject: listObject];
		}
	}

	[super dealloc];
}

- (void)finalize
{
	if (destructor != NULL)
		destructor(self);

	if (initialized)
		of_tlskey_free(key);

	/* In case we called [self release] in init */
	if (listObject != NULL) {
		@synchronized (TLSKeys) {
			[TLSKeys removeListObject: listObject];
		}
	}

	[super finalize];
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
		@throw [OFMutexLockFailedException newWithClass: isa
							  mutex: self];
}

- (BOOL)tryLock
{
	return of_mutex_trylock(&mutex);
}

- (void)unlock
{
	if (!of_mutex_unlock(&mutex))
		@throw [OFMutexUnlockFailedException newWithClass: isa
							    mutex: self];
}

- (void)dealloc
{
	if (initialized)
		if (!of_mutex_free(&mutex))
			@throw [OFMutexStillLockedException newWithClass: isa
								   mutex: self];

	[super dealloc];
}

- (void)finalize
{
	if (initialized)
		if (!of_mutex_free(&mutex))
			@throw [OFMutexStillLockedException newWithClass: isa
								   mutex: self];

	[super finalize];
}
@end

@implementation OFCondition
+ condition
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	if (!of_condition_new(&condition)) {
		Class c = isa;
		[self release];
		@throw [OFInitializationFailedException newWithClass: c];
	}

	conditionInitialized = YES;

	return self;
}

- (void)wait
{
	if (!of_condition_wait(&condition, &mutex))
		@throw [OFConditionWaitFailedException newWithClass: isa
							  condition: self];
}

- (void)signal
{
	if (!of_condition_signal(&condition))
		@throw [OFConditionSignalFailedException newWithClass: isa
							    condition: self];
}

- (void)broadcast
{
	if (!of_condition_broadcast(&condition))
		@throw [OFConditionBroadcastFailedException newWithClass: isa
							       condition: self];
}

- (void)dealloc
{
	if (conditionInitialized)
		if (!of_condition_free(&condition))
			@throw [OFConditionStillWaitingException
			    newWithClass: isa
			       condition: self];

	[super dealloc];
}

- (void)finalize
{
	if (conditionInitialized)
		if (!of_condition_free(&condition))
			@throw [OFConditionStillWaitingException
			    newWithClass: isa
			       condition: self];

	[super finalize];
}
@end
