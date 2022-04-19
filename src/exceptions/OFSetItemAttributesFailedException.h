/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
#import "OFURLHandler.h"

OF_ASSUME_NONNULL_BEGIN

@class OFURL;

/**
 * @class OFSetItemAttributesFailedException \
 *	  OFSetItemAttributesFailedException.h \
 *	  ObjFW/OFSetItemAttributesFailedException.h
 *
 * @brief An exception indicating an item's attributes could not be set.
 */
@interface OFSetItemAttributesFailedException: OFException
{
	OFURL *_URL;
	OFFileAttributes _attributes;
	OFFileAttributeKey _failedAttribute;
	int _errNo;
}

/**
 * @brief The URL of the item whose attributes could not be set.
 */
@property (readonly, nonatomic) OFURL *URL;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief The attributes that should have been set.
 */
@property (readonly, nonatomic) OFFileAttributes attributes;

/**
 * @brief The first attribute that could not be set.
 */
@property (readonly, nonatomic) OFFileAttributeKey failedAttribute;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased set item attributes failed exception.
 *
 * @param URL The URL of the item whose attributes could not be set
 * @param attributes The attributes that should have been set for the specified
 *		     item.
 * @param failedAttribute The first attribute that could not be set
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased set item attributes failed exception
 */
+ (instancetype)exceptionWithURL: (OFURL *)URL
		      attributes: (OFFileAttributes)attributes
		 failedAttribute: (OFFileAttributeKey)failedAttribute
			   errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated set item attributes failed exception.
 *
 * @param URL The URL of the item whose attributes could not be set
 * @param attributes The attributes that should have been set for the specified
 *		     item.
 * @param failedAttribute The first attribute that could not be set
 * @param errNo The errno of the error that occurred
 * @return An initialized set item attributes failed exception
 */
- (instancetype)initWithURL: (OFURL *)URL
		 attributes: (OFFileAttributes)attributes
	    failedAttribute: (OFFileAttributeKey)failedAttribute
		      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
