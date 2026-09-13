/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
 * @class OFSetOptionFailedException OFSetOptionFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that setting an option for an object failed.
 */
@interface OFSetOptionFailedException: OFException
{
	id _Nullable _object;
	int _errNo;
	OF_RESERVE_IVARS(OFSetOptionFailedException, 4)
}

/**
 * @brief The object for which the option could not be set.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id object;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased set option failed exception.
 *
 * @param object The object for which the option could not be set
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased set option failed exception
 */
+ (instancetype)exceptionWithObject: (nullable id)object errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated set option failed exception.
 *
 * @param object The object for which the option could not be set
 * @param errNo The errno of the error that occurred
 * @return An initialized set option failed exception
 */
- (instancetype)initWithObject: (nullable id)object
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
