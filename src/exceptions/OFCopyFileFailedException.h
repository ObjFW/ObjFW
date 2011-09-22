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

/**
 * \brief An exception indicating that copying a file failed.
 */
@interface OFCopyFileFailedException: OFException
{
	OFString *sourcePath;
	OFString *destinationPath;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *sourcePath;
@property (readonly, nonatomic) OFString *destinationPath;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param src The original path
 * \param dst The new path
 * \return A new copy file failed exception
 */
+ exceptionWithClass: (Class)class_
	  sourcePath: (OFString*)src
     destinationPath: (OFString*)dst;

/**
 * Initializes an already allocated copy file failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param src The original path
 * \param dst The new path
 * \return An initialized copy file failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)src
  destinationPath: (OFString*)dst;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The path of the source file
 */
- (OFString*)sourcePath;

/**
 * \return The destination path
 */
- (OFString*)destinationPath;
@end
