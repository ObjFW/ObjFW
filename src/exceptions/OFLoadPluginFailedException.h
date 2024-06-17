/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFLoadPluginFailedException OFLoadPluginFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating a plugin could not be loaded.
 */
@interface OFLoadPluginFailedException: OFException
{
	OFString *_path, *_Nullable _error;
	OF_RESERVE_IVARS(OFLoadPluginFailedException, 4)
}

/**
 * @brief The path of the plugin which could not be loaded
 */
@property (readonly, nonatomic) OFString *path;

/**
 * @brief The error why the plugin could not be loaded, as a string
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *error;

/**
 * @brief Creates a new, autoreleased load plugin failed exception.
 *
 * @param path The path of the plugin which could not be loaded
 * @param error The error why the plugin could not be loaded, as a string
 * @return A new, autoreleased load plugin failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			    error: (nullable OFString *)error;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated load plugin failed exception.
 *
 * @param path The path of the plugin which could not be loaded
 * @param error The error why the plugin could not be loaded, as a string
 * @return An initialized load plugin failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		       error: (nullable OFString *)error
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
