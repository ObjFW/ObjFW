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
 * @class OFOutOfMemoryException OFOutOfMemoryException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating there is not enough memory available.
 */
@interface OFOutOfMemoryException: OFException
{
	size_t _requestedSize;
	OF_RESERVE_IVARS(OFOutOfMemoryException, 4)
}

/**
 * @brief The size of the memory that could not be allocated.
 */
@property (readonly, nonatomic) size_t requestedSize;

/**
 * @brief Creates a new, autoreleased no memory exception.
 *
 * @param requestedSize The size of the memory that could not be allocated
 * @return A new, autoreleased no memory exception
 */
+ (instancetype)exceptionWithRequestedSize: (size_t)requestedSize;

/**
 * @brief Initializes an already allocated no memory exception.
 *
 * @param requestedSize The size of the memory that could not be allocated
 * @return An initialized no memory exception
 */
- (instancetype)initWithRequestedSize: (size_t)requestedSize
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
