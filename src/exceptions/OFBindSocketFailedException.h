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

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBindSocketFailedException \
 *	  OFBindSocketFailedException.h ObjFW/OFBindSocketFailedException.h
 *
 * @brief An exception indicating that binding a socket failed.
 */
@interface OFBindSocketFailedException: OFException
{
	id _socket;
	int _errNo;
	OF_RESERVE_IVARS(OFBindSocketFailedException, 4)
}

/**
 * @brief The socket which could not be bound.
 */
@property (readonly, nonatomic) id socket;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased bind socket failed exception.
 *
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind socket failed exception
 */
+ (instancetype)exceptionWithSocket: (id)socket errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind socket failed exception.
 *
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind socket failed exception
 */
- (instancetype)initWithSocket: (id)socket
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
