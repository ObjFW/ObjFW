/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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
#ifdef OF_HAVE_SOCKETS
# import "OFTCPSocket.h"
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFSortedList OF_GENERIC(ObjectType);
#ifdef OF_HAVE_THREADS
@class OFMutex;
@class OFCondition;
#endif
#ifdef OF_HAVE_SOCKETS
@class OFKernelEventObserver;
#endif
@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);
@class OFTimer;

/*!
 * @class OFRunLoop OFRunLoop.h ObjFW/OFRunLoop.h
 *
 * @brief A class providing a run loop for the application and its processes.
 */
@interface OFRunLoop: OFObject
#ifdef OF_HAVE_SOCKETS
    <OFKernelEventObserverDelegate>
#endif
{
	OFSortedList *_timersQueue;
#ifdef OF_HAVE_THREADS
	OFMutex *_timersQueueLock;
#endif
#if defined(OF_HAVE_SOCKETS)
	OFKernelEventObserver *_kernelEventObserver;
	OFMutableDictionary *_readQueues;
#elif defined(OF_HAVE_THREADS)
	OFCondition *_condition;
#endif
	volatile bool _stop;
}

/*!
 * @brief Returns the main run loop.
 *
 * @return The main run loop
 */
+ (OFRunLoop*)mainRunLoop;

/*!
 * @brief Returns the run loop for the current thread.
 *
 * @return The run loop for the current thread
 */
+ (OFRunLoop*)currentRunLoop;

/*!
 * @brief Adds an OFTimer to the run loop.
 *
 * @param timer The timer to add
 */
- (void)addTimer: (OFTimer*)timer;

/*!
 * @brief Starts the run loop.
 */
- (void)run;

/*!
 * @brief Run the run loop until the specified deadline.
 *
 * @param deadline The date until which the run loop should run
 */
- (void)runUntilDate: (nullable OFDate*)deadline;

/*!
 * @brief Stops the run loop. If there is still an operation being executed, it
 *	  is finished before the run loop stops.
 */
- (void)stop;
@end

OF_ASSUME_NONNULL_END
