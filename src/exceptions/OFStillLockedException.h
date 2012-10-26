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

/**
 * \brief An exception indicating that a lock is still locked.
 */
@interface OFStillLockedException: OFException
{
	id <OFLocking> lock;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) id <OFLocking> lock;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param lock The lock which is still locked
 * \return A new still locked exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			      lock: (id <OFLocking>)lock;

/**
 * Initializes an already allocated still locked exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param lock The lock which is still locked
 * \return An initialized still locked exception
 */
- initWithClass: (Class)class_
	   lock: (id <OFLocking>)lock;

/**
 * \return The lock which is still locked
 */
- (id <OFLocking>)lock;
@end
