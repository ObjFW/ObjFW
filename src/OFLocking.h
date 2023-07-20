/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFLocking OFLocking.h ObjFW/OFLocking.h
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
