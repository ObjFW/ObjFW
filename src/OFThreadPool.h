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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block for a job which should be executed in a thread pool.
 */
typedef void (^of_thread_pool_block_t)(void);
#endif

@class OFCondition;
@class OFList OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFThreadPoolJob;

/*!
 * @class OFThreadPool OFThreadPool.h ObjFW/OFThreadPool.h
 *
 * @brief A class providing a pool of reusable threads.
 *
 * @note When the thread pool is released, all threads will terminate after
 *	 they finish the job they are currently processing.
 */
@interface OFThreadPool: OFObject
{
	size_t _size;
	OFMutableArray *_threads;
	volatile int _count;
#ifdef OF_THREAD_POOL_M
@public
#endif
	OFList *_queue;
	OFCondition *_queueCondition;
	volatile int _doneCount;
	OFCondition *_countCondition;
}

/*!
 * @brief The size of the thread pool.
 */
@property (readonly, nonatomic) size_t size;

/*!
 * @brief Returns a new thread pool with one thread for each core in the system.
 *
 * @warning If for some reason the number of cores in the system could not be
 *	    determined, the pool will only have one thread!
 *
 * @return A new thread pool with one thread for each core in the system
 */
+ (instancetype)threadPool;

/*!
 * @brief Returns a new thread pool with the specified number of threads.
 *
 * @param size The number of threads for the pool
 * @return A new thread pool with the specified number of threads
 */
+ (instancetype)threadPoolWithSize: (size_t)size;

/*!
 * @brief Initializes an already allocated OFThreadPool with the specified
 *	  number of threads.
 *
 * @param size The number of threads for the pool
 * @return An initialized OFThreadPool with the specified number of threads
 */
- (instancetype)initWithSize: (size_t)size OF_DESIGNATED_INITIALIZER;

/*!
 * @brief Execute the specified selector on the specified target with the
 *	  specified object as soon as a thread is ready.
 *
 * @param target The target on which to perform the selector
 * @param selector The selector to perform on the target
 * @param object The object with which the selector is performed on the target
 */
- (void)dispatchWithTarget: (id)target
		  selector: (SEL)selector
		    object: (nullable id)object;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Executes the specified block as soon as a thread is ready.
 *
 * @param block The block to execute
 */
- (void)dispatchWithBlock: (of_thread_pool_block_t)block;
#endif

/*!
 * @brief Waits until all jobs are done.
 */
- (void)waitUntilDone;
@end

OF_ASSUME_NONNULL_END
