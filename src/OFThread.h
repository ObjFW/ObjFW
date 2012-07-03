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
#import "OFList.h"

#import "threading.h"

@class OFDate;

#ifdef OF_HAVE_BLOCKS
typedef id (^of_thread_block_t)(id object);
#endif

/**
 * \brief A class for Thread Local Storage keys.
 */
@interface OFTLSKey: OFObject
{
@public
	of_tlskey_t key;
/* Work around a bug in gcc 4.4.4 (possibly only on Haiku) */
#if !defined(__GNUC__) || __GNUC__ != 4 || __GNUC_MINOR__ != 4 || \
    __GNUC_PATCHLEVEL__ != 4
@protected
#endif
	void (*destructor)(id);
	of_list_object_t *listObject;
	BOOL initialized;
}

/**
 * \brief Creates a new Thread Local Storage key
 *
 * \return A new, autoreleased Thread Local Storage key
 */
+ TLSKey;

/**
 * \brief Creates a new Thread Local Storage key with the specified destructor.
 *
 * \param destructor A destructor that is called when the thread is terminated
 * \return A new autoreleased Thread Local Storage key
 */
+ TLSKeyWithDestructor: (void(*)(id))destructor;

+ (void)callAllDestructors;

/**
 * \brief Initializes an already allocated Thread Local Storage Key with the
 *	  specified destructor.
 *
 * \param destructor A destructor that is called when the thread is terminated
 * \return An initialized Thread Local Storage key
 */
- initWithDestructor: (void(*)(id))destructor;
@end

/**
 * \brief A class which provides portable threads.
 *
 * To use it, you should create a new class derived from it and reimplement
 * main.
 */
@interface OFThread: OFObject
{
@public
	id object;
	of_thread_t thread;
	enum {
		OF_THREAD_NOT_RUNNING,
		OF_THREAD_RUNNING,
		OF_THREAD_WAITING_FOR_JOIN
	} running;
#ifdef OF_HAVE_BLOCKS
	of_thread_block_t block;
#endif
	id returnValue;
}

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
@property (copy) of_thread_block_t block;
#endif

/**
 * \brief Creates a new thread.
 *
 * \return A new, autoreleased thread
 */
+ thread;

/**
 * \brief Creates a new thread with the specified object.
 *
 * \param object An object which is passed for use in the main method or nil
 * \return A new, autoreleased thread
 */
+ threadWithObject: (id)object;

#ifdef OF_HAVE_BLOCKS
/**
 * \brief Creates a new thread with the specified block.
 *
 * \param block A block which is executed by the thread
 * \return A new, autoreleased thread
 */
+ threadWithBlock: (of_thread_block_t)block;

/**
 * \brief Creates a new thread with the specified block and object.
 *
 * \param block A block which is executed by the thread
 * \param object An object which is passed for use in the main method or nil
 * \return A new, autoreleased thread
 */
+ threadWithBlock: (of_thread_block_t)block
	   object: (id)object;
#endif

/**
 * \brief Sets the Thread Local Storage for the specified key.
 *
 * The specified object is first retained and then the object stored before is
 * released. You can specify nil as object if you want the old object to be
 * released and don't want any new object for the TLS key.
 *
 * \param key The Thread Local Storage key
 * \param object The object the Thread Local Storage key will be set to
 */
+ (void)setObject: (id)object
	forTLSKey: (OFTLSKey*)key;

/**
 * \brief Returns the object for the specified Thread Local Storage key.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \param key The Thread Local Storage key
 */
+ (id)objectForTLSKey: (OFTLSKey*)key;

/**
 * \brief Returns the current thread.
 *
 * \return The current thread or nil if we are in the main thread
 */
+ (OFThread*)currentThread;

/**
 * \brief Suspends execution of the current thread for the specified time
 *	  interval.
 *
 * \param seconds The number of seconds to sleep
 */
+ (void)sleepForTimeInterval: (double)seconds;

/**
 * \brief Suspends execution of the current thread until the specified date.
 *
 * \param date The date to wait for
 */
+ (void)sleepUntilDate: (OFDate*)date;

/**
 * \brief Yields a processor voluntarily and moves the thread at the end of the
 *	  queue for its priority.
 */
+ (void)yield;

/**
 * \brief Terminates the current thread, letting it return nil.
 */
+ (void)terminate;

/**
 * \brief Terminates the current thread, letting it return the specified object.
 *
 * \param object The object which the terminated thread will return
 */
+ (void)terminateWithObject: (id)object;

/**
 * \brief Initializes an already allocated thread with the specified object.
 *
 * \param object An object which is passed for use in the main method or nil
 * \return An initialized OFThread.
 */
- initWithObject: (id)object;

#ifdef OF_HAVE_BLOCKS
/**
 * \brief Initializes an already allocated thread with the specified block.
 *
 * \param block A block which is executed by the thread
 * \return An initialized OFThread.
 */
- initWithBlock: (of_thread_block_t)block;

/**
 * \brief Initializes an already allocated thread with the specified block and
 *	  object.
 *
 * \param block A block which is executed by the thread
 * \param object An object which is passed for use in the main method or nil
 * \return An initialized OFThread.
 */
- initWithBlock: (of_thread_block_t)block
	 object: (id)object;
#endif

/**
 * \brief The main routine of the thread. You need to reimplement this!
 *
 * It can access the object passed to the threadWithObject or initWithObject
 * method using the instance variable named object.
 *
 * \return The object the join method should return when called for this thread
 */
- (id)main;

/**
 * \brief This routine is exectued when the thread's main method has finished
 *	  executing or terminate has been called.
 */
- (void)handleTermination;

/**
 * \brief Starts the thread.
 */
- (void)start;

/**
 * \brief Joins a thread.
 *
 * \return The object returned by the main method of the thread.
 */
- (id)join;
@end

/**
 * \brief A class for creating mutual exclusions.
 */
@interface OFMutex: OFObject
{
	of_mutex_t mutex;
	BOOL initialized;
}

/**
 * \brief Creates a new mutex.
 *
 * \return A new autoreleased mutex.
 */
+ mutex;

/**
 * \brief Locks the mutex.
 */
- (void)lock;

/**
 * \brief Tries to lock the mutex.
 *
 * \return A boolean whether the mutex could be acquired
 */
- (BOOL)tryLock;

/**
 * \brief Unlocks the mutex.
 */
- (void)unlock;
@end

/**
 * \brief A class implementing a condition variable for thread synchronization.
 */
@interface OFCondition: OFMutex
{
	of_condition_t condition;
	BOOL conditionInitialized;
}

/**
 * \brief Creates a new condition.
 *
 * \return A new, autoreleased OFCondition
 */
+ condition;

/**
 * \brief Blocks the current thread until another thread calls -[signal] or
 *	  -[broadcast].
 */
- (void)wait;

/**
 * \brief Signals the next waiting thread to continue.
 */
- (void)signal;

/**
 * \brief Signals all threads to continue.
 */
- (void)broadcast;
@end
