/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

OF_ASSUME_NONNULL_BEGIN

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
	uint16_t _permissions;
	int _errNo;
}

/*!
 * The path of the item.
 */
@property (readonly, nonatomic) OFString *path;

/*!
 * The new permissions for the item.
 */
@property (readonly, nonatomic) uint16_t permissions;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased change permissions failed exception.
 *
 * @param path The path of the item
 * @param permissions The new permissions for the item
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased change permissions failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
		      permissions: (uint16_t)permissions
			    errNo: (int)errNo;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated change permissions failed exception.
 *
 * @param path The path of the item
 * @param permissions The new permissions for the item
 * @param errNo The errno of the error that occurred
 * @return An initialized change permissions failed exception
 */
- initWithPath: (OFString *)path
   permissions: (uint16_t)permissions
	 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
