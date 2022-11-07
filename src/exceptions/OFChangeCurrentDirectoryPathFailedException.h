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

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFChangeCurrentDirectoryPathFailedException \
 *	  OFChangeCurrentDirectoryPathFailedException.h \
 *	  ObjFW/OFChangeCurrentDirectoryPathFailedException.h
 *
 * @brief An exception indicating that changing the current directory path
 *	  failed.
 */
@interface OFChangeCurrentDirectoryPathFailedException: OFException
{
	OFString *_path;
	int _errNo;
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
