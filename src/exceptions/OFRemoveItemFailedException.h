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
 * @brief An exception indicating that removing an item failed.
 */
@interface OFRemoveItemFailedException: OFException
{
	OFString *_path;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *path;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased remove failed exception.
 *
 * @param path The path of the item which could not be removed
 * @return A new, autoreleased remove item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString*)path;

/*!
 * @brief Initializes an already allocated remove failed exception.
 *
 * @param path The path of the item which could not be removed
 * @return An initialized remove item failed exception
 */
- initWithPath: (OFString*)path;

/*!
 * @brief Returns the path of the item which could not be removed.
 *
 * @return The path of the item which could not be removed
 */
- (OFString*)path;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
