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

#import "OFBindSocketFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBindIPXSocketFailedException OFBindIPXSocketFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that binding an IPX socket failed.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFBindIPXSocketFailedException: OFBindSocketFailedException
{
	uint32_t _network;
	unsigned char _node[IPX_NODE_LEN];
	uint16_t _port;
	uint8_t _packetType;
}

/**
 * @brief The IPX network on which binding failed.
 */
@property (readonly, nonatomic) uint32_t network;

/**
 * @brief The IPX port on which binding failed.
 */
@property (readonly, nonatomic) uint16_t port;

/**
 * @brief The IPX packet type for which binding failed.
 */
@property (readonly, nonatomic) uint8_t packetType;

/**
 * @brief Creates a new, autoreleased bind IPX socket failed exception.
 *
 * @param network The IPX network to which binding failed
 * @param node The IPX node to which binding failed
 * @param port The IPX port to which binding failed
 * @param packetType The IPX packet type for which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind IPX socket failed exception
 */
+ (instancetype)
    exceptionWithNetwork: (uint32_t)network
		    node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
		    port: (uint16_t)port
	      packetType: (uint8_t)packetType
		  socket: (id)socket
		   errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind IPX socket failed exception.
 *
 * @param network The IPX network to which binding failed
 * @param node The IPX node to which binding failed
 * @param port The IPX port to which binding failed
 * @param packetType The IPX packet type for which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind IPX socket failed exception
 */
- (instancetype)
    initWithNetwork: (uint32_t)network
	       node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
	       port: (uint16_t)port
	 packetType: (uint8_t)packetType
	     socket: (id)socket
	      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Get the IPX node for which binding failed.
 *
 * @param node A pointer to where to write the node to
 */
- (void)getNode: (unsigned char [_Nonnull IPX_NODE_LEN])node;
@end

OF_ASSUME_NONNULL_END
