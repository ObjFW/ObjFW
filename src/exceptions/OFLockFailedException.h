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
 * @class OFLockFailedException OFLockFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that locking a lock failed.
 */
@interface OFLockFailedException: OFException
{
	id <OFLocking> _Nullable _lock;
	int _errNo;
	OF_RESERVE_IVARS(OFLockFailedException, 4)
}

/**
 * @brief The lock which could not be locked.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id <OFLocking> lock;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased lock failed exception.
 *
 * @param lock The lock which could not be locked
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased lock failed exception
 */
+ (instancetype)exceptionWithLock: (nullable id <OFLocking>)lock
			    errNo: (int)errNo;

/**
 * @brief Initializes an already allocated lock failed exception.
 *
 * @param lock The lock which could not be locked
 * @param errNo The errno of the error that occurred
 * @return An initialized lock failed exception
 */
- (instancetype)initWithLock: (nullable id <OFLocking>)lock
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
