/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
 * @class OFGetCurrentDirectoryFailedException
 *	  OFGetCurrentDirectoryFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that getting the current directory path
 *	  failed.
 */
@interface OFGetCurrentDirectoryFailedException: OFException
{
	int _errNo;
	OF_RESERVE_IVARS(OFGetCurrentDirectoryFailedException, 4)
}

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased get current directory path failed
 *	  exception.
 *
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased get current directory failed exception
 */
+ (instancetype)exceptionWithErrNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated get current directory path failed
 *	  exception.
 *
 * @param errNo The errno of the error that occurred
 * @return An initialized get current directory path failed exception
 */
- (instancetype)initWithErrNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
