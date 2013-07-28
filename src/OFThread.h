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

#import "OFObject.h"

#ifdef OF_HAVE_THREADS
# import "threading.h"
#endif

/*! @file */

@class OFDate;
@class OFRunLoop;
@class OFMutableDictionary;

#if defined(OF_HAVE_THREADS) && defined(OF_HAVE_BLOCKS)
/*!
 * @brief A block to be executed in a new thread.
 *
 * @return The object which should be returned when the thread is joined
 */
typedef id (^of_thread_block_t)(void);
#endif

/*!
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
	enum {
		OF_THREAD_NOT_RUNNING,
		OF_THREAD_RUNNING,
		OF_THREAD_WAITING_FOR_JOIN
	} _running;
# ifdef OF_HAVE_BLOCKS
	of_thread_block_t _threadBlock;
# endif
	id _returnValue;
	OFRunLoop *_runLoop;
	OFString *_name;
	OFMutableDictionary *_threadDictionary;
}

# ifdef OF_HAVE_PROPERTIES
#  ifdef OF_HAVE_BLOCKS
@property (copy) of_thread_block_t threadBlock;
#  endif
@property (copy) OFString *name;
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
+ (OFThread*)currentThread;

/*!
 * @brief Returns the main thread.
 *
 * @return The main thread
 */
+ (OFThread*)mainThread;

/*!
 * @brief Returns a dictionary to store thread-specific data, meaning it
 *	  returns a different dictionary for every thread.
 *
 * @return A dictionary to store thread-specific data.
 */
+ (OFMutableDictionary*)threadDictionary;
#endif

/*!
 * @brief Suspends execution of the current thread for the specified time
 *	  interval.
 *
 * @param seconds The number of seconds to sleep
 */
+ (void)sleepForTimeInterval: (double)seconds;

/*!
 * @brief Suspends execution of the current thread until the specified date.
 *
 * @param date The date to wait for
 */
+ (void)sleepUntilDate: (OFDate*)date;

/*!
 * @brief Yields a processor voluntarily and moves the thread to the end of the
 *	  queue for its priority.
 */
+ (void)yield;

#ifdef OF_HAVE_THREADS
/*!
 * @brief Terminates the current thread, letting it return nil.
 */
+ (void)terminate;

/*!
 * @brief Terminates the current thread, letting it return the specified object.
 *
 * @param object The object which the terminated thread will return
 */
+ (void)terminateWithObject: (id)object;

+ (void)OF_createMainThread;

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
 * It can access the object passed to the threadWithObject or initWithObject
 * method using the instance variable named object.
 *
 * @return The object the join method should return when called for this thread
 */
- (id)main;

/*!
 * @brief This routine is exectued when the thread's main method has finished
 *	  executing or terminate has been called.
 *
 * @note Be sure to call [super handleTermination]!
 */
- (void)handleTermination;

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
- (OFRunLoop*)runLoop;

/*!
 * @brief Returns the name of the thread or nil if none has been set.
 *
 * @return The name of the thread or nik if none has been set
 */
- (OFString*)name;

/*!
 * @brief Sets the name for the thread.
 *
 * @param name The name for the thread
 */
- (void)setName: (OFString*)name;
#endif
@end
