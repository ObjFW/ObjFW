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

#import "OFObject.h"

#ifdef OF_HAVE_BLOCKS
typedef void (^of_thread_pool_block_t)(id object);
#endif

@class OFMutableArray;
@class OFList;
@class OFCondition;
@class OFThreadPoolJob;

/**
 * \brief A class providing a pool of reusable threads.
 */
@interface OFThreadPool: OFObject
{
	size_t size;
	OFMutableArray *threads;
	int count;
@public
	OFList *queue;
	OFCondition *queueCondition;
	int doneCount;
	OFCondition *countCondition;
}

/**
 * \brief Returns a new thread pool with one thread for each core in the system.
 *
 * \warning If for some reason the number of cores in the system could not be
 *	    determined, the pool will only have one thread!
 *
 * \return A new thread pool with one thread for each core in the system
 */
+ threadPool;

/**
 * \brief Returns a new thread pool with the specified number of threads.
 *
 * \warning If for some reason the number of cores in the system could not be
 *	    determined, the pool will only have one thread!
 *
 * \param size The number of threads for the pool
 * \return A new thread pool with the specified number of threads
 */
+ threadPoolWithSize: (size_t)size;

/**
 * \brief Initializes an already allocated OFThreadPool with one thread for
 *	  each core in the system.
 *
 * \warning If for some reason the number of cores in the system could not be
 *	    determined, the pool will only have one thread!
 *
 * \return An initialized OFThreadPool with one thread for each core in the
 *	   system
 */
- init;

/**
 * \brief Initializes an already allocated OFThreadPool with the specified
 *	  number of threads.
 *
 * \warning If for some reason the number of cores in the system could not be
 *	    determined, the pool will only have one thread!
 *
 * \param size The number of threads for the pool
 * \return An initialized OFThreadPool with the specified number of threads
 */
- initWithSize: (size_t)size;

/**
 * \brief Execute the specified selector on the specified target with the
 *	  specified object as soon as a thread is ready.
 *
 * \param target The target on which to perform the selector
 * \param selector The selector to perform on the target
 * \param object THe object with which the selector is performed on the target
 */
- (void)dispatchWithTarget: (id)target
		  selector: (SEL)selector
		    object: (id)object;

#ifdef OF_HAVE_BLOCKS
/**
 * \brief Executes the specified block as soon as a thread is ready.
 *
 * \param block The block to execute
 */
- (void)dispatchWithBlock: (of_thread_pool_block_t)block;

/**
 * \brief Executes the specified block as soon as a thread is ready.
 *
 * \param block The block to execute
 * \param object The object to pass to the block
 */
- (void)dispatchWithBlock: (of_thread_pool_block_t)block
		   object: (id)object;
#endif

/**
 * \brief Waits until all threads have finished.
 */
- (void)waitUntilFinished;
@end
