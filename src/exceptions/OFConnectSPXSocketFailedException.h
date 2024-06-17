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
 * @class OFConnectSPXSocketFailedException OFConnectSPXSocketFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that an SPX connection could not be
 *	  established.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFConnectSPXSocketFailedException: OFConnectSocketFailedException
{
	uint32_t _network;
	unsigned char _node[IPX_NODE_LEN];
	uint16_t _port;
}


/**
 * @brief The IPX network of the node to which the connection failed.
 */
@property (readonly, nonatomic) uint32_t network;

/**
 * @brief The IPX port on the host to which the connection failed.
 */
@property (readonly, nonatomic) uint16_t port;

/**
 * @brief Creates a new, autoreleased connect SPX socket failed exception.
 *
 * @param network The IPX network of the node to which the connection failed
 * @param node The node to which the connection failed
 * @param port The port on the node to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connect SPX socket failed exception
 */
+ (instancetype)
    exceptionWithNetwork: (uint32_t)network
		    node: (const unsigned char [_Nullable IPX_NODE_LEN])node
		    port: (uint16_t)port
		  socket: (id)socket
		   errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated connect SPX socket failed exception.
 *
 * @param network The IPX network of the node to which the connection failed
 * @param node The node to which the connection failed
 * @param port The port on the node to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connect SPX socket failed exception
 */
- (instancetype)
    initWithNetwork: (uint32_t)network
	       node: (const unsigned char [_Nullable IPX_NODE_LEN])node
	       port: (uint16_t)port
	     socket: (id)socket
	      errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Get the IPX node to which the connection failed.
 *
 * @param node A pointer to where to write the node to
 */
- (void)getNode: (unsigned char [_Nonnull IPX_NODE_LEN])node;
@end

OF_ASSUME_NONNULL_END
