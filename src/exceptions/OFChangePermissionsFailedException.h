/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#include <sys/types.h>

#import "OFException.h"

/*!
 * @class OFChangePermissionsFailedException \
 *	  OFChangePermissionsFailedException.h \
 *	  ObjFW/OFChangePermissionsFailedException.h
 *
 * @brief An exception indicating that changing the permissions of an item
 *	  failed.
 */
@interface OFChangePermissionsFailedException: OFException
{
	OFString *_path;
	mode_t _permissions;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *path;
@property (readonly) mode_t permissions;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased change permissions failed exception.
 *
 * @param path The path of the item
 * @param permissions The new permissions for the item
 * @return A new, autoreleased change permissions failed exception
 */
+ (instancetype)exceptionWithPath: (OFString*)path
		      permissions: (mode_t)permissions;

/*!
 * @brief Initializes an already allocated change permissions failed exception.
 *
 * @param path The path of the item
 * @param permissions The new permissions for the item
 * @return An initialized change permissions failed exception
 */
- initWithPath: (OFString*)path
   permissions: (mode_t)permissions;

/*!
 * @brief Returns the path of the item.
 *
 * @return The path of the item
 */
- (OFString*)path;

/*!
 * @brief Returns the new permissions for the item.
 *
 * @return The new permissions for the item
 */
- (mode_t)permissions;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
