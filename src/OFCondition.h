/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFMutex.h"
#import "OFPlainCondition.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDate;

/**
 * @class OFCondition OFCondition.h ObjFW/ObjFW.h
 *
 * @brief A class implementing a condition variable for thread synchronization.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFCondition: OFMutex
{
	OFPlainCondition _condition;
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
 *
 * @throw OFWaitForConditionFailedException Waiting for the condition failed
 */
- (void)wait;

#if defined(OF_AMIGAOS) || defined(DOXYGEN)
/**
 * @brief Blocks the current thread until another thread calls @ref signal,
 *	  @ref broadcast or an Exec Signal is received.
 *
 * @note This is only available on AmigaOS!
 *
 * @param signalMask A pointer to a signal mask of Exec Signals to receive.
 *		     This is modified and set to the mask of signals received.
 * @throw OFWaitForConditionFailedException Waiting for the condition failed
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
 * @throw OFWaitForConditionFailedException Waiting for the condition failed
 */
- (bool)waitForTimeInterval: (OFTimeInterval)timeInterval;

#if defined(OF_AMIGAOS) || defined(DOXYGEN)
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
 * @throw OFWaitForConditionFailedException Waiting for the condition failed
 */
- (bool)waitForTimeInterval: (OFTimeInterval)timeInterval
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
 * @throw OFWaitForConditionFailedException Waiting for the condition failed
 */
- (bool)waitUntilDate: (OFDate *)date;

#if defined(OF_AMIGAOS) || defined(DOXYGEN)
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
 * @throw OFWaitForConditionFailedException Waiting for the condition failed
 */
- (bool)waitUntilDate: (OFDate *)date orExecSignal: (ULONG *)signalMask;
#endif

/**
 * @brief Signals the next waiting thread to continue.
 *
 * @throw OFSignalConditionFailedException Signaling the condition failed
 */
- (void)signal;

/**
 * @brief Signals all threads to continue.
 *
 * @throw OFBroadcastConditionFailedException Broadcasting the condition failed
 */
- (void)broadcast;
@end

OF_ASSUME_NONNULL_END
