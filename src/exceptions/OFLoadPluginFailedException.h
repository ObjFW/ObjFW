/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
 * @class OFLoadPluginFailedException \
 *	  OFLoadPluginFailedException.h ObjFW/OFLoadPluginFailedException.h
 *
 * @brief An exception indicating a plugin could not be loaded.
 */
@interface OFLoadPluginFailedException: OFException
{
	OFString *_path, *_Nullable _error;
}

/*!
 * @brief The path of the plugin which could not be loaded
 */
@property (readonly, nonatomic) OFString *path;

/*!
 * @brief The error why the plugin could not be loaded, as a string
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *error;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased load plugin failed exception.
 *
 * @param path The path of the plugin which could not be loaded
 * @param error The error why the plugin could not be loaded, as a string
 * @return A new, autoreleased load plugin failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			    error: (nullable OFString *)error;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated load plugin failed exception.
 *
 * @param path The path of the plugin which could not be loaded
 * @param error The error why the plugin could not be loaded, as a string
 * @return An initialized load plugin failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		       error: (nullable OFString *)error
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
