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
	uint8_t _node, _port, _protocolType;
}

/**
 * @brief The DDP network on which binding failed.
 */
@property (readonly, nonatomic) uint16_t network;

/**
 * @brief The DDP node for which binding failed.
 */
@property (readonly, nonatomic) uint8_t node;

/**
 * @brief The DDP port on which binding failed.
 */
@property (readonly, nonatomic) uint8_t port;

/**
 * @brief The DDP protocol type for which binding failed.
 */
@property (readonly, nonatomic) uint8_t protocolType;

/**
 * @brief Creates a new, autoreleased bind DDP socket failed exception.
 *
 * @param network The DDP network on which binding failed
 * @param node The DDP node for which binding failed
 * @param port The DDP port on which binding failed
 * @param protocolType The DDP protocol type for which binding failed.
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind DDP socket failed exception
 */
+ (instancetype)exceptionWithNetwork: (uint16_t)network
				node: (uint8_t)node
				port: (uint8_t)port
			protocolType: (uint8_t)protocolType
			      socket: (id)socket
			       errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind DDP socket failed exception.
 *
 * @param network The DDP network on which binding failed
 * @param node The DDP node for which binding failed
 * @param port The DDP port on which binding failed
 * @param protocolType The DDP protocol type for which binding failed.
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind DDP socket failed exception
 */
- (instancetype)initWithNetwork: (uint16_t)network
			   node: (uint8_t)node
			   port: (uint8_t)port
		   protocolType: (uint8_t)protocolType
			 socket: (id)socket
			  errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
