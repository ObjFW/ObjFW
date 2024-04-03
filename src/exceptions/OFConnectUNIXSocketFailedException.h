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

#import "OFConnectSocketFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFConnectUNIXSocketFailedException \
 *	  OFConnectUNIXSocketFailedException.h \
 *	  ObjFW/OFConnectUNIXSocketFailedException.h
 *
 * @brief An exception indicating that a UNIX socket connection could not be
 *	  established.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFConnectUNIXSocketFailedException: OFConnectSocketFailedException
{
	OFString *_Nullable _path;
}

/**
 * @brief The path to which the connection failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief Creates a new, autoreleased connect UNIX socket failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connect UNIX socket failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)socket
			    errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated connect UNIX socket failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connect UNIX socket failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		      socket: (id)socket
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
