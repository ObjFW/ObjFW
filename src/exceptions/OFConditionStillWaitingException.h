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

#import "OFException.h"

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFCondition;

/*!
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
}

/*!
 * @brief The condition for which is still being waited.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFCondition *condition;

/*!
 * @brief Creates a new, autoreleased condition still waiting exception.
 *
 * @param condition The condition for which is still being waited
 * @return A new, autoreleased condition still waiting exception
 */
+ (instancetype)exceptionWithCondition: (nullable OFCondition *)condition;

/*!
 * @brief Initializes an already allocated condition still waiting exception.
 *
 * @param condition The condition for which is still being waited
 * @return An initialized condition still waiting exception
 */
- (instancetype)initWithCondition: (nullable OFCondition *)condition
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
