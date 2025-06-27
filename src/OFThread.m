/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#define _POSIX_TIMERS

#include <errno.h>

#include <stdlib.h>
#include <math.h>
#include <time.h>

#ifdef OF_HAVE_SCHED_YIELD
# include <sched.h>
#endif
#include "unistd_wrapper.h"

#include "platform.h"

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# include <proto/dos.h>
# undef Class
#endif

#ifdef OF_WII
# define asm __asm__
# define nanosleep ogc_nanosleep
# include <gccore.h>
# include <ogcsys.h>
# undef nanosleep
# undef asm
#endif

#ifdef OF_NINTENDO_DS
# define asm __asm__
# include <nds.h>
# undef asm
#endif

#ifdef OF_NINTENDO_3DS
/* Newer versions of libctru started using id as a parameter name. */
# define id id_3ds
# include <3ds.h>
# undef id
#endif

#import "OFThread.h"
#import "OFThread+Private.h"
#ifdef OF_HAVE_ATOMIC_OPS
# import "OFAtomic.h"
#endif
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
# import "OFJoinThreadFailedException.h"
# import "OFStartThreadFailedException.h"
# import "OFThreadStillRunningException.h"
#endif

#ifdef OF_MINT
/* freemint-gcc does not have trunc() */
# define trunc(x) ((int64_t)(x))
#endif

#if defined(OF_HAVE_THREADS)
# import "OFTLSKey.h"
# if defined(OF_AMIGAOS) && defined(OF_HAVE_SOCKETS)
#  import "OFSocket.h"
#  import "OFSocket+Private.h"
# endif

static OFTLSKey threadSelfKey;
static OFThread *mainThread;
#elif defined(OF_HAVE_SOCKETS)
static OFDNSResolver *DNSResolver;
#endif

@implementation OFThread
#ifdef OF_HAVE_THREADS
static void
callMain(id object)
{
	OFThread *thread = (OFThread *)object;
	OFString *name;

	if (OFTLSKeySet(threadSelfKey, thread) != 0)
		@throw [OFInitializationFailedException
		    exceptionWithClass: thread.class];

#ifndef OF_OBJFW_RUNTIME
	thread->_pool = objc_autoreleasePoolPush();
#endif

	name = thread.name;
	if (name != nil)
		OFSetThreadName(
		    [name cStringWithEncoding: [OFLocale encoding]]);
	else
		OFSetThreadName(object_getClassName(thread));

#if defined(OF_AMIGAOS) && defined(OF_HAVE_SOCKETS)
	if (thread.supportsSockets)
		if (!_OFSocketInit())
			@throw [OFInitializationFailedException
			    exceptionWithClass: thread.class];
#endif

	/*
	 * Nasty workaround for thread implementations which can't return a
	 * pointer on join, or don't have a way to exit a thread.
	 */
	if (setjmp(thread->_exitEnv) == 0) {
# ifdef OF_HAVE_BLOCKS
		if (thread->_block != NULL)
			thread->_returnValue = objc_retain(thread->_block());
		else
# endif
			thread->_returnValue = objc_retain([thread main]);
	}

	[thread handleTermination];

#ifdef OF_OBJFW_RUNTIME
	objc_autoreleasePoolPop((void *)(uintptr_t)-1);
#else
	objc_autoreleasePoolPop(thread->_pool);
#endif

#if defined(OF_AMIGAOS) && !defined(OF_MORPHOS) && defined(OF_HAVE_SOCKETS)
	if (thread.supportsSockets)
		_OFSocketDeinit();
#endif

	thread->_running = OFThreadStateWaitingForJoin;

	objc_release(thread);
}

@synthesize name = _name;
# ifdef OF_HAVE_BLOCKS
@synthesize block = _block;
# endif

+ (void)initialize
{
	if (self != [OFThread class])
		return;

	if (OFTLSKeyNew(&threadSelfKey) != 0)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)thread
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

# ifdef OF_HAVE_BLOCKS
+ (instancetype)threadWithBlock: (OFThreadBlock)block
{
	return objc_autoreleaseReturnValue([[self alloc] initWithBlock: block]);
}
# endif

+ (OFThread *)currentThread
{
	return OFTLSKeyGet(threadSelfKey);
}

+ (OFThread *)mainThread
{
	return mainThread;
}

+ (bool)isMainThread
{
	if (mainThread == nil)
		return false;

	return (OFTLSKeyGet(threadSelfKey) == mainThread);
}

+ (OFMutableDictionary *)threadDictionary
{
	OFThread *thread = OFTLSKeyGet(threadSelfKey);

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
	OFThread *thread = OFTLSKeyGet(threadSelfKey);

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

+ (void)sleepForTimeInterval: (OFTimeInterval)timeInterval
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
#elif defined(OF_AMIGAOS)
	struct timerequest request = *DOSBase->dl_TimeReq;

	request.tr_node.io_Message.mn_ReplyPort =
	    &((struct Process *)FindTask(NULL))->pr_MsgPort;
	request.tr_node.io_Command = TR_ADDREQUEST;
	request.tr_time.tv_secs = (ULONG)timeInterval;
	request.tr_time.tv_micro = (ULONG)
	    ((timeInterval - (unsigned int)timeInterval) * 1000000);

	DoIO((struct IORequest *)&request);
#elif defined(HAVE_NANOSLEEP)
	struct timespec rqtp;

	rqtp.tv_sec = (time_t)timeInterval;
	rqtp.tv_nsec = (long)((timeInterval - rqtp.tv_sec) * 1000000000);

	if (rqtp.tv_sec != trunc(timeInterval))
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
	usleep((unsigned int)
	    ((timeInterval - (unsigned int)timeInterval) * 1000000));
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

#if defined(OF_WII)
+ (void)waitForVerticalBlank
{
	VIDEO_WaitVSync();
}
#elif defined(OF_NINTENDO_DS)
+ (void)waitForVerticalBlank
{
	swiWaitForVBlank();
}
#elif defined(OF_NINTENDO_3DS)
+ (void)waitForVerticalBlank
{
	gspWaitForVBlank();
}
#endif

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
	OFThread *thread = OFTLSKeyGet(threadSelfKey);

	if (thread == mainThread)
		@throw [OFInvalidArgumentException exception];

	OFEnsure(thread != nil);

	thread->_returnValue = objc_retain(object);
	longjmp(thread->_exitEnv, 1);

	OF_UNREACHABLE
}

+ (void)setName: (OFString *)name
{
	[OFThread currentThread].name = name;

	if (name != nil)
		OFSetThreadName(
		    [name cStringWithEncoding: [OFLocale encoding]]);
	else
		OFSetThreadName(class_getName([self class]));
}

+ (OFString *)name
{
	return [OFThread currentThread].name;
}

+ (void)of_createMainThread
{
	mainThread = [[OFThread alloc] init];
	mainThread->_thread = OFCurrentPlainThread();
	mainThread->_running = OFThreadStateRunning;

	if (OFTLSKeySet(threadSelfKey, mainThread) != 0)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

- (instancetype)init
{
	self = [super init];

	@try {
		if (OFPlainThreadAttributesInit(&_attr) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

# ifdef OF_HAVE_BLOCKS
- (instancetype)initWithBlock: (OFThreadBlock)block
{
	self = [self init];

	@try {
		_block = [block copy];
	} @catch (id e) {
		objc_release(self);
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
	objc_release(oldRunLoop);

	objc_release(_threadDictionary);
	_threadDictionary = nil;

# ifdef OF_HAVE_SOCKETS
	objc_release(_DNSResolver);
	_DNSResolver = nil;
# endif
}

- (void)start
{
	int error;

	if (_running == OFThreadStateRunning)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	if (_running == OFThreadStateWaitingForJoin) {
		OFPlainThreadDetach(_thread);
		objc_release(_returnValue);
	}

	objc_retain(self);

	_running = OFThreadStateRunning;

	if ((error = OFPlainThreadNew(&_thread, [_name cStringWithEncoding:
	    [OFLocale encoding]], callMain, self, &_attr)) != 0) {
		objc_release(self);
		@throw [OFStartThreadFailedException
		    exceptionWithThread: self
				  errNo: error];
	}
}

- (id)join
{
	int error;

	if (_running == OFThreadStateNotRunning)
		@throw [OFJoinThreadFailedException
		    exceptionWithThread: self
				  errNo: EINVAL];

	if ((error = OFPlainThreadJoin(_thread)) != 0)
		@throw [OFJoinThreadFailedException exceptionWithThread: self
								  errNo: error];

	_running = OFThreadStateNotRunning;

	return _returnValue;
}

- (id)copy
{
	return objc_retain(self);
}

- (OFRunLoop *)runLoop
{
# if defined(OF_HAVE_ATOMIC_OPS) && !defined(__clang_analyzer__)
	if (_runLoop == nil) {
		OFRunLoop *tmp = [[OFRunLoop alloc] init];

		if (!OFAtomicPointerCompareAndSwap(
		    (void **)&_runLoop, nil, tmp))
			objc_release(tmp);
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
	if (_running == OFThreadStateRunning)
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
	if (_running == OFThreadStateRunning)
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
	if (_running == OFThreadStateRunning)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	_supportsSockets = supportsSockets;
}

- (void)dealloc
{
	if (_running == OFThreadStateRunning)
		@throw [OFThreadStillRunningException
		    exceptionWithThread: self];

	/*
	 * We should not be running anymore, but call detach in order to free
	 * the resources.
	 */
	if (_running == OFThreadStateWaitingForJoin)
		OFPlainThreadDetach(_thread);

	objc_release(_returnValue);
# ifdef OF_HAVE_BLOCKS
	objc_release(_block);
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
