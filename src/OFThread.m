/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#ifdef __HAIKU__
# include <kernel/OS.h>
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

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"
#import "OFThreadJoinFailedException.h"
#import "OFThreadStartFailedException.h"
#import "OFThreadStillRunningException.h"

#ifdef OF_HAVE_ATOMIC_OPS
# import "atomic.h"
#endif
#import "autorelease.h"
#import "threading.h"

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
	if (thread->_block != NULL)
		thread->_returnValue = [thread->_block() retain];
	else
#endif
		thread->_returnValue = [[thread main] retain];

	[thread handleTermination];

	thread->_running = OF_THREAD_WAITING_FOR_JOIN;

	[OFTLSKey OF_callAllDestructors];
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

static void
set_thread_name(OFThread *thread)
{
#ifdef __HAIKU__
	OFString *name = thread->_name;

	if (name == nil)
		name = [thread className];

	rename_thread(get_pthread_thread_id(thread->thread), [name UTF8String]);
#endif
}

@implementation OFThread
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
@synthesize block = _block;
#endif

+ (void)initialize
{
	if (self != [OFThread class])
		return;

	if (!of_tlskey_new(&threadSelfKey))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)thread
{
	return [[[self alloc] init] autorelease];
}

#ifdef OF_HAVE_BLOCKS
+ (instancetype)threadWithBlock: (of_thread_block_t)block
{
	return [[[self alloc] initWithBlock: block] autorelease];
}
#endif

+ (void)setObject: (id)object
	forTLSKey: (OFTLSKey*)key
{
	id oldObject = of_tlskey_get(key->_key);

	if (!of_tlskey_set(key->_key, [object retain]))
		@throw [OFInvalidArgumentException exceptionWithClass: self
							     selector: _cmd];

	[oldObject release];
}

+ (id)objectForTLSKey: (OFTLSKey*)key
{
	return [[(id)of_tlskey_get(key->_key) retain] autorelease];
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
		thread->_returnValue = [object retain];

		[thread handleTermination];

		thread->_running = OF_THREAD_WAITING_FOR_JOIN;
	}

	[OFTLSKey OF_callAllDestructors];
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
	mainThread->_thread = of_thread_current();

	if (!of_tlskey_set(threadSelfKey, mainThread))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

#ifdef OF_HAVE_BLOCKS
- initWithBlock: (of_thread_block_t)block
{
	self = [super init];

	@try {
		_block = [block copy];
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
	OFRunLoop *oldRunLoop = _runLoop;
	_runLoop = nil;
	[oldRunLoop release];
}

- (void)start
{
	if (_running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithClass: [self class]
				thread: self];

	if (_running == OF_THREAD_WAITING_FOR_JOIN) {
		of_thread_detach(_thread);
		[_returnValue release];
	}

	[self retain];

	_running = OF_THREAD_RUNNING;

	if (!of_thread_new(&_thread, call_main, self)) {
		[self release];
		@throw [OFThreadStartFailedException
		    exceptionWithClass: [self class]
				thread: self];
	}

	set_thread_name(self);
}

- (id)join
{
	if (_running == OF_THREAD_NOT_RUNNING || !of_thread_join(_thread))
		@throw [OFThreadJoinFailedException
		    exceptionWithClass: [self class]
				thread: self];

	_running = OF_THREAD_NOT_RUNNING;

	return _returnValue;
}

- copy
{
	return [self retain];
}

- (OFRunLoop*)runLoop
{
#ifdef OF_HAVE_ATOMIC_OPS
	if (_runLoop == nil) {
		OFRunLoop *tmp = [[OFRunLoop alloc] init];

		if (!of_atomic_cmpswap_ptr((void**)&_runLoop, nil, tmp))
			[tmp release];
	}
#else
	@synchronized (self) {
		if (_runLoop == nil)
			_runLoop = [[OFRunLoop alloc] init];
	}
#endif

	return [[_runLoop retain] autorelease];
}

- (OFString*)name
{
	OF_GETTER(_name, YES)
}

- (void)setName: (OFString*)name
{
	OF_SETTER(_name, name, YES, 1)

	if (_running == OF_THREAD_RUNNING)
		set_thread_name(self);
}

- (void)dealloc
{
	if (_running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithClass: [self class]
				thread: self];

	/*
	 * We should not be running anymore, but call detach in order to free
	 * the resources.
	 */
	if (_running == OF_THREAD_WAITING_FOR_JOIN)
		of_thread_detach(_thread);

	[_returnValue release];
	[_runLoop release];

	[super dealloc];
}
@end
