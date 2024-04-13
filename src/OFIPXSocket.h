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

#import "OFDatagramSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @protocol OFIPXSocketDelegate OFIPXSocket.h ObjFW/OFIPXSocket.h
 *
 * @brief A delegate for OFIPXSocket.
 */
@protocol OFIPXSocketDelegate <OFDatagramSocketDelegate>
@end

/**
 * @class OFIPXSocket OFIPXSocket.h ObjFW/OFIPXSocket.h
 *
 * @brief A class which provides methods to create and use IPX sockets.
 *
 * Addresses are of type @ref OFSocketAddress. You can use
 * @ref OFSocketAddressMakeIPX to create an address or
 * @ref OFSocketAddressIPXNetwork to get the IPX network,
 * @ref OFSocketAddressGetIPXNode to get the IPX node and
 * @ref OFSocketAddressIPXPort to get the port (sometimes also called
 * socket number).
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the socket, but instead retains it.
 *	    This is so that the socket can be used as a key for a dictionary,
 *	    so context can be associated with a socket. Using a socket in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 */
@interface OFIPXSocket: OFDatagramSocket
{
#ifndef OF_WINDOWS
	uint8_t _packetType;
#endif
	OF_RESERVE_IVARS(OFIPXSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFIPXSocketDelegate> delegate;

/**
 * @brief Bind the socket to the specified network, node and port with the
 *	  specified packet type.
 *
 * @param network The IPX network to bind to. 0 means the current network.
 * @param node The IPX network to bind to. An all zero node means the
 *	       computer's node.
 * @param port The port (sometimes called socket number) to bind to. 0 means to
 *	       pick one and return via the returned socket address.
 * @param packetType The packet type to use on the socket
 * @return The address on which this socket can be reached
 * @throw OFBindIPXSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already bound
 */
- (OFSocketAddress)
    bindToNetwork: (uint32_t)network
	     node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
	     port: (uint16_t)port
       packetType: (uint8_t)packetType;
@end

OF_ASSUME_NONNULL_END
