/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFAcceptSocketFailedException OFAcceptSocketFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that accepting a connection failed.
 */
@interface OFAcceptSocketFailedException: OFException
{
	id _socket;
	int _errNo;
	OF_RESERVE_IVARS(OFAcceptSocketFailedException, 4)
}

/**
 * @brief The socket which could not accept a connection.
 */
@property (readonly, nonatomic) id socket;

/**
 * @brief The errno from when the exception was created.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @param errNo The errno for the error
 * @return A new, autoreleased accept failed exception
 */
+ (instancetype)exceptionWithSocket: (id)socket errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @param errNo The errno for the error
 * @return An initialized accept failed exception
 */
- (instancetype)initWithSocket: (id)socket
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
