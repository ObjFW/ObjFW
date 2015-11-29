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

#import "OFException.h"

#ifdef OF_HAVE_CHOWN
/*!
 * @class OFChangeOwnerFailedException \
 *	  OFChangeOwnerFailedException.h ObjFW/OFChangeOwnerFailedException.h
 *
 * @brief An exception indicating that changing the owner of an item failed.
 */
@interface OFChangeOwnerFailedException: OFException
{
	OFString *_path, *_owner, *_group;
	int _errNo;
}

/*!
 * The path of the item.
 */
@property (readonly, copy) OFString *path;

/*!
 * The new owner for the item.
 */
@property (readonly, copy) OFString *owner;

/*!
 * The new group for the item.
 */
@property (readonly, copy) OFString *group;

/*!
 * The errno of the error that occurred.
 */
@property (readonly) int errNo;

/*!
 * @brief Creates a new, autoreleased change owner failed exception.
 *
 * @param path The path of the item
 * @param owner The new owner for the item
 * @param group The new group for the item
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased change owner failed exception
 */
+ (instancetype)exceptionWithPath: (OFString*)path
			    owner: (OFString*)owner
			    group: (OFString*)group
			    errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated change owner failed exception.
 *
 * @param path The path of the item
 * @param owner The new owner for the item
 * @param group The new group for the item
 * @param errNo The errno of the error that occurred
 * @return An initialized change owner failed exception
 */
- initWithPath: (OFString*)path
	 owner: (OFString*)owner
	 group: (OFString*)group
	 errNo: (int)errNo;
@end
#endif
