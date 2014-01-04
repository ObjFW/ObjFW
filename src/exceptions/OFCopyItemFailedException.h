/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include <errno.h>

#import "OFException.h"

/*!
 * @brief An exception indicating that copying a item failed.
 */
@interface OFCopyItemFailedException: OFException
{
	OFString *_sourcePath, *_destinationPath;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *sourcePath;
@property (readonly, copy) OFString *destinationPath;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased copy item failed exception.
 *
 * @param sourcePath The original path
 * @param destinationPath The new path
 * @return A new, autoreleased copy item failed exception
 */
+ (instancetype)exceptionWithSourcePath: (OFString*)sourcePath
			destinationPath: (OFString*)destinationPath;

/*!
 * @brief Initializes an already allocated copy item failed exception.
 *
 * @param sourcePath The original path
 * @param destinationPath The new path
 * @return An initialized copy item failed exception
 */
- initWithSourcePath: (OFString*)sourcePath
     destinationPath: (OFString*)destinationPath;

/*!
 * @brief Returns the path of the source item.
 *
 * @return The path of the source item
 */
- (OFString*)sourcePath;

/*!
 * @brief Returns the destination path.
 *
 * @return The destination path
 */
- (OFString*)destinationPath;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
