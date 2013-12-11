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

#include <errno.h>

#import "OFException.h"

/*!
 * @brief An exception indicating that moving an item failed.
 */
@interface OFMoveItemFailedException: OFException
{
	OFString *_sourcePath, *_destinationPath;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *sourcePath, *destinationPath;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased move item failed exception.
 *
 * @param sourcePath The original path
 * @param destinationPath The new path
 * @return A new, autoreleased move item failed exception
 */
+ (instancetype)exceptionWithSourcePath: (OFString*)sourcePath
			destinationPath: (OFString*)destinationPath;

/*!
 * @brief Initializes an already allocated move item failed exception.
 *
 * @param sourcePath The original path
 * @param destinationPath The new path
 * @return An initialized move item failed exception
 */
- initWithSourcePath: (OFString*)sourcePath
     destinationPath: (OFString*)destinationPath;

/*!
 * @brief Returns the original path.
 *
 * @return The original path
 */
- (OFString*)sourcePath;

/*!
 * @brief Returns the new path.
 *
 * @return The new path
 */
- (OFString*)destinationPath;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
