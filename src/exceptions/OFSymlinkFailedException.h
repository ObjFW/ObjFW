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

#ifdef OF_HAVE_SYMLINK
/*!
 * @brief An exception indicating that creating a symlink failed.
 */
@interface OFSymlinkFailedException: OFException
{
	OFString *_sourcePath, *_destinationPath;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy, nonatomic) OFString *sourcePath, *destinationPath;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased symlink failed exception.
 *
 * @param sourcePath The source for the symlink
 * @param destinationPath The destination for the symlink
 * @return A new, autoreleased symlink failed exception
 */
+ (instancetype)exceptionWithSourcePath: (OFString*)sourcePath
			destinationPath: (OFString*)destinationPath;

/*!
 * @brief Initializes an already allocated symlink failed exception.
 *
 * @param sourcePath The source for the symlink
 * @param destinationPath The destination for the symlink
 * @return An initialized symlink failed exception
 */
- initWithSourcePath: (OFString*)sourcePath
     destinationPath: (OFString*)destinationPath;

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

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
#endif
