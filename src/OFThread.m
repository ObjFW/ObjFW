/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
#define _POSIX_TIMERS
#define __NO_EXT_QNX

#include "config.h"

#include <stdlib.h>
#include <math.h>
#include <time.h>

#ifdef OF_HAVE_SCHED_YIELD
# include <sched.h>
#endif
#include "unistd_wrapper.h"

#include "platform.h"

#ifdef OF_AMIGAOS
# include <proto/exec.h>
# include <proto/dos.h>
#endif

#ifdef OF_WII
# define nanosleep ogc_nanosleep
# include <ogcsys.h>
# undef nanosleep
#endif

#ifdef OF_NINTENDO_3DS
# include <3ds/svc.h>
#endif

#import "OFThread.h"
#import "OFThread+Private.h"
#import "OFAutoreleasePool+Private.h"
#import "OFAutoreleasePool.h"
#import "OFDate.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_SOCKETS
# import "OFDNSResolver.h"
#endif
#import "OFLocale.h"
#import "OFRunLoop.h"
#import "OFString.h"

#ifdef OF_WINDOWS
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

#ifdef OF_DJGPP
# define lrint(x) rint(x)
#endif

#if defined(OF_HAVE_THREADS)
# import "tlskey.h"
# if defined(OF_AMIGAOS) && defined(OF_HAVE_SOCKETS)
#  import "socket.h"
# endif

static of_tlskey_t threadSelfKey;
static OFThread *mainThread;

static void
callMain(id object)
{
	OFThread *thread = (OFThread *)object;
	OFString *name;

	if (!of_tlskey_set(threadSelfKey, thread))
		@throw [OFInitializationFailedException
		    exceptionWithClass: thread.class];

	thread->_pool = objc_autoreleasePoolPush();

	name = thread.name;
	if (name != nil)
		of_thread_set_name(
		    [name cStringWithEncoding: [OFLocale encoding]]);
	else
		of_thread_set_name(object_getClassName(thread));

#if defined(OF_AMIGAOS) && defined(OF_HAVE_SOCKETS)
	if (thread.supportsSockets)
		if (!of_socket_init())
			@throw [OFInitializationFailedException
			    exceptionWithClass: thread.class];
#endif

	/*
	 * Nasty workaround for thread implementations which can't return a
	 * pointer on join, or don't have a way to exit a thread.
	 */
	if (setjmp(thread->_exitEnv) == 0) {
# ifdef OF_HAVE_BLOCKS
		if (thread->_threadBlock != NULL)
			thread->_returnValue = [thread->_threadBlock() retain];
		else
# endif
			thread->_returnValue = [[thread main] retain];
	}

	[thread handleTermination];

	objc_autoreleasePoolPop(thread->_pool);
	[OFAutoreleasePool of_handleThreadTermination];

#if defined(OF_AMIGAOS) && defined(OF_HAVE_SOCKETS)
	if (thread.supportsSockets)
		of_socket_deinit();
#endif

	thread->_running = OF_THREAD_WAITING_FOR_JOIN;

	[thread release];
}
#elif defined(OF_HAVE_SOCKETS)
static OFDNSResolver *DNSResolver;
#endif

@implementation OFThread
#ifdef OF_HAVE_THREADS
@synthesize name = _name;
# ifdef OF_HAVE_BLOCKS
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

+ (OFThread *)currentThread
{
	return of_tlskey_get(threadSelfKey);
}

+ (OFThread *)mainThread
{
	return mainThread;
}

+ (OFMutableDictionary *)threadDictionary
{
	OFThread *thread = of_tlskey_get(threadSelfKey);

	if (thread == nil)
		return nil;

	if (thread->_threadDictionary == nil)
		thread->_threadDictionary = [[OFMutableDictionary alloc] init];

	return thread->_threadDictionary;
}
#endif

#ifdef OF_HAVE_SOCKETS
+ (OFDNSResolver *)DNSResolver
{
# ifdef OF_HAVE_THREADS
	OFThread *thread = of_tlskey_get(threadSelfKey);

	if (thread == nil)
		return nil;

	if (thread->_DNSResolver == nil)
		thread->_DNSResolver = [[OFDNSResolver alloc] init];

	return thread->_DNSResolver;
# else
	if (DNSResolver == nil)
		DNSResolver = [[OFDNSResolver alloc] init];

	return DNSResolver;
# endif
}
#endif

+ (void)sleepForTimeInterval: (of_time_interval_t)timeInterval
{
	if (timeInterval < 0)
		return;

#if defined(OF_WINDOWS)
	if (timeInterval * 1000 > UINT_MAX)
		@throw [OFOutOfRangeException exception];

	Sleep((unsigned int)(timeInterval * 1000));
#elif defined(OF_NINTENDO_3DS)
	if (timeInterval * 1000000000 > INT64_MAX)
		@throw [OFOutOfRangeException exception];

	svcSleepThread((int64_t)(timeInterval * 1000000000));
#elif defined(HAVE_NANOSLEEP)
	struct timespec rqtp;

	rqtp.tv_sec = (time_t)timeInterval;
	rqtp.tv_nsec = lrint((timeInterval - rqtp.tv_sec) * 1000000000);

	if (rqtp.tv_sec != trunc(timeInterval))
		@throw [OFOutOfRangeException exception];

	nanosleep(&rqtp, NULL);
#elif defined(OF_AMIGAOS)
	if (timeInterval * 50 > ULONG_MAX)
		@throw [OFOutOfRangeException exception];

	Delay(timeInterval * 50);
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
	usleep((unsigned int)lrint(
	    (timeInterval - trunc(timeInterval)) * 1000000));
#endif
}

+ (void)sleepUntilDate: (OFDate *)date
{
	[self sleepForTimeInterval: date.timeIntervalSinceNow];
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

	OF_ENSURE(thread != nil);

	thread->_returnValue = [object retain];
	longjmp(thread->_exitEnv, 1);

	OF_UNREACHABLE
}

+ (void)setName: (OFString *)name
{
	[OFThread currentThread].name = name;

	if (name != nil)
		of_thread_set_name(
		    [name cStringWithEncoding: [OFLocale encoding]]);
	else
		of_thread_set_name(class_getName(self.class));
}

+ (OFString *)name
{
	return [OFThread currentThread].name;
}

+ (void)of_createMainThread
{
	mainThread = [[OFThread alloc] init];
	mainThread->_thread = of_thread_current();
	mainThread->_running = OF_THREAD_RUNNING;

	if (!of_tlskey_set(threadSelfKey, mainThread))
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

- (instancetype)init
{
	self = [super init];

	@try {
		if (!of_thread_attr_init(&_attr))
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

# ifdef OF_HAVE_BLOCKS
- (instancetype)initWithThreadBlock: (of_thread_block_t)threadBlock
{
	self = [self init];

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

# ifdef OF_HAVE_SOCKETS
	[_DNSResolver release];
	_DNSResolver = nil;
# endif
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

	if (!of_thread_new(&_thread, callMain, self, &_attr)) {
		[self release];
		@throw [OFThreadStartFailedException exceptionWithThread: self];
	}
}

- (id)join
{
	if (_running == OF_THREAD_NOT_RUNNING || !of_thread_join(_thread))
		@throw [OFThreadJoinFailedException exceptionWithThread: self];

	_running = OF_THREAD_NOT_RUNNING;

	return _returnValue;
}

- (id)copy
{
	return [self retain];
}

- (OFRunLoop *)runLoop
{
# if defined(OF_HAVE_ATOMIC_OPS) && !defined(__clang_analyzer__)
	if (_runLoop == nil) {
		OFRunLoop *tmp = [[OFRunLoop alloc] init];

		if (!of_atomic_ptr_cmpswap((void **)&_runLoop, nil, tmp))
			[tmp release];
	}
# else
	@synchronized (self) {
		if (_runLoop == nil)
			_runLoop = [[OFRunLoop alloc] init];
	}
# endif

	return _runLoop;
}

- (float)priority
{
	return _attr.priority;
}

- (void)setPriority: (float)priority
{
	if (_running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	_attr.priority = priority;
}

- (size_t)stackSize
{
	return _attr.stackSize;
}

- (void)setStackSize: (size_t)stackSize
{
	if (_running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	_attr.stackSize = stackSize;
}

- (bool)supportsSockets
{
	return _supportsSockets;
}

- (void)setSupportsSockets: (bool)supportsSockets
{
	if (_running == OF_THREAD_RUNNING)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	_supportsSockets = supportsSockets;
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
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}
#endif
@end
