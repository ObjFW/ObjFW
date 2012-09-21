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

#define OF_THREAD_M

#define __NO_EXT_QNX

#include <math.h>

#ifndef _WIN32
# include <unistd.h>
# include <sched.h>
#endif

#import "OFThread.h"
#import "OFList.h"
#import "OFDate.h"
#import "OFSortedList.h"
#import "OFRunLoop.h"
#import "OFAutoreleasePool.h"

#ifdef _WIN32
# include <windows.h>
#endif

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

#import "atomic.h"
#import "autorelease.h"
#import "threading.h"

static OFList *TLSKeys;
static of_tlskey_t threadSelfKey;
static OFThread *mainThread;

static id
call_main(id object)
{
	OFThread *thread = (OFThread*)object;

	if (!of_tlskey_set(threadSelfKey, thread))
		@throw [OFInitializationFailedException
		    exceptionWithClass: [thread class]];

	objc_autoreleasePoolPush();

	/*
	 * Nasty workaround for thread implementations which can't return a
	 * value on join.
	 */
#ifdef OF_HAVE_BLOCKS
	if (thread->block != NULL)
		thread->returnValue = [thread->block(thread->object) retain];
	else
#endif
		thread->returnValue = [[thread main] retain];

	[thread handleTermination];

	thread->running = OF_THREAD_WAITING_FOR_JOIN;

	[OFTLSKey callAllDestructors];
#ifdef OF_OBJFW_RUNTIME
	/*
	 * As the values returned by objc_autoreleasePoolPush() in the ObjFW
	 * runtime are not actually pointers, but sequential numbers, 0 means
	 * we pop everything.
	 */
	objc_autoreleasePoolPop(0);
#endif

	[thread release];

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

	if (!of_tlskey_new(&threadSelfKey))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
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

+ threadWithObject: (id)object
	     block: (of_thread_block_t)block
{
	return [[[self alloc] initWithObject: object
				       block: block] autorelease];
}
#endif

+ (void)setObject: (id)object
	forTLSKey: (OFTLSKey*)key
{
	id oldObject = of_tlskey_get(key->key);

	if (!of_tlskey_set(key->key, [object retain]))
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	[oldObject release];
}

+ (id)objectForTLSKey: (OFTLSKey*)key
{
	return [[(id)of_tlskey_get(key->key) retain] autorelease];
}

+ (OFThread*)currentThread
{
	return [[(id)of_tlskey_get(threadSelfKey) retain] autorelease];
}

+ (OFThread*)mainThread
{
	return mainThread;
}

+ (void)sleepForTimeInterval: (double)seconds
{
	if (seconds < 0)
		@throw [OFOutOfRangeException exceptionWithClass: self];

#ifndef _WIN32
	if (seconds > UINT_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: self];

	sleep((unsigned int)seconds);
	usleep((useconds_t)rint((seconds - floor(seconds)) * 1000000));
#else
	if (seconds * 1000 > UINT_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: self];

	Sleep((unsigned int)(seconds * 1000));
#endif
}

+ (void)sleepUntilDate: (OFDate*)date
{
	double seconds = [date timeIntervalSinceNow];

#ifndef _WIN32
	if (seconds > UINT_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: self];

	sleep((unsigned int)seconds);
	usleep((useconds_t)rint((seconds - floor(seconds)) * 1000000));
#else
	if (seconds * 1000 > UINT_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: self];

	Sleep((unsigned int)(seconds * 1000));
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
	OFThread *thread = of_tlskey_get(threadSelfKey);

	if (thread != nil) {
		thread->returnValue = [object retain];

		[thread handleTermination];

		thread->running = OF_THREAD_WAITING_FOR_JOIN;
	}

	[OFTLSKey callAllDestructors];
#ifdef OF_OBJFW_RUNTIME
	/*
	 * As the values returned by objc_autoreleasePoolPush() in the ObjFW
	 * runtime are not actually pointers, but sequential numbers, 0 means
	 * we pop everything.
	 */
	objc_autoreleasePoolPop(0);
#endif

	[thread release];

	of_thread_exit();
}

+ (void)OF_createMainThread
{
	mainThread = [[OFThread alloc] init];
	mainThread->thread = of_thread_current();

	if (!of_tlskey_set(threadSelfKey, mainThread))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

- initWithObject: (id)object_
{
	self = [super init];

	object = [object_ retain];

	return self;
}

#ifdef OF_HAVE_BLOCKS
- initWithBlock: (of_thread_block_t)block_
{
	return [self initWithObject: nil
			      block: block_];
}

- initWithObject: (id)object_
	   block: (of_thread_block_t)block_
{
	self = [super init];

	@try {
		object = [object_ retain];
		block = [block_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (id)main
{
	[[OFRunLoop currentRunLoop] run];

	return nil;
}

- (void)handleTermination
{
	OFRunLoop *tmp = runLoop;
	runLoop = nil;
	[tmp release];
}

- (void)start
{
	if (running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithClass: [self class]
				thread: self];

	if (running == OF_THREAD_WAITING_FOR_JOIN) {
		of_thread_detach(thread);
		[returnValue release];
	}

	[self retain];

	running = OF_THREAD_RUNNING;

	if (!of_thread_new(&thread, call_main, self)) {
		[self release];
		@throw [OFThreadStartFailedException
		    exceptionWithClass: [self class]
				thread: self];
	}
}

- (id)join
{
	if (running == OF_THREAD_NOT_RUNNING || !of_thread_join(thread))
		@throw [OFThreadJoinFailedException
		    exceptionWithClass: [self class]
				thread: self];

	running = OF_THREAD_NOT_RUNNING;

	return returnValue;
}

- (OFRunLoop*)runLoop
{
	if (runLoop == nil) {
		OFRunLoop *tmp = [[OFRunLoop alloc] init];

		if (!of_atomic_cmpswap_ptr((void**)&runLoop, nil, tmp))
			[tmp release];
	}

	return [[runLoop retain] autorelease];
}

- (void)dealloc
{
	if (running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithClass: [self class]
				thread: self];

	/*
	 * We should not be running anymore, but call detach in order to free
	 * the resources.
	 */
	if (running == OF_THREAD_WAITING_FOR_JOIN)
		of_thread_detach(thread);

	[object release];
	[returnValue release];
	[runLoop release];

	[super dealloc];
}

- copy
{
	return [self retain];
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
			    exceptionWithClass: [self class]];

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
		Class c = [self class];
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	initialized = YES;

	return self;
}

- OF_initWithoutCreatingMutex
{
	return [super init];
}

- (void)lock
{
	if (!of_mutex_lock(&mutex))
		@throw [OFMutexLockFailedException
		    exceptionWithClass: [self class]
				 mutex: self];
}

- (BOOL)tryLock
{
	return of_mutex_trylock(&mutex);
}

- (void)unlock
{
	if (!of_mutex_unlock(&mutex))
		@throw [OFMutexUnlockFailedException
		    exceptionWithClass: [self class]
				 mutex: self];
}

- (void)dealloc
{
	if (initialized)
		if (!of_mutex_free(&mutex))
			@throw [OFMutexStillLockedException
			    exceptionWithClass: [self class]
					 mutex: self];

	[super dealloc];
}
@end

@implementation OFRecursiveMutex
- init
{
	self = [super OF_initWithoutCreatingMutex];

	if (!of_rmutex_new(&rmutex)) {
		Class c = [self class];
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	initialized = YES;

	return self;
}

- (void)lock
{
	if (!of_rmutex_lock(&rmutex))
		@throw [OFMutexLockFailedException
		    exceptionWithClass: [self class]
				 mutex: self];
}

- (BOOL)tryLock
{
	return of_rmutex_trylock(&rmutex);
}

- (void)unlock
{
	if (!of_rmutex_unlock(&rmutex))
		@throw [OFMutexUnlockFailedException
		    exceptionWithClass: [self class]
				 mutex: self];
}

- (void)dealloc
{
	if (initialized)
		if (!of_rmutex_free(&rmutex))
			@throw [OFMutexStillLockedException
			    exceptionWithClass: [self class]
					 mutex: self];

	[super dealloc];
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
		Class c = [self class];
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	conditionInitialized = YES;

	return self;
}

- (void)wait
{
	if (!of_condition_wait(&condition, &mutex))
		@throw [OFConditionWaitFailedException
		    exceptionWithClass: [self class]
			     condition: self];
}

- (void)signal
{
	if (!of_condition_signal(&condition))
		@throw [OFConditionSignalFailedException
		    exceptionWithClass: [self class]
			     condition: self];
}

- (void)broadcast
{
	if (!of_condition_broadcast(&condition))
		@throw [OFConditionBroadcastFailedException
		    exceptionWithClass: [self class]
			     condition: self];
}

- (void)dealloc
{
	if (conditionInitialized)
		if (!of_condition_free(&condition))
			@throw [OFConditionStillWaitingException
			    exceptionWithClass: [self class]
				     condition: self];

	[super dealloc];
}
@end
