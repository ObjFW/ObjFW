/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
 * @brief An exception indicating that locking a lock failed.
 */
@interface OFLockFailedException: OFException
{
	id <OFLocking> lock;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) id <OFLocking> lock;
#endif

/*!
 * @brief Creates a new, autoreleased lock failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param lock The lock which could not be locked
 * @return A new, autoreleased lock failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			      lock: (id <OFLocking>)lock;

/*!
 * @brief Initializes an already allocated lock failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param lock The lock which could not be locked
 * @return An initialized lock failed exception
 */
- initWithClass: (Class)class_
	   lock: (id <OFLocking>)lock;

/*!
 * @brief Returns the lock which could not be locked.
 *
 * @return The lock which could not be locked
 */
- (id <OFLocking>)lock;
@end
