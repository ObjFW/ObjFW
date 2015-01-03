/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) id <OFLocking> lock;
#endif

/*!
 * @brief Creates a new, autoreleased unlock failed exception.
 *
 * @param lock The lock which could not be unlocked
 * @return A new, autoreleased unlock failed exception
 */
+ (instancetype)exceptionWithLock: (id <OFLocking>)lock;

/*!
 * @brief Initializes an already allocated unlock failed exception.
 *
 * @param lock The lock which could not be unlocked
 * @return An initialized unlock failed exception
 */
- initWithLock: (id <OFLocking>)lock;

/*!
 * @brief Returns the lock which could not be unlocked.
 *
 * @return The lock which could not be unlocked
 */
- (id <OFLocking>)lock;
@end
