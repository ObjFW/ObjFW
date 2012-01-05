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

@class OFMutex;

/**
 * \brief An exception indicating that locking a mutex failed.
 */
@interface OFMutexLockFailedException: OFException
{
	OFMutex *mutex;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFMutex *mutex;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param mutex The mutex which is could not be locked
 * \return A new mutex lock failed exception
 */
+ exceptionWithClass: (Class)class_
	       mutex: (OFMutex*)mutex;

/**
 * Initializes an already allocated mutex lock failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param mutex The mutex which is could not be locked
 * \return An initialized mutex lock failed exception
 */
- initWithClass: (Class)class_
	  mutex: (OFMutex*)mutex;

/**
 * \param The mutex which is could not be locked
 */
- (OFMutex*)mutex;
@end
