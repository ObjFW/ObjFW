/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#ifdef OF_HAVE_THREADS
# import "threading.h"
#endif

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFDate;
@class OFRunLoop;
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);

#if defined(OF_HAVE_THREADS) && defined(OF_HAVE_BLOCKS)
/*!
 * @brief A block to be executed in a new thread.
 *
 * @return The object which should be returned when the thread is joined
 */
typedef id _Nullable (^of_thread_block_t)(void);
#endif

/*!
 * @class OFThread OFThread.h ObjFW/OFThread.h
 *
 * @brief A class which provides portable threads.
 *
 * To use it, you should create a new class derived from it and reimplement
 * main.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the thread, but instead retains it.
 *	    This is so that the thread can be used as a key for a dictionary,
 *	    so context can be associated with a thread.
 */
@interface OFThread: OFObject
#ifdef OF_HAVE_THREADS
    <OFCopying>
{
# ifdef OF_THREAD_M
@public
# else
@private
# endif
	of_thread_t _thread;
	of_thread_attr_t _attr;
	enum of_thread_running {
		OF_THREAD_NOT_RUNNING,
		OF_THREAD_RUNNING,
		OF_THREAD_WAITING_FOR_JOIN
	} _running;
	void *_pool;
# ifdef OF_HAVE_BLOCKS
	of_thread_block_t _threadBlock;
# endif
	id _returnValue;
	OFRunLoop *_Nullable _runLoop;
	OFMutableDictionary *_threadDictionary;
@private
	OFString *_Nullable _name;
}

/*!
 * The name for the thread to use when starting it.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *name;

# ifdef OF_HAVE_BLOCKS
/*!
 * The block to execute in the thread.
 */
@property (readonly, nonatomic) of_thread_block_t threadBlock;
# endif

/*!
 * @brief Creates a new thread.
 *
 * @return A new, autoreleased thread
 */
+ (instancetype)thread;

# ifdef OF_HAVE_BLOCKS
/*!
 * @brief Creates a new thread with the specified block.
 *
 * @param threadBlock A block which is executed by the thread
 * @return A new, autoreleased thread
 */
+ (instancetype)threadWithThreadBlock: (of_thread_block_t)threadBlock;
# endif

/*!
 * @brief Returns the current thread.
 *
 * @return The current thread
 */
+ (OFThread *)currentThread;

/*!
 * @brief Returns the main thread.
 *
 * @return The main thread
 */
+ (OFThread *)mainThread;

/*!
 * @brief Returns a dictionary to store thread-specific data, meaning it
 *	  returns a different dictionary for every thread.
 *
 * @return A dictionary to store thread-specific data.
 */
+ (OFMutableDictionary *)threadDictionary;
#endif

/*!
 * @brief Suspends execution of the current thread for the specified time
 *	  interval.
 *
 * @param timeInterval The number of seconds to sleep
 */
+ (void)sleepForTimeInterval: (of_time_interval_t)timeInterval;

/*!
 * @brief Suspends execution of the current thread until the specified date.
 *
 * @param date The date to wait for
 */
+ (void)sleepUntilDate: (OFDate *)date;

/*!
 * @brief Yields a processor voluntarily and moves the thread to the end of the
 *	  queue for its priority.
 */
+ (void)yield;

#ifdef OF_HAVE_THREADS
/*!
 * @brief Terminates the current thread, letting it return `nil`.
 */
+ (void)terminate OF_NO_RETURN;

/*!
 * @brief Terminates the current thread, letting it return the specified object.
 *
 * @param object The object which the terminated thread will return
 */
+ (void)terminateWithObject: (nullable id)object OF_NO_RETURN;

# ifdef OF_HAVE_BLOCKS
/*!
 * @brief Initializes an already allocated thread with the specified block.
 *
 * @param threadBlock A block which is executed by the thread
 * @return An initialized OFThread.
 */
- initWithThreadBlock: (of_thread_block_t)threadBlock;
# endif

/*!
 * @brief The main routine of the thread. You need to reimplement this!
 *
 * @return The object the join method should return when called for this thread
 */
- (nullable id)main;

/*!
 * @brief This routine is executed when the thread's main method has finished
 *	  executing or terminate has been called.
 *
 * @note Be sure to call [super handleTermination]!
 */
- (void)handleTermination OF_REQUIRES_SUPER;

/*!
 * @brief Starts the thread.
 */
- (void)start;

/*!
 * @brief Joins a thread.
 *
 * @return The object returned by the main method of the thread.
 */
- (id)join;

/*!
 * @brief Returns the run loop for the thread.
 *
 * @return The run loop for the thread
 */
- (OFRunLoop *)runLoop;

/*!
 * @brief Returns the priority of the thread.
 *
 * This is a value between -1.0 (meaning lowest priority that still schedules)
 * and +1.0 (meaning highest priority that still allows getting preempted)
 * with normal priority being 0.0 (meaning being the same as the main thread).
 *
 * @return The priority of the thread
 */
- (float)priority;

/*!
 * @brief Sets the priority of the thread.
 *
 * @note This has to be set before the thread is started!
 *
 * @param priority The priority of the thread. This is a value between -1.0
 *		   (meaning lowest priority that still schedules) and +1.0
 *		   (meaning highest priority that still allows getting
 *		   preempted) with normal priority being 0.0 (meaning being
 *		   the same as the main thread).
 */
- (void)setPriority: (float)priority;

/*!
 * @brief Returns the stack size of the thread.
 *
 * @return The stack size of the thread
 */
- (size_t)stackSize;

/*!
 * @brief Sets the stack size of the thread.
 *
 * @note This has to be set before the thread is started!
 *
 * @param stackSize The stack size for the thread
 */
- (void)setStackSize: (size_t)stackSize;
#else
- init OF_UNAVAILABLE;
#endif
@end

OF_ASSUME_NONNULL_END
