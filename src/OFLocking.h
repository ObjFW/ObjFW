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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFLocking OFLocking.h ObjFW/ObjFW.h
 *
 * @brief A protocol for locks.
 */
@protocol OFLocking <OFObject>
/**
 * @brief The name of the lock.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *name;

/**
 * @brief Locks the lock.
 *
 * @throw OFLockFailedException Acquiring the lock failed
 */
- (void)lock;

/**
 * @brief Tries to lock the lock.
 *
 * @return A boolean whether the lock could be locked
 *
 * @throw OFLockFailedException The lock could not be acquired for another
 *				reason than it already being held
 */
- (bool)tryLock;

/**
 * @brief Unlocks the lock.
 *
 * @throw OFUnlockFailedException Releasing the lock failed
 */
- (void)unlock;
@end

OF_ASSUME_NONNULL_END
