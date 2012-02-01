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

#include <sys/types.h>

#import "OFException.h"

/**
 * \brief An exception indicating that changing the mode of a file failed.
 */
@interface OFChangeFileModeFailedException: OFException
{
	OFString *path;
	mode_t mode;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, assign) OFString *path;
@property (readonly) mode_t mode;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param mode The new mode for the file
 * \return An initialized change file mode failed exception
 */
+ exceptionWithClass: (Class)class_
		path: (OFString*)path
		mode: (mode_t)mode;

/**
 * Initializes an already allocated change file mode failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param path The path of the file
 * \param mode The new mode for the file
 * \return An initialized change file mode failed exception
 */
- initWithClass: (Class)class_
	   path: (OFString*)path
	   mode: (mode_t)mode;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the file
 */
- (OFString*)path;

/**
 * \return The new mode for the file
 */
- (mode_t)mode;
@end
