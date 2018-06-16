/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include "config.h"

#define OF_THREAD_POOL_M

#import "OFThreadPool.h"
#import "OFArray.h"
#import "OFList.h"
#import "OFThread.h"
#import "OFCondition.h"
#import "OFSystemInfo.h"

@interface OFThreadPoolJob: OFObject
{
	id _target;
	SEL _selector;
	id _object;
#ifdef OF_HAVE_BLOCKS
	of_thread_pool_block_t _block;
#endif
}

- (instancetype)initWithTarget: (id)target
		      selector: (SEL)selector
			object: (id)object;
#ifdef OF_HAVE_BLOCKS
- (instancetype)initWithBlock: (of_thread_pool_block_t)block;
#endif
- (void)perform;
@end

@implementation OFThreadPoolJob
- (instancetype)initWithTarget: (id)target
		      selector: (SEL)selector
			object: (id)object
{
	self = [super init];

	@try {
		_target = [target retain];
		_selector = selector;
		_object = [object retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_BLOCKS
- (instancetype)initWithBlock: (of_thread_pool_block_t)block
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

- (void)dealloc
{
	[_target release];
	[_object release];
#ifdef OF_HAVE_BLOCKS
	[_block release];
#endif

	[super dealloc];
}

- (void)perform
{
#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block();
	else
#endif
		[_target performSelector: _selector
			      withObject: _object];
}
@end

@interface OFThreadPoolThread: OFThread
{
	OFList *_queue;
	OFCondition *_queueCondition, *_countCondition;
@public
	volatile bool _terminate;
	volatile int *_doneCount;
}

+ (instancetype)threadWithThreadPool: (OFThreadPool *)threadPool;
- (instancetype)initWithThreadPool: (OFThreadPool *)threadPool;
@end

@implementation OFThreadPoolThread
+ (instancetype)threadWithThreadPool: (OFThreadPool *)threadPool
{
	return [[[self alloc] initWithThreadPool: threadPool] autorelease];
}

- (instancetype)initWithThreadPool: (OFThreadPool *)threadPool
{
	self = [super init];

	@try {
		_queue = [threadPool->_queue retain];
		_queueCondition = [threadPool->_queueCondition retain];
		_countCondition = [threadPool->_countCondition retain];
		_doneCount = &threadPool->_doneCount;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_queue release];
	[_queueCondition release];
	[_countCondition release];

	[super dealloc];
}

- (id)main
{
	void *pool;

	if (_terminate)
		return nil;

	pool = objc_autoreleasePoolPush();

	for (;;) {
		OFThreadPoolJob *job;

		[_queueCondition lock];
		@try {
			of_list_object_t *listObject;

			if (_terminate) {
				objc_autoreleasePoolPop(pool);
				return nil;
			}

			listObject = [_queue firstListObject];

			while (listObject == NULL) {
				[_queueCondition wait];

				if (_terminate) {
					objc_autoreleasePoolPop(pool);
					return nil;
				}

				listObject = [_queue firstListObject];
			}

			job = [[listObject->object retain] autorelease];
			[_queue removeListObject: listObject];
		} @finally {
			[_queueCondition unlock];
		}

		if (_terminate) {
			objc_autoreleasePoolPop(pool);
			return nil;
		}

		[job perform];

		if (_terminate) {
			objc_autoreleasePoolPop(pool);
			return nil;
		}

		objc_autoreleasePoolPop(pool);
		pool = objc_autoreleasePoolPush();

		[_countCondition lock];
		@try {
			if (_terminate) {
				objc_autoreleasePoolPop(pool);
				return nil;
			}

			(*_doneCount)++;

			[_countCondition signal];
		} @finally {
			[_countCondition unlock];
		}
	}
}
@end

@implementation OFThreadPool
+ (instancetype)threadPool
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)threadPoolWithSize: (size_t)size
{
	return [[[self alloc] initWithSize: size] autorelease];
}

- (instancetype)init
{
	return [self initWithSize: [OFSystemInfo numberOfCPUs]];
}

- (instancetype)initWithSize: (size_t)size
{
	self = [super init];

	@try {
		_size = size;
		_threads = [[OFMutableArray alloc] init];
		_queue = [[OFList alloc] init];
		_queueCondition = [[OFCondition alloc] init];
		_countCondition = [[OFCondition alloc] init];

		for (size_t i = 0; i < size; i++) {
			void *pool = objc_autoreleasePoolPush();

			OFThreadPoolThread *thread =
			    [OFThreadPoolThread threadWithThreadPool: self];

			[_threads addObject: thread];

			objc_autoreleasePoolPop(pool);
		}

		/*
		 * We need to start the threads in a separate loop to make sure
		 * _threads is not modified anymore to prevent a race condition.
		 */
		for (size_t i = 0; i < size; i++)
			[[_threads objectAtIndex: i] start];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_queueCondition lock];
	@try {
		[_countCondition lock];
		@try {
			for (OFThreadPoolThread *thread in _threads)
				thread->_terminate = true;
		} @finally {
			[_countCondition unlock];
		}

		[_queueCondition broadcast];
	} @finally {
		[_queueCondition unlock];
	}

	[_threads release];
	[_queue release];
	[_queueCondition release];
	[_countCondition release];

	[super dealloc];
}

- (void)of_dispatchJob: (OFThreadPoolJob *)job
{
	[_countCondition lock];
	_count++;
	[_countCondition unlock];

	[_queueCondition lock];
	@try {
		[_queue appendObject: job];
		[_queueCondition signal];
	} @finally {
		[_queueCondition unlock];
	}
}

- (void)waitUntilDone
{
	for (;;) {
		[_countCondition lock];
		@try {
			if (_doneCount == _count)
				return;

			[_countCondition wait];
		} @finally {
			[_countCondition unlock];
		}
	}
}

- (void)dispatchWithTarget: (id)target
		  selector: (SEL)selector
		    object: (id)object
{
	OFThreadPoolJob *job = [[OFThreadPoolJob alloc] initWithTarget: target
							      selector: selector
								object: object];
	@try {
		[self of_dispatchJob: job];
	} @finally {
		[job release];
	}
}

#ifdef OF_HAVE_BLOCKS
- (void)dispatchWithBlock: (of_thread_pool_block_t)block
{
	OFThreadPoolJob *job = [[OFThreadPoolJob alloc] initWithBlock: block];
	@try {
		[self of_dispatchJob: job];
	} @finally {
		[job release];
	}
}
#endif

- (size_t)size
{
	return _size;
}
@end
