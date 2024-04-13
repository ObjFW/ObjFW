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

#import "OFException.h"

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFCondition;

/**
 * @class OFConditionStillWaitingException \
 *	  OFConditionStillWaitingException.h \
 *	  ObjFW/OFConditionStillWaitingException.h
 *
 * @brief An exception indicating that a thread is still waiting for a
 *	  condition.
 */
@interface OFConditionStillWaitingException: OFException
{
	OFCondition *_condition;
	OF_RESERVE_IVARS(OFConditionStillWaitingException, 4)
}

/**
 * @brief The condition for which is still being waited.
 */
@property (readonly, nonatomic) OFCondition *condition;

/**
 * @brief Creates a new, autoreleased condition still waiting exception.
 *
 * @param condition The condition for which is still being waited
 * @return A new, autoreleased condition still waiting exception
 */
+ (instancetype)exceptionWithCondition: (OFCondition *)condition;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated condition still waiting exception.
 *
 * @param condition The condition for which is still being waited
 * @return An initialized condition still waiting exception
 */
- (instancetype)initWithCondition: (OFCondition *)condition
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
