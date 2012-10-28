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

/*!
 * @brief An exception indicating that copying a file failed.
 */
@interface OFCopyFileFailedException: OFException
{
	OFString *sourcePath;
	OFString *destinationPath;
	int errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy, nonatomic) OFString *sourcePath;
@property (readonly, copy, nonatomic) OFString *destinationPath;
@property (readonly) int errNo;
#endif

/*!
 * @param class_ The class of the object which caused the exception
 * @param source The original path
 * @param destination The new path
 * @return A new copy file failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			sourcePath: (OFString*)source
		   destinationPath: (OFString*)destination;

/*!
 * Initializes an already allocated copy file failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param source The original path
 * @param destination The new path
 * @return An initialized copy file failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)source
  destinationPath: (OFString*)destination;

/*!
 * @return The errno from when the exception was created
 */
- (int)errNo;

/*!
 * @return The path of the source file
 */
- (OFString*)sourcePath;

/*!
 * @return The destination path
 */
- (OFString*)destinationPath;
@end
