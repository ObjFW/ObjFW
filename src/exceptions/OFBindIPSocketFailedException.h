/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFBindSocketFailedException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBindIPSocketFailedException \
 *	  OFBindIPSocketFailedException.h ObjFW/OFBindIPSocketFailedException.h
 *
 * @brief An exception indicating that binding an IP socket failed.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFBindIPSocketFailedException: OFBindSocketFailedException
{
	OFString *_Nullable _host;
	uint16_t _port;
}

/**
 * @brief The host on which binding failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *host;

/**
 * @brief The port on which binding failed.
 */
@property (readonly, nonatomic) uint16_t port;

/**
 * @brief Creates a new, autoreleased bind IP socket failed exception.
 *
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind IP socket failed exception
 */
+ (instancetype)exceptionWithHost: (OFString *)host
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind IP socket failed exception.
 *
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind IP socket failed exception
 */
- (instancetype)initWithHost: (OFString *)host
			port: (uint16_t)port
		      socket: (id)socket
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
