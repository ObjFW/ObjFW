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

/*
 * TODO:
 *  - What to do when threads are running and the thread pool is deallocated?
 *  - How to tell the threads to terminate because they won't get new work?
 */

#include "config.h"

#import "OFThreadPool.h"
#import "OFArray.h"
#import "OFList.h"
#import "OFThread.h"
#import "OFAutoreleasePool.h"

@interface OFThreadPoolJob: OFObject
{
	id target;
	SEL selector;
	id object;
#ifdef OF_HAVE_BLOCKS
	of_thread_pool_block_t block;
#endif
}

+ jobWithTarget: (id)target
       selector: (SEL)selector
	 object: (id)object;
#ifdef OF_HAVE_BLOCKS
+ jobWithBlock: (of_thread_pool_block_t)block
	object: (id)object;
#endif
- initWithTarget: (id)target
	selector: (SEL)selector
	  object: (id)object;
#ifdef OF_HAVE_BLOCKS
- initWithBlock: (of_thread_pool_block_t)block
	 object: (id)object;
#endif
- (void)perform;
@end

@implementation OFThreadPoolJob
+ jobWithTarget: (id)target
       selector: (SEL)selector
	 object: (id)object
{
	return [[[self alloc] initWithTarget: target
				    selector: selector
				      object: object] autorelease];
}

#ifdef OF_HAVE_BLOCKS
+ jobWithBlock: (of_thread_pool_block_t)block
	object: (id)object
{
	return [[(OFThreadPoolJob*)[self alloc]
	    initWithBlock: block
		   object: object] autorelease];
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
	if (block != nil)
		block(object);
	else
#endif
		[object performSelector: selector
			     withObject: object];
}
@end

@interface OFThreadPoolThread: OFThread
{
	OFThreadPool *threadPool;
}

+ threadWithThreadPool: (OFThreadPool*)threadPool;
- initWithThreadPool: (OFThreadPool*)threadPool;
@end

@implementation OFThreadPoolThread
+ threadWithThreadPool: (OFThreadPool*)threadPool
{
	return [[[self alloc] initWithThreadPool: threadPool] autorelease];
}

- initWithThreadPool: (OFThreadPool*)threadPool_
{
	self = [super init];

	threadPool = threadPool_;

	return self;
}

- (id)main
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	for (;;) {
		OFThreadPoolJob *job;

		[threadPool->queueCondition lock];
		@try {
			of_list_object_t *listObject;

			listObject = [threadPool->queue firstListObject];

			while (listObject == NULL) {
				[threadPool->queueCondition wait];
				listObject =
				    [threadPool->queue firstListObject];
			}

			job = [[listObject->object retain] autorelease];
			[threadPool->queue removeListObject: listObject];
		} @finally {
			[threadPool->queueCondition unlock];
		}

		[job perform];
		[pool releaseObjects];

		[threadPool->countCondition lock];
		@try {
			threadPool->doneCount++;
			[threadPool->countCondition signal];
		} @finally {
			[threadPool->countCondition unlock];
		}
	}
}
@end

@implementation OFThreadPool
+ threadPool
{
	return [[[self alloc] init] autorelease];
}

+ threadPoolWithSize: (size_t)size
{
	return [[[self alloc] initWithSize: size] autorelease];
}

- init
{
	return [self initWithSize: of_num_cpus];
}

- initWithSize: (size_t)size_
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		size_t i;

		size = size_;
		threads = [[OFMutableArray alloc] init];
		queue = [[OFList alloc] init];
		queueCondition = [[OFCondition alloc] init];
		countCondition = [[OFCondition alloc] init];

		for (i = 0; i < size; i++) {
			OFThreadPoolThread *thread =
			    [OFThreadPoolThread threadWithThreadPool: self];

			[threads addObject: thread];

			[pool releaseObjects];
		}

		/*
		 * We need to start the threads in a separate loop to make sure
		 * threads is not modified anymore to prevent a race condition.
		 */
		for (i = 0; i < size; i++) {
			OFThreadPoolThread *thread = [threads objectAtIndex: i];

			[thread start];
		}

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[threads release];
	[queue release];
	[queueCondition release];
	[countCondition release];

	[super dealloc];
}

- (void)_dispatchJob: (OFThreadPoolJob*)job
{
	of_atomic_inc_int(&count);

	[queueCondition lock];
	@try {
		[queue appendObject: job];
		[queueCondition signal];
	} @finally {
		[queueCondition unlock];
	}
}

- (void)waitUntilFinished
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
	[self _dispatchJob: [OFThreadPoolJob jobWithTarget: target
						  selector: selector
						    object: object]];
}

#ifdef OF_HAVE_BLOCKS
- (void)dispatchWithBlock: (of_thread_pool_block_t)block
{
	[self _dispatchJob: [OFThreadPoolJob jobWithBlock: block
						   object: nil]];
}

- (void)dispatchWithBlock: (of_thread_pool_block_t)block
		   object: (id)object
{
	[self _dispatchJob: [OFThreadPoolJob jobWithBlock: block
						   object: object]];
}
#endif
@end
