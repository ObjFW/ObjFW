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

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFHashNotCalculatedException OFHashNotCalculatedException.h \
 *	  ObjFW/OFHashNotCalculatedException.h
 *
 * @brief An exception indicating that the hash has not been calculated yet.
 */
@interface OFHashNotCalculatedException: OFException
{
	id _object;
	OF_RESERVE_IVARS(OFHashNotCalculatedException, 4)
}

/**
 * @brief The hash which has not been calculated yet.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief Creates a new, autoreleased hash not calculated exception.
 *
 * @param object The hash which has not been calculated yet
 * @return A new, autoreleased hash not calculated exception
 */
+ (instancetype)exceptionWithObject: (id)object;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated hash not calculated exception.
 *
 * @param object The hash which has not been calculated yet
 * @return An initialized hash not calculated exception
 */
- (instancetype)initWithObject: (id)object OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
