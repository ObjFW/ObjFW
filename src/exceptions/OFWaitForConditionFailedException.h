/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
 * @class OFWaitForConditionFailedException OFWaitForConditionFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating waiting for a condition failed.
 */
@interface OFWaitForConditionFailedException: OFException
{
	OFCondition *_condition;
	int _errNo;
	OF_RESERVE_IVARS(OFWaitForConditionFailedException, 4)
}

/**
 * @brief The condition for which could not be waited.
 */
@property (readonly, nonatomic) OFCondition *condition;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased condition wait failed exception.
 *
 * @param condition The condition for which could not be waited
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased condition wait failed exception
 */
+ (instancetype)exceptionWithCondition: (OFCondition *)condition
				 errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated condition wait failed exception.
 *
 * @param condition The condition for which could not be waited
 * @param errNo The errno of the error that occurred
 * @return An initialized condition wait failed exception
 */
- (instancetype)initWithCondition: (OFCondition *)condition
			    errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
