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

#include <setjmp.h>

#import "OFObject.h"

#ifdef OF_HAVE_THREADS
# import "thread.h"
#endif

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFDate;
#ifdef OF_HAVE_SOCKETS
@class OFDNSResolver;
#endif
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
 * @warning Some operating systems such as AmigaOS need special per-thread
 *	    initialization of sockets. If you intend to use sockets in the
 *	    thread, set the @ref usesSockets property to true before starting
 *	    it.
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
	of_thread_block_t _Nullable _threadBlock;
# endif
	jmp_buf _exitEnv;
	id _returnValue;
@protected
	bool _supportsSockets;
	OFRunLoop *_Nullable _runLoop;
	OFMutableDictionary *_threadDictionary;
@private
	OFString *_Nullable _name;
# ifdef OF_HAVE_SOCKETS
	OFDNSResolver *_DNSResolver;
# endif
}
#endif

#ifdef OF_HAVE_CLASS_PROPERTIES
# ifdef OF_HAVE_THREADS
@property (class, readonly, nullable, nonatomic) OFThread *currentThread;
@property (class, readonly, nullable, nonatomic) OFThread *mainThread;
@property (class, readonly, nullable, nonatomic)
    OFMutableDictionary *threadDictionary;
@property (class, nullable, copy, nonatomic) OFString *name;
# endif
# ifdef OF_HAVE_SOCKETS
@property (class, readonly, nonatomic) OFDNSResolver *DNSResolver;
# endif
#endif

#ifdef OF_HAVE_THREADS
/*!
 * @brief The name for the thread to use when starting it.
 *
 * @note While this can be changed after the thread has been started, it will
 *	 have no effect once the thread started. If you want to change the name
 *	 of the current thread after it has been started, look at the class
 *	 method @ref setName:.
 */
@property OF_NULLABLE_PROPERTY (copy) OFString *name;

# ifdef OF_HAVE_BLOCKS
/*!
 * @brief The block to execute in the thread.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    of_thread_block_t threadBlock;
# endif

/*!
 * @brief The run loop for the thread.
 */
@property (readonly, nonatomic) OFRunLoop *runLoop;

/*!
 * @brief The priority of the thread.
 *
 * @note This has to be set before the thread is started!
 *
 * This is a value between -1.0 (meaning lowest priority that still schedules)
 * and +1.0 (meaning highest priority that still allows getting preempted)
 * with normal priority being 0.0 (meaning being the same as the main thread).
 */
@property (nonatomic) float priority;

/*!
 * @brief The stack size of the thread.
 *
 * @note This has to be set before the thread is started!
 */
@property (nonatomic) size_t stackSize;

/*!
 * @brief Whether the thread supports sockets.
 *
 * Some operating systems such as AmigaOS need special per-thread
 * initialization of sockets. If you intend to use sockets in the thread, set
 * this property to true before starting the thread.
 */
@property (nonatomic) bool supportsSockets;

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
+ (nullable OFThread *)currentThread;

/*!
 * @brief Returns the main thread.
 *
 * @return The main thread
 */
+ (nullable OFThread *)mainThread;

/*!
 * @brief Returns a dictionary to store thread-specific data, meaning it
 *	  returns a different dictionary for every thread.
 *
 * @return A dictionary to store thread-specific data
 */
+ (nullable OFMutableDictionary *)threadDictionary;
#endif

#ifdef OF_HAVE_SOCKETS
/*!
 * @brief Returns the DNS resolver for the current thread.
 *
 * @return The DNS resolver for the current thread
 */
+ (OFDNSResolver *)DNSResolver;
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

/*!
 * @brief Sets the name of the current thread.
 *
 * Unlike the instance method, this can be used after the thread has been
 * started.
 *
 * @param name The new name for the current thread.
 */
+ (void)setName: (nullable OFString *)name;

/*!
 * @brief Returns the name of the current thread.
 *
 * @return The name of the current thread.
 */
+ (nullable OFString *)name;

# ifdef OF_HAVE_BLOCKS
/*!
 * @brief Initializes an already allocated thread with the specified block.
 *
 * @param threadBlock A block which is executed by the thread
 * @return An initialized OFThread.
 */
- (instancetype)initWithThreadBlock: (of_thread_block_t)threadBlock;
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
#else
- (instancetype)init OF_UNAVAILABLE;
#endif
@end

OF_ASSUME_NONNULL_END
