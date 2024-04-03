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
 * @class OFAlreadyOpenException \
 *	  OFAlreadyOpenException.h ObjFW/OFAlreadyOpenException.h
 *
 * @brief An exception indicating that an object is already open and thus
 *	  cannot be opened again.
 */
@interface OFAlreadyOpenException: OFException
{
	id _object;
	OF_RESERVE_IVARS(OFAlreadyOpenException, 4)
}

/**
 * @brief The object which is already open.
 */
@property (readonly, nonatomic) id object;

/**
 * @brief Creates a new, autoreleased already open exception.
 *
 * @param object The object which is already open
 * @return A new, autoreleased already open exception
 */
+ (instancetype)exceptionWithObject: (id)object;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated already open exception.
 *
 * @param object The object which is already open
 * @return An initialized already open exception
 */
- (instancetype)initWithObject: (id)object OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
