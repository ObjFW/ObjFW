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
 * @class OFBroadcastConditionFailedException
 *	  OFBroadcastConditionFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating broadcasting a condition failed.
 */
@interface OFBroadcastConditionFailedException: OFException
{
	OFCondition *_condition;
	int _errNo;
	OF_RESERVE_IVARS(OFBroadcastConditionFailedException, 4)
}

/**
 * @brief The condition which could not be broadcasted.
 */
@property (readonly, nonatomic) OFCondition *condition;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Returns a new, autoreleased condition broadcast failed exception.
 *
 * @param condition The condition which could not be broadcasted
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased condition broadcast failed exception
 */
+ (instancetype)exceptionWithCondition: (OFCondition *)condition
				 errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated condition broadcast failed exception.
 *
 * @param condition The condition which could not be broadcasted
 * @param errNo The errno of the error that occurred
 * @return An initialized condition broadcast failed exception
 */
- (instancetype)initWithCondition: (OFCondition *)condition
			    errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
