/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

/**
 * @class OFCondition OFCondition.h ObjFW/OFCondition.h
 *
 * @brief A class implementing a condition variable for thread synchronization.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFCondition: OFMutex
{
	of_condition_t _condition;
	bool _conditionInitialized;
}

/**
 * @brief Creates a new condition.
 *
 * @return A new, autoreleased OFCondition
 */
+ (instancetype)condition;

/**
 * @brief Blocks the current thread until another thread calls @ref signal or
 *	  @ref broadcast.
 *
 * @note Waiting might have been interrupted by a signal. It is thus recommended
 *	 to check the condition again after @ref wait returned!
 */
- (void)wait;

#ifdef OF_AMIGAOS
/**
 * @brief Blocks the current thread until another thread calls @ref signal,
 *	  @ref broadcast or an Exec Signal is received.
 *
 * @note This is only available on AmigaOS!
 *
 * @param signalMask A pointer to a signal mask of Exec Signals to receive.
 *		     This is modified and set to the mask of signals received.
 */
- (void)waitForConditionOrExecSignal: (ULONG *)signalMask;
#endif

/**
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

#ifdef OF_AMIGAOS
/**
 * @brief Blocks the current thread until another thread calls @ref signal,
 *	  @ref broadcast, the timeout is reached or an Exec Signal is received.
 *
 * @note This is only available on AmigaOS!
 *
 * @param timeInterval The time interval until the timeout is reached
 * @param signalMask A pointer to a signal mask of Exec Signals to receive.
 *		     This is modified and set to the mask of signals received.
 * @return Whether the condition has been signaled or a signal received
 */
- (bool)waitForTimeInterval: (of_time_interval_t)timeInterval
	       orExecSignal: (ULONG *)signalMask;
#endif

/**
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

#ifdef OF_AMIGAOS
/**
 * @brief Blocks the current thread until another thread calls @ref signal,
 *	  @ref broadcast, the timeout is reached or an Exec Signal is received.
 *
 * @note This is only available on AmigaOS!
 *
 * @param date The date at which the timeout is reached
 * @param signalMask A pointer to a signal mask of Exec Signals to receive.
 *		     This is modified and set to the mask of signals received.
 * @return Whether the condition has been signaled or a signal received
 */
- (bool)waitUntilDate: (OFDate *)date
	 orExecSignal: (ULONG *)signalMask;
#endif

/**
 * @brief Signals the next waiting thread to continue.
 */
- (void)signal;

/**
 * @brief Signals all threads to continue.
 */
- (void)broadcast;
@end

OF_ASSUME_NONNULL_END
