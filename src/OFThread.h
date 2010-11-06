/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"
#import "OFList.h"

#import "threading.h"

/**
 * \brief A class for Thread Local Storage keys.
 */
@interface OFTLSKey: OFObject
{
@public
	of_tlskey_t key;
@protected
	void (*destructor)(id);
	of_list_object_t *listobj;
	BOOL initialized;
}

/**
 * \return A new autoreleased Thread Local Storage key
 */
+ tlsKey;

/**
 * \param destructor A destructor that is called when the thread is terminated
 * \return A new autoreleased Thread Local Storage key
 */
+ tlsKeyWithDestructor: (void(*)(id))destructor;

+ (void)callAllDestructors;

/**
 * \return An initialized Thread Local Storage key
 */
- init;

/**
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
	id object;
	of_thread_t thread;
@public
	enum {
		OF_THREAD_NOT_RUNNING,
		OF_THREAD_RUNNING,
		OF_THREAD_WAITING_FOR_JOIN
	} running;
	id retval;
}

/**
 * \param obj An object that is passed to the main method as a copy or nil
 * \return A new autoreleased thread
 */
+ threadWithObject: (id)obj;

/**
 * Sets the Thread Local Storage for the specified key.
 *
 * The specified object is first retained and then the object stored before is
 * released. You can specify nil as object if you want the old object to be
 * released and don't want any new object for the TLS key.
 *
 * \param key The Thread Local Storage key
 * \param obj The object the Thread Local Storage key will be set to
 * \return The old object, autoreleased
 */
+ (id)setObject: (id)obj
      forTLSKey: (OFTLSKey*)key;

/**
 * Returns the object for the specified Thread Local Storage key.
 *
 * The returned object is <i>not</i> retained and autoreleased for performance
 * reasons!
 *
 * \param key The Thread Local Storage key
 */
+ (id)objectForTLSKey: (OFTLSKey*)key;

/**
 * \return The current thread or nil if we are in the main thread
 */
+ (OFThread*)currentThread;

/**
 * Suspends execution of the current thread for N milliseconds.
 */
+ (void)sleepForNMilliseconds: (unsigned int)msecs;

/**
 * Yields a processor voluntarily and moves the thread at the end of the queue
 * for its priority.
 */
+ (void)yield;

/**
 * Terminates the current thread, letting it return nil.
 */
+ (void)terminate;

/**
 * Terminates the current thread, letting it return the specified object.
 *
 * \param The object which the terminated thread will return
 */
+ (void)terminateWithObject: (id)obj;

/**
 * \param obj An object that is passed to the main method as a copy or nil
 * \return An initialized OFThread.
 */
- initWithObject: (id)obj;

/**
 * The main routine of the thread. You need to reimplement this!
 *
 * It can access the object passed to the threadWithObject or initWithObject
 * method using the instance variable named object.
 *
 * \return The object the join method should return when called for this thread
 */
- (id)main;

/**
 * This routine is exectued when the thread's main method has finished executing
 * or terminate has been called.
 */
- (void)handleTermination;

/**
 * Starts the thread.
 */
- (void)start;

/**
 * Joins a thread.
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
 * \return A new autoreleased mutex.
 */
+ mutex;

/**
 * Locks the mutex.
 */
- (void)lock;

/**
 * Tries to lock the mutex and returns a boolean whether the mutex could be
 * acquired.
 *
 * \return A boolean whether the mutex could be acquired
 */
- (BOOL)tryLock;

/**
 * Unlocks the mutex.
 */
- (void)unlock;
@end
