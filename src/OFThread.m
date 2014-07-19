/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#define OF_THREAD_M
#define __NO_EXT_QNX

#include "config.h"

#include <stdlib.h>
#include <math.h>
#include <time.h>

/* Work around __block being used by glibc */
#ifdef __GLIBC__
# undef __USE_XOPEN
#endif

#ifndef _WIN32
# include <unistd.h>
#endif

#ifdef OF_HAVE_SCHED_YIELD
# include <sched.h>
#endif

#import "OFThread.h"
#import "OFThread+Private.h"
#import "OFRunLoop.h"
#import "OFList.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFAutoreleasePool.h"
#import "OFAutoreleasePool+Private.h"

#ifdef _WIN32
# include <windows.h>
#endif

#ifdef OF_NINTENDO_DS
# define asm __asm__
# include <nds.h>
# undef asm
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFOutOfRangeException.h"
#ifdef OF_HAVE_THREADS
# import "OFThreadJoinFailedException.h"
# import "OFThreadStartFailedException.h"
# import "OFThreadStillRunningException.h"
#endif

#ifdef OF_HAVE_ATOMIC_OPS
# import "atomic.h"
#endif

#ifdef __DJGPP__
# define lrint(x) rint(x)
# define useconds_t unsigned int
#endif

#ifdef OF_HAVE_THREADS
# import "threading.h"

static of_tlskey_t threadSelfKey;
static OFThread *mainThread;

static id
callMain(id object)
{
	OFThread *thread = (OFThread*)object;

	if (!of_tlskey_set(threadSelfKey, thread))
		@throw [OFInitializationFailedException
		    exceptionWithClass: [thread class]];

	thread->_pool = objc_autoreleasePoolPush();

	/*
	 * Nasty workaround for thread implementations which can't return a
	 * value on join.
	 */
# ifdef OF_HAVE_BLOCKS
	if (thread->_threadBlock != NULL)
		thread->_returnValue = [thread->_threadBlock() retain];
	else
# endif
		thread->_returnValue = [[thread main] retain];

	[thread handleTermination];

	thread->_running = OF_THREAD_WAITING_FOR_JOIN;

	objc_autoreleasePoolPop(thread->_pool);
	[OFAutoreleasePool OF_handleThreadTermination];

	[thread release];

	return 0;
}
#endif

@implementation OFThread
#ifdef OF_HAVE_THREADS
# if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
@synthesize threadBlock = _threadBlock;
# endif

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

# ifdef OF_HAVE_BLOCKS
+ (instancetype)threadWithThreadBlock: (of_thread_block_t)threadBlock
{
	return [[[self alloc] initWithThreadBlock: threadBlock] autorelease];
}
# endif

+ (OFThread*)currentThread
{
	return of_tlskey_get(threadSelfKey);
}

+ (OFThread*)mainThread
{
	return mainThread;
}

+ (OFMutableDictionary*)threadDictionary
{
	OFThread *thread = of_tlskey_get(threadSelfKey);

	if (thread->_threadDictionary == nil)
		thread->_threadDictionary = [[OFMutableDictionary alloc] init];

	return thread->_threadDictionary;
}
#endif

+ (void)sleepForTimeInterval: (of_time_interval_t)timeInterval
{
	if (timeInterval < 0)
		@throw [OFOutOfRangeException exception];

#if defined(_WIN32)
	if (timeInterval * 1000 > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	Sleep((unsigned int)(timeInterval * 1000));
#elif defined(HAVE_NANOSLEEP)
	struct timespec rqtp;

	rqtp.tv_sec = (time_t)timeInterval;
	rqtp.tv_nsec = lrint((timeInterval - rqtp.tv_sec) * 1000000000);

	if (rqtp.tv_sec != floor(timeInterval))
		@throw [OFOutOfRangeException exception];

	nanosleep(&rqtp, NULL);
#elif defined(OF_NINTENDO_DS)
	uint64_t counter;

	if (timeInterval > UINT64_MAX / 60)
		@throw [OFOutOfRangeException exception];

	counter = timeInterval * 60;
	while (counter--)
		swiWaitForVBlank();
#else
	if (timeInterval > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	sleep((unsigned int)timeInterval);
	usleep((useconds_t)lrint(
	    (timeInterval - floor(timeInterval)) * 1000000));
#endif
}

+ (void)sleepUntilDate: (OFDate*)date
{
	[self sleepForTimeInterval: [date timeIntervalSinceNow]];
}

+ (void)yield
{
#ifdef OF_HAVE_SCHED_YIELD
	sched_yield();
#else
	[self sleepForTimeInterval: 0];
#endif
}

#ifdef OF_HAVE_THREADS
+ (void)terminate
{
	[self terminateWithObject: nil];

	/*
	 * For some reason, Clang thinks terminateWithObject: can return - even
	 * though it is declared OF_NO_RETURN - and warns that terminate
	 * returns while being declared OF_NO_RETURN.
	 */
	OF_UNREACHABLE
}

+ (void)terminateWithObject: (id)object
{
	OFThread *thread = of_tlskey_get(threadSelfKey);

	if (thread != nil) {
		thread->_returnValue = [object retain];

		[thread handleTermination];

		thread->_running = OF_THREAD_WAITING_FOR_JOIN;
		objc_autoreleasePoolPop(thread->_pool);
	}

	[OFAutoreleasePool OF_handleThreadTermination];

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

# ifdef OF_HAVE_BLOCKS
- initWithThreadBlock: (of_thread_block_t)threadBlock
{
	self = [super init];

	@try {
		_threadBlock = [threadBlock copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
# endif

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

	[_threadDictionary release];
	_threadDictionary = nil;
}

- (void)start
{
	if (_running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	if (_running == OF_THREAD_WAITING_FOR_JOIN) {
		of_thread_detach(_thread);
		[_returnValue release];
	}

	[self retain];

	_running = OF_THREAD_RUNNING;

	if (!of_thread_new(&_thread, callMain, self)) {
		[self release];
		@throw [OFThreadStartFailedException exceptionWithThread: self];
	}

	if (_name != nil)
		of_thread_set_name(_thread, [_name UTF8String]);
	else
		of_thread_set_name(_thread, class_getName([self class]));
}

- (id)join
{
	if (_running == OF_THREAD_NOT_RUNNING || !of_thread_join(_thread))
		@throw [OFThreadJoinFailedException exceptionWithThread: self];

	_running = OF_THREAD_NOT_RUNNING;

	return _returnValue;
}

- copy
{
	return [self retain];
}

- (OFRunLoop*)runLoop
{
# ifdef OF_HAVE_ATOMIC_OPS
	if (_runLoop == nil) {
		OFRunLoop *tmp = [[OFRunLoop alloc] init];

		if (!of_atomic_ptr_cmpswap((void**)&_runLoop, nil, tmp))
			[tmp release];
	}
# else
	@synchronized (self) {
		if (_runLoop == nil)
			_runLoop = [[OFRunLoop alloc] init];
	}
# endif

	return [[_runLoop retain] autorelease];
}

- (OFString*)name
{
	OF_GETTER(_name, true)
}

- (void)setName: (OFString*)name
{
	OF_SETTER(_name, name, true, 1)

	if (_running == OF_THREAD_RUNNING) {
		if (_name != nil)
			of_thread_set_name(_thread, [_name UTF8String]);
		else
			of_thread_set_name(_thread,
			    class_getName([self class]));
	}
}

- (void)dealloc
{
	if (_running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	/*
	 * We should not be running anymore, but call detach in order to free
	 * the resources.
	 */
	if (_running == OF_THREAD_WAITING_FOR_JOIN)
		of_thread_detach(_thread);

	[_returnValue release];
# ifdef OF_HAVE_BLOCKS
	[_threadBlock release];
# endif

	[super dealloc];
}
#else
- init
{
	OF_INVALID_INIT_METHOD
}
#endif
@end
