/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

#import "threading.h"

/**
 * A Thread Local Storage key.
 */
@interface OFTLSKey: OFObject
{
@public
	of_tlskey_t key;
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
 * The OFThread class provides portable threads.
 *
 * To use it, you should create a new class derived from it and reimplement
 * main.
 */
@interface OFThread: OFObject
{
	id object;
	of_thread_t thread;
	BOOL running;

@public
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
 */
+ setObject: (id)obj
  forTLSKey: (OFTLSKey*)key;

/**
 * Returns the object for the specified Thread Local Storage key.
 *
 * \param key The Thread Local Storage key
 */
+ (id)objectForTLSKey: (OFTLSKey*)key;

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
 * Joins a thread.
 *
 * \return The object returned by the main method of the thread.
 */
- join;
@end

/**
 * A class for creating mutual exclusions.
 */
@interface OFMutex: OFObject
{
	of_mutex_t mutex;
}

/**
 * \return A new autoreleased mutex.
 */
+ mutex;

/**
 * Locks the mutex.
 */
- lock;

/**
 * Unlocks the mutex.
 */
- unlock;
@end
