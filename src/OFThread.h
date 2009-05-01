/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#ifndef _WIN32
#include <pthread.h>
#else
#include <windows.h>
#endif

#import "OFObject.h"

/**
 * The OFThread class provides portable threads.
 *
 * To use it, you should create a new class derived from it and reimplement
 * main.
 */
@interface OFThread: OFObject
{
	id object;
#ifndef _WIN32
	pthread_t thread;
#else
	HANDLE thread;

@public
	id retval;
#endif
}

/**
 * \param obj An object that is passed to the main method
 * \return A new, autoreleased thread
 */
+ threadWithObject: (id)obj;

/**
 * \param obj An object that is passed to the main method
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
