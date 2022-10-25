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

#import "OFBindSocketFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBindDDPSocketFailedException \
 *	  OFBindDDPSocketFailedException.h \
 *	  ObjFW/OFBindDDPSocketFailedException.h
 *
 * @brief An exception indicating that binding a DDP socket failed.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFBindDDPSocketFailedException: OFBindSocketFailedException
{
	uint16_t _network;
	uint8_t _port;
}

/**
 * @brief The DDP network on which binding failed.
 */
@property (readonly, nonatomic) uint16_t network;

/**
 * @brief The DDP port on which binding failed.
 */
@property (readonly, nonatomic) uint8_t port;

/**
 * @brief Creates a new, autoreleased bind DDP socket failed exception.
 *
 * @param network The DDP network on which binding failed
 * @param port The DDP port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind DDP socket failed exception
 */
+ (instancetype)exceptionWithNetwork: (uint16_t)network
				port: (uint8_t)port
			      socket: (id)socket
			       errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind DDP socket failed exception.
 *
 * @param network The DDP network on which binding failed
 * @param port The DDP port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind DDP socket failed exception
 */
- (instancetype)initWithNetwork: (uint16_t)network
			   port: (uint8_t)port
			 socket: (id)socket
			  errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
