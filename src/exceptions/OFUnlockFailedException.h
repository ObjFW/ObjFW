/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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
 * @class OFUnlockFailedException \
 *	  OFUnlockFailedException.h ObjFW/OFUnlockFailedException.h
 *
 * @brief An exception indicating that unlocking a lock failed.
 */
@interface OFUnlockFailedException: OFException
{
	id <OFLocking> _lock;
}

/*!
 * @brief The lock which could not be unlocked.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id <OFLocking> lock;

/*!
 * @brief Creates a new, autoreleased unlock failed exception.
 *
 * @param lock The lock which could not be unlocked
 * @return A new, autoreleased unlock failed exception
 */
+ (instancetype)exceptionWithLock: (nullable id <OFLocking>)lock;

/*!
 * @brief Initializes an already allocated unlock failed exception.
 *
 * @param lock The lock which could not be unlocked
 * @return An initialized unlock failed exception
 */
- (instancetype)initWithLock: (nullable id <OFLocking>)lock
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
