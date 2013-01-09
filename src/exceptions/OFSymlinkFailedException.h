/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#ifndef _WIN32
/*!
 * @brief An exception indicating that creating a symlink failed.
 */
@interface OFSymlinkFailedException: OFException
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
 * @brief Creates a new, autoreleased symlink failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param source The source for the symlink
 * @param destination The destination for the symlink
 * @return A new, autoreleased symlink failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			sourcePath: (OFString*)source
		   destinationPath: (OFString*)destination;

/*!
 * @brief Initializes an already allocated symlink failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param source The source for the symlink
 * @param destination The destination for the symlink
 * @return An initialized symlink failed exception
 */
-   initWithClass: (Class)class_
       sourcePath: (OFString*)source
  destinationPath: (OFString*)destination;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;

/*!
 * @brief Returns a string with the source for the symlink.
 *
 * @return A string with the source for the symlink
 */
- (OFString*)sourcePath;

/*!
 * @brief Returns a string with the destination for the symlink.
 *
 * @return A string with the destination for the symlink
 */
- (OFString*)destinationPath;
@end
#endif
