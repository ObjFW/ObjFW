/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

/*!
 * @protocol OFLocking OFLocking.h ObjFW/OFLocking.h
 *
 * @brief A protocol for locks.
 */
@protocol OFLocking <OFObject>
#ifdef OF_HAVE_PROPERTIES
@property OF_NULLABLE_PROPERTY (copy) OFString *name;
#endif

/*!
 * @brief Locks the lock.
 */
- (void)lock;

/*!
 * @brief Tries to lock the lock.
 *
 * @return A boolean whether the lock could be locked
 */
- (bool)tryLock;

/*!
 * @brief Unlocks the lock.
 */
- (void)unlock;

/*!
 * @brief Sets a name for the lock.
 *
 * @param name The name for the lock
 */
- (void)setName: (nullable OFString*)name;

/*!
 * @brief Returns the name for the lock.
 *
 * @return The name for the lock
 */
- (nullable OFString*)name;
@end

OF_ASSUME_NONNULL_END
