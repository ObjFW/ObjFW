/*
 * Copyright (c) 2008, 2009, 2010, 2011
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
 * \brief An exception indicating that unlocking a mutex failed.
 */
@interface OFMutexUnlockFailedException: OFException
{
	OFMutex *mutex;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFMutex *mutex;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param mutex The mutex which could not be unlocked
 * \return A new mutex unlock failed exception
 */
+ exceptionWithClass: (Class)class_
	       mutex: (OFMutex*)mutex;

/**
 * Initializes an already allocated mutex unlock failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param mutex The mutex which could not be unlocked
 * \return An initialized mutex unlock failed exception
 */
- initWithClass: (Class)class_
	  mutex: (OFMutex*)mutex;

/**
 * \return The mutex which could not be unlocked
 */
- (OFMutex*)mutex;
@end
