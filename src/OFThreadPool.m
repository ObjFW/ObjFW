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

#import "OFThreadPool.h"
#import "OFArray.h"
#import "OFList.h"
#import "OFThread.h"
#import "OFCondition.h"
#import "OFSystemInfo.h"

#import "autorelease.h"

@interface OFThreadPoolJob: OFObject
{
	id target;
	SEL selector;
	id object;
#ifdef OF_HAVE_BLOCKS
	of_thread_pool_block_t block;
#endif
}

+ (instancetype)jobWithTarget: (id)target
		     selector: (SEL)selector
		       object: (id)object;
#ifdef OF_HAVE_BLOCKS
+ (instancetype)jobWithBlock: (of_thread_pool_block_t)block;
#endif
- initWithTarget: (id)target
	selector: (SEL)selector
	  object: (id)object;
#ifdef OF_HAVE_BLOCKS
- initWithBlock: (of_thread_pool_block_t)block;
#endif
- (void)perform;
@end

@implementation OFThreadPoolJob
+ (instancetype)jobWithTarget: (id)target
		     selector: (SEL)selector
		       object: (id)object
{
	return [[[self alloc] initWithTarget: target
				    selector: selector
				      object: object] autorelease];
}

#ifdef OF_HAVE_BLOCKS
+ (instancetype)jobWithBlock: (of_thread_pool_block_t)block
{
	return [[(OFThreadPoolJob*)[self alloc]
	    initWithBlock: block] autorelease];
}
#endif

- initWithTarget: (id)target_
	selector: (SEL)selector_
	  object: (id)object_
{
	self = [super init];

	@try {
		target = [target_ retain];
		selector = selector_;
		object = [object_ retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_BLOCKS
- initWithBlock: (of_thread_pool_block_t)block_
{
	self = [super init];

	@try {
		block = [block_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[target release];
	[object release];
#ifdef OF_HAVE_BLOCKS
	[block release];
#endif

	[super dealloc];
}

- (void)perform
{
#ifdef OF_HAVE_BLOCKS
	if (block != NULL)
		block();
	else
#endif
		[object performSelector: selector
			     withObject: object];
}
@end

@interface OFThreadPoolThread: OFThread
{
	OFList *queue;
	OFCondition *queueCondition, *countCondition;
@public
	volatile BOOL terminate;
	volatile int *doneCount;
}

+ (instancetype)threadWithThreadPool: (OFThreadPool*)threadPool;
- initWithThreadPool: (OFThreadPool*)threadPool;
@end

@implementation OFThreadPoolThread
+ (instancetype)threadWithThreadPool: (OFThreadPool*)threadPool
{
	return [[[self alloc] initWithThreadPool: threadPool] autorelease];
}

- initWithThreadPool: (OFThreadPool*)threadPool
{
	self = [super init];

	@try {
		queue = [threadPool->queue retain];
		queueCondition = [threadPool->queueCondition retain];
		countCondition = [threadPool->countCondition retain];
		doneCount = &threadPool->doneCount;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[queue release];
	[queueCondition release];
	[countCondition release];

	[super dealloc];
}

- (id)main
{
	void *pool;

	if (terminate)
		return nil;

	pool = objc_autoreleasePoolPush();

	for (;;) {
		OFThreadPoolJob *job;

		[queueCondition lock];
		@try {
			of_list_object_t *listObject;

			if (terminate) {
				objc_autoreleasePoolPop(pool);
				return nil;
			}

			listObject = [queue firstListObject];

			while (listObject == NULL) {
				[queueCondition wait];

				if (terminate) {
					objc_autoreleasePoolPop(pool);
					return nil;
				}

				listObject = [queue firstListObject];
			}

			job = [[listObject->object retain] autorelease];
			[queue removeListObject: listObject];
		} @finally {
			[queueCondition unlock];
		}

		if (terminate) {
			objc_autoreleasePoolPop(pool);
			return nil;
		}

		[job perform];

		if (terminate) {
			objc_autoreleasePoolPop(pool);
			return nil;
		}

		objc_autoreleasePoolPop(pool);
		pool = objc_autoreleasePoolPush();

		[countCondition lock];
		@try {
			if (terminate) {
				objc_autoreleasePoolPop(pool);
				return nil;
			}

			(*doneCount)++;

			[countCondition signal];
		} @finally {
			[countCondition unlock];
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

- init
{
	return [self initWithSize: [OFSystemInfo numberOfCPUs]];
}

- initWithSize: (size_t)size_
{
	self = [super init];

	@try {
		size_t i;

		size = size_;
		threads = [[OFMutableArray alloc] init];
		queue = [[OFList alloc] init];
		queueCondition = [[OFCondition alloc] init];
		countCondition = [[OFCondition alloc] init];

		for (i = 0; i < size; i++) {
			void *pool = objc_autoreleasePoolPush();

			OFThreadPoolThread *thread =
			    [OFThreadPoolThread threadWithThreadPool: self];

			[threads addObject: thread];

			objc_autoreleasePoolPop(pool);
		}

		/*
		 * We need to start the threads in a separate loop to make sure
		 * threads is not modified anymore to prevent a race condition.
		 */
		for (i = 0; i < size; i++) {
			OFThreadPoolThread *thread = [threads objectAtIndex: i];

			[thread start];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	void *pool = objc_autoreleasePoolPush();
	[queueCondition lock];
	@try {
		[countCondition lock];
		@try {
			OFEnumerator *enumerator = [threads objectEnumerator];
			OFThreadPoolThread *thread;

			while ((thread = [enumerator nextObject]) != nil)
				thread->terminate = YES;
		} @finally {
			[countCondition unlock];
		}

		[queueCondition broadcast];
	} @finally {
		[queueCondition unlock];
	}
	objc_autoreleasePoolPop(pool);

	[threads release];
	[queue release];
	[queueCondition release];
	[countCondition release];

	[super dealloc];
}

- (void)OF_dispatchJob: (OFThreadPoolJob*)job
{
	[countCondition lock];
	count++;
	[countCondition unlock];

	[queueCondition lock];
	@try {
		[queue appendObject: job];
		[queueCondition signal];
	} @finally {
		[queueCondition unlock];
	}
}

- (void)waitUntilDone
{
	for (;;) {
		[countCondition lock];
		@try {
			if (doneCount == count)
				return;

			[countCondition wait];
		} @finally {
			[countCondition unlock];
		}
	}
}

- (void)dispatchWithTarget: (id)target
		  selector: (SEL)selector
		    object: (id)object
{
	[self OF_dispatchJob: [OFThreadPoolJob jobWithTarget: target
						    selector: selector
						      object: object]];
}

#ifdef OF_HAVE_BLOCKS
- (void)dispatchWithBlock: (of_thread_pool_block_t)block
{
	[self OF_dispatchJob: [OFThreadPoolJob jobWithBlock: block]];
}
#endif

- (size_t)size
{
	return size;
}
@end
