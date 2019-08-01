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

#import "OFMutex.h"

#import "condition.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDate;

/*!
 * @class OFCondition OFCondition.h ObjFW/OFCondition.h
 *
 * @brief A class implementing a condition variable for thread synchronization.
 */
@interface OFCondition: OFMutex
{
	of_condition_t _condition;
	bool _conditionInitialized;
}

/*!
 * @brief Creates a new condition.
 *
 * @return A new, autoreleased OFCondition
 */
+ (instancetype)condition;

/*!
 * @brief Blocks the current thread until another thread calls @ref signal or
 *	  @ref broadcast.
 *
 * @note Waiting might have been interrupted by a signal. It is thus recommended
 *	 to check the condition again after @ref wait returned!
 */
- (void)wait;

/*!
 * @brief Blocks the current thread until another thread calls @ref signal,
 *	  @ref broadcast or the timeout is reached.
 *
 * @note Waiting might have been interrupted by a signal. It is thus recommended
 *	 to check the condition again after @ref waitForTimeInterval: returned!
 *
 * @param timeInterval The time interval until the timeout is reached
 * @return Whether the condition has been signaled
 */
- (bool)waitForTimeInterval: (of_time_interval_t)timeInterval;

/*!
 * @brief Blocks the current thread until another thread calls @ref signal,
 *	  @ref broadcast or the timeout is reached.
 *
 * @note Waiting might have been interrupted by a signal. It is thus recommended
 *	 to check the condition again after @ref waitUntilDate: returned!
 *
 * @param date The date at which the timeout is reached
 * @return Whether the condition has been signaled
 */
- (bool)waitUntilDate: (OFDate *)date;

/*!
 * @brief Signals the next waiting thread to continue.
 */
- (void)signal;

/*!
 * @brief Signals all threads to continue.
 */
- (void)broadcast;
@end

OF_ASSUME_NONNULL_END
