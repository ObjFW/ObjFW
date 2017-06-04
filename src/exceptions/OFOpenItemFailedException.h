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
 * @class OFOpenItemFailedException \
 *	  OFOpenItemFailedException.h ObjFW/OFOpenItemFailedException.h
 *
 * @brief An exception indicating an item could not be opened.
 */
@interface OFOpenItemFailedException: OFException
{
	OFString *_path, *_mode;
	int _errNo;
}

/*!
 * The path of the item which could not be opened.
 */
@property (readonly, nonatomic) OFString *path;

/*!
 * The mode in which the item should have been opened.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *mode;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param path A string with the path of the item tried to open
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path;

/*!
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param path A string with the path of the item tried to open
 * @param mode A string with the mode in which the item should have been opened
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			     mode: (nullable OFString *)mode;

/*!
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param path A string with the path of the item tried to open
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			    errNo: (int)errNo;

/*!
 * @brief Creates a new, autoreleased open item failed exception.
 *
 * @param path A string with the path of the item tried to open
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased open item failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			     mode: (nullable OFString *)mode
			    errNo: (int)errNo;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param path A string with the path of the item which could not be opened
 * @return An initialized open item failed exception
 */
- initWithPath: (OFString *)path;

/*!
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param path A string with the path of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @return An initialized open item failed exception
 */
- initWithPath: (OFString *)path
	  mode: (nullable OFString *)mode;

/*!
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param path A string with the path of the item which could not be opened
 * @param errNo The errno of the error that occurred
 * @return An initialized open item failed exception
 */
- initWithPath: (OFString *)path
	 errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated open item failed exception.
 *
 * @param path A string with the path of the item which could not be opened
 * @param mode A string with the mode in which the item should have been opened
 * @param errNo The errno of the error that occurred
 * @return An initialized open item failed exception
 */
- initWithPath: (OFString *)path
	  mode: (nullable OFString *)mode
	 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
