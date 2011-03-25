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

@class OFThread;

/**
 * \brief An exception indicating that starting a thread failed.
 */
@interface OFThreadStartFailedException: OFException
{
	OFThread *thread;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFThread *thread;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param thread The thread which could not be started
 * \return An initialized thread start failed exception
 */
+ newWithClass: (Class)class_
	thread: (OFThread*)thread;

/**
 * Initializes an already allocated thread start failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param thread The thread which could not be started
 * \return An initialized thread start failed exception
 */
- initWithClass: (Class)class_
	 thread: (OFThread*)thread;

/**
 * \return The thread which could not be started
 */
- (OFThread*)thread;
@end
