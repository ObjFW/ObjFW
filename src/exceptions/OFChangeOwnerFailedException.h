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

#ifdef OF_HAVE_CHOWN
/*!
 * @brief An exception indicating that changing the owner of an item failed.
 */
@interface OFChangeOwnerFailedException: OFException
{
	OFString *_path, *_owner, *_group;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *path, *owner, *group;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased change owner failed exception.
 *
 * @param path The path of the item
 * @param owner The new owner for the item
 * @param group The new group for the item
 * @return A new, autoreleased change owner failed exception
 */
+ (instancetype)exceptionWithPath: (OFString*)path
			    owner: (OFString*)owner
			    group: (OFString*)group;

/*!
 * @brief Initializes an already allocated change owner failed exception.
 *
 * @param path The path of the item
 * @param owner The new owner for the item
 * @param group The new group for the item
 * @return An initialized change owner failed exception
 */
- initWithPath: (OFString*)path
	 owner: (OFString*)owner
	 group: (OFString*)group;

/*!
 * @brief Returns the path of the item.
 *
 * @return The path of the item
 */
- (OFString*)path;

/*!
 * @brief Returns the new owner for the item.
 *
 * @return The new owner for the item
 */
- (OFString*)owner;

/*!
 * @brief Returns the new group for the item.
 *
 * @return The new group for the item
 */
- (OFString*)group;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
#endif
