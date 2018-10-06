/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

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
@class OFDate;

/*!
 * @brief A mode for an OFRunLoop.
 */
typedef OFConstantString *of_run_loop_mode_t;

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief The default mode for an OFRunLoop.
 */
extern of_run_loop_mode_t of_run_loop_mode_default;
#ifdef __cplusplus
}
#endif

/*!
 * @class OFRunLoop OFRunLoop.h ObjFW/OFRunLoop.h
 *
 * @brief A class providing a run loop for the application and its processes.
 */
@interface OFRunLoop: OFObject
{
	OFMutableDictionary *_states;
#ifdef OF_HAVE_THREADS
	OFMutex *_statesMutex;
#endif
	of_run_loop_mode_t _Nullable _currentMode;
	volatile bool _stop;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nullable, nonatomic) OFRunLoop *mainRunLoop;
@property (class, readonly, nullable, nonatomic) OFRunLoop *currentRunLoop;
#endif
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    of_run_loop_mode_t currentMode;

/*!
 * @brief Returns the run loop for the main thread.
 *
 * @return The run loop for the main thread
 */
+ (nullable OFRunLoop *)mainRunLoop;

/*!
 * @brief Returns the run loop for the current thread.
 *
 * @return The run loop for the current thread
 */
+ (nullable OFRunLoop *)currentRunLoop;

/*!
 * @brief Adds an OFTimer to the run loop.
 *
 * @param timer The timer to add
 */
- (void)addTimer: (OFTimer *)timer;

/*!
 * @brief Adds an OFTimer to the run loop for the specified mode.
 *
 * @param timer The timer to add
 * @param mode The run loop mode in which to run the timer
 */
- (void)addTimer: (OFTimer *)timer
	 forMode: (of_run_loop_mode_t)mode;

/*!
 * @brief Starts the run loop.
 */
- (void)run;

/*!
 * @brief Run the run loop until the specified deadline.
 *
 * @param deadline The date until which the run loop should run
 */
- (void)runUntilDate: (nullable OFDate *)deadline;

/*!
 * @brief Run the run loop until an event or timer occurs or the specified
 *	  deadline is reached.
 *
 * @param mode The mode in which to run the run loop
 * @param deadline The date until which the run loop should run at the longest
 */
- (void)runMode: (of_run_loop_mode_t)mode
     beforeDate: (nullable OFDate *)deadline;

/*!
 * @brief Stops the run loop. If there is still an operation being executed, it
 *	  is finished before the run loop stops.
 */
- (void)stop;
@end

OF_ASSUME_NONNULL_END
