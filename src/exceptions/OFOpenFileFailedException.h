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
 * \brief An exception indicating a file couldn't be opened.
 */
@interface OFOpenFileFailedException: OFException
{
	OFString *path;
	OFString *mode;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *path;
@property (readonly, nonatomic) OFString *mode;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the file tried to open
 * \param mode A string with the mode in which the file should have been opened
 * \return A new open file failed exception
 */
+ exceptionWithClass: (Class)class_
		path: (OFString*)path
		mode: (OFString*)mode;

/**
 * Initializes an already allocated open file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path A string with the path of the file which couldn't be opened
 * \param mode A string with the mode in which the file should have been opened
 * \return An initialized open file failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path
	   mode: (OFString*)mode;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return A string with the path of the file which couldn't be opened
 */
- (OFString*)path;

/**
 * \return A string with the mode in which the file should have been opened
 */
- (OFString*)mode;
@end
