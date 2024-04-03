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

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFListenOnSocketFailedException \
 *	  OFListenOnSocketFailedException.h \
 *	  ObjFW/OFListenOnSocketFailedException.h
 *
 * @brief An exception indicating that listening on the socket failed.
 */
@interface OFListenOnSocketFailedException: OFException
{
	id _socket;
	int _backlog, _errNo;
	OF_RESERVE_IVARS(OFListenOnSocketFailedException, 4)
}

/**
 * @brief The socket which failed to listen.
 */
@property (readonly, nonatomic) id socket;

/**
 * @brief The requested back log.
 */
@property (readonly, nonatomic) int backlog;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased listen failed exception.
 *
 * @param socket The socket which failed to listen
 * @param backlog The requested size of the back log
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased listen failed exception
 */
+ (instancetype)exceptionWithSocket: (id)socket
			    backlog: (int)backlog
			      errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated listen failed exception.
 *
 * @param socket The socket which failed to listen
 * @param backlog The requested size of the back log
 * @param errNo The errno of the error that occurred
 * @return An initialized listen failed exception
 */
- (instancetype)initWithSocket: (id)socket
		       backlog: (int)backlog
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
