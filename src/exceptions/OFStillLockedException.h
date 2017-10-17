/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFException.h"
#import "OFLocking.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFStillLockedException \
 *	  OFStillLockedException.h ObjFW/OFStillLockedException.h
 *
 * @brief An exception indicating that a lock is still locked.
 */
@interface OFStillLockedException: OFException
{
	id <OFLocking> _lock;
}

/*!
 * The lock which is still locked.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id <OFLocking> lock;

/*!
 * @brief Creates a new, autoreleased still locked exception.
 *
 * @param lock The lock which is still locked
 * @return A new, autoreleased still locked exception
 */
+ (instancetype)exceptionWithLock: (nullable id <OFLocking>)lock;

/*!
 * @brief Initializes an already allocated still locked exception.
 *
 * @param lock The lock which is still locked
 * @return An initialized still locked exception
 */
- (instancetype)initWithLock: (nullable id <OFLocking>)lock
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
