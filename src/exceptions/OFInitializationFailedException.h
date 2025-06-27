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

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFInitializationFailedException OFInitializationFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that initializing something failed.
 */
@interface OFInitializationFailedException: OFException
{
	Class _inClass;
	OF_RESERVE_IVARS(OFInitializationFailedException, 4)
}

/**
 * @brief The class for which initialization failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) Class inClass;

/**
 * @brief Creates a new, autoreleased initialization failed exception.
 *
 * @param class_ The class for which initialization failed
 * @return A new, autoreleased initialization failed exception
 */
+ (instancetype)exceptionWithClass: (nullable Class)class_;

/**
 * @brief Initializes an already allocated initialization failed exception.
 *
 * @param class_ The class for which initialization failed
 * @return An initialized initialization failed exception
 */
- (instancetype)initWithClass: (nullable Class)class_ OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
