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
#import "OFLocking.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFStillLockedException OFStillLockedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a lock is still locked.
 */
@interface OFStillLockedException: OFException
{
	id <OFLocking> _Nullable _lock;
	OF_RESERVE_IVARS(OFStillLockedException, 4)
}

/**
 * @brief The lock which is still locked.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id <OFLocking> lock;

/**
 * @brief Creates a new, autoreleased still locked exception.
 *
 * @param lock The lock which is still locked
 * @return A new, autoreleased still locked exception
 */
+ (instancetype)exceptionWithLock: (nullable id <OFLocking>)lock;

/**
 * @brief Initializes an already allocated still locked exception.
 *
 * @param lock The lock which is still locked
 * @return An initialized still locked exception
 */
- (instancetype)initWithLock: (nullable id <OFLocking>)lock
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
