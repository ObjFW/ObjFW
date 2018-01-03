/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

@class OFURL;

/*!
 * @class OFRemoveItemFailedException \
 *	  OFRemoveItemFailedException.h ObjFW/OFRemoveItemFailedException.h
 *
 * @brief An exception indicating that removing an item failed.
 */
@interface OFRemoveItemFailedException: OFException
{
	OFURL *_URL;
	int _errNo;
}

/*!
 * @brief The URL of the item which could not be removed.
 */
@property (readonly, nonatomic) OFURL *URL;

/*!
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased remove failed exception.
 *
 * @param URL The URL of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased remove item failed exception
 */
+ (instancetype)exceptionWithURL: (OFURL *)URL
			   errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated remove failed exception.
 *
 * @param URL The URL of the item which could not be removed
 * @param errNo The errno of the error that occurred
 * @return An initialized remove item failed exception
 */
- (instancetype)initWithURL: (OFURL *)URL
		      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
