/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
