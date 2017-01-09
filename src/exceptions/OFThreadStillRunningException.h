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

#import "OFException.h"

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

@class OFThread;

/*!
 * @class OFThreadStillRunningException \
 *	  OFThreadStillRunningException.h ObjFW/OFThreadStillRunningException.h
 *
 * @brief An exception indicating that a thread is still running.
 */
@interface OFThreadStillRunningException: OFException
{
	OFThread *_thread;
}

/*!
 * The thread which is still running.
 */
@property (readonly, retain) OFThread *thread;

/*!
 * @brief Creates a new, autoreleased thread still running exception.
 *
 * @param thread The thread which is still running
 * @return A new, autoreleased thread still running exception
 */
+ (instancetype)exceptionWithThread: (OFThread*)thread;

/*!
 * @brief Initializes an already allocated thread still running exception.
 *
 * @param thread The thread which is still running
 * @return An initialized thread still running exception
 */
- initWithThread: (OFThread*)thread;
@end
