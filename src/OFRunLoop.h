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

@class OFSortedList;
@class OFStreamObserver;
@class OFTimer;

/**
 * \brief A class providing a run loop for the application and its processes.
 */
@interface OFRunLoop: OFObject
{
	OFSortedList *timersQueue;
	OFStreamObserver *streamObserver;
}

/**
 * \brief Returns the main run loop.
 *
 * \return The main run loop
 */
+ (OFRunLoop*)mainRunLoop;

/**
 * \brief Returns the run loop for the current thread.
 *
 * \return The run loop for the current thread
 */
+ (OFRunLoop*)currentRunLoop;

+ (void)_setMainRunLoop: (OFRunLoop*)mainRunLoop;

/**
 * \brief Adds an OFTimer to the run loop.
 *
 * \param timer The timer to add
 */
- (void)addTimer: (OFTimer*)timer;

/**
 * \brief Starts the run loop.
 */
- (void)run;
@end
