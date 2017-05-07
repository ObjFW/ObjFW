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
 * @class OFStatItemFailedException \
 *	  OFStatItemFailedException.h ObjFW/OFStatItemFailedException.h
 *
 * @brief An exception indicating an item's status could not be retrieved.
 */
@interface OFStatItemFailedException: OFException
{
	OFString *_path;
	int _errNo;
}

/*!
 * A string with the path of the item whose status could not be retrieved.
 */
@property (readonly, nonatomic) OFString *path;

/*!
 * The errno of the error that occurred.
 */
@property (readonly) int errNo;

/*!
 * @brief Creates a new, autoreleased stat item failed exception.
 *
 * @param path A string with the path of the item whose status could not be
 *	       retrieved
 * @return A new, autoreleased stat item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path;

/*!
 * @brief Creates a new, autoreleased stat item failed exception.
 *
 * @param path A string with the path of the item whose status could not be
 *	       retrieved
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased stat item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			    errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated stat item failed exception.
 *
 * @param path A string with the path of the item whose status could not be
 *	       retrieved
 * @return An initialized stat item failed exception
 */
- initWithPath: (OFString *)path;

/*!
 * @brief Initializes an already allocated stat item failed exception.
 *
 * @param path A string with the path of the item whose status could not be
 *	       retrieved
 * @param errNo The errno of the error that occurred
 * @return An initialized stat item failed exception
 */
- initWithPath: (OFString *)path
	 errNo: (int)errNo;
@end

OF_ASSUME_NONNULL_END
