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
 * @class OFChangeCurrentDirectoryFailedException \
 *	  OFChangeCurrentDirectoryFailedException.h \
 *	  ObjFW/OFChangeCurrentDirectoryFailedException.h
 *
 * @brief An exception indicating that changing the current directory path
 *	  failed.
 */
@interface OFChangeCurrentDirectoryFailedException: OFException
{
	OFString *_path;
	int _errNo;
	OF_RESERVE_IVARS(OFChangeCurrentDirectoryFailedException, 4)
}

/**
 * @brief The path of the directory to which the current path could not be
 *	  changed.
 */
@property (readonly, nonatomic) OFString *path;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased change current directory path failed
 *	  exception.
 *
 * @param path The path of the directory to which the current path could not be
 *	       changed
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased change current directory path failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated change directory failed exception.
 *
 * @param path The path of the directory to which the current path could not be
 *	       changed
 * @param errNo The errno of the error that occurred
 * @return An initialized change current directory path failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
