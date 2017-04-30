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

/*!
 * @class OFRemoveItemFailedException \
 *	  OFRemoveItemFailedException.h ObjFW/OFRemoveItemFailedException.h
 *
 * @brief An exception indicating that removing an item failed.
 */
@interface OFRemoveItemFailedException: OFException
{
	OFString *_path;
	int _errNo;
}

/*!
 * The path of the item which could not be removed.
 */
@property (readonly, nonatomic) OFString *path;

/*!
 * The errno of the error that occurred.
 */
@property (readonly) int errNo;

/*!
 * @brief Creates a new, autoreleased remove failed exception.
 *
 * @param path The path of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased remove item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString*)path
			    errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated remove failed exception.
 *
 * @param path The path of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return An initialized remove item failed exception
 */
- initWithPath: (OFString*)path
	 errNo: (int)errNo;
@end
