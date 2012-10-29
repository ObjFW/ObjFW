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

/**
 * \brief An exception indicating changing to a directory failed
 */
@interface OFChangeDirectoryFailedException: OFException
{
	OFString *path;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy, nonatomic) OFString *path;
@property (readonly) int errNo;
#endif

/**
 * \brief Creates a new, autoreleased change directory failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the directory to which couldn't be
 *	       changed
 * \return A new, autoreleased change directory failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			      path: (OFString*)path;

/**
 * \brief Initializes an already allocated change directory failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the directory to which couldn't be
 *	       changed
 * \return An initialized change directory failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path;

/**
 * \brief Returns the errno from when the exception was created.
 *
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \brief Returns the path to which changing failed.
 *
 * \return The path to which changing failed
 */
- (OFString*)path;
@end
