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

#import "OFDatagramSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/**
 * @protocol OFDDPSocketDelegate OFDDPSocket.h ObjFW/ObjFW.h
 *
 * @brief A delegate for OFDDPSocket.
 */
@protocol OFDDPSocketDelegate <OFDatagramSocketDelegate>
@end

/**
 * @class OFDDPSocket OFDDPSocket.h ObjFW/ObjFW.h
 *
 * @brief A class which provides methods to create and use AppleTalk DDP
 *	  sockets.
 *
 * Addresses are of type @ref OFSocketAddress. You can use
 * @ref OFSocketAddressMakeAppleTalk to create an address or
 * @ref OFSocketAddressAppleTalkNetwork to get the AppleTalk network,
 * @ref OFSocketAddressAppleTalkNode to get the AppleTalk node and
 * @ref OFSocketAddressAppleTalkPort to get the port (sometimes also called
 * socket number).
 *
 * @note On some systems, packets received with the wrong protocol type just
 *	 get filtered by the kernel, however, on other systems, the packet is
 *	 queued up and will raise an @ref OFReadFailedException with the
 *	 @ref OFReadFailedException#errNo set to `ENOMSG` when being received.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the socket, but instead retains it.
 *	    This is so that the socket can be used as a key for a dictionary,
 *	    so context can be associated with a socket. Using a socket in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 */
@interface OFDDPSocket: OFDatagramSocket
{
#if !defined(OF_MACOS) && !defined(OF_WINDOWS)
	uint8_t _protocolType;
#endif
	OF_RESERVE_IVARS(OFDDPSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFDDPSocketDelegate> delegate;

/**
 * @brief Bind the socket to the specified network, node and port.
 *
 * @param network The network to bind to. 0 means any.
 * @param node The node to bind to. 0 means "this node".
 * @param port The port to bind to. 0 means to pick one and return it via the
 *	       returned socket address.
 * @param protocolType The DDP protocol type to use. Must not be 0. If you want
 *		       to use DDP directly and not a protocol built on top of
 *		       it, use 11 for compatibility with Open Transport.
 * @return The address on which this socket can be reached
 * @throw OFBindDDPSockeFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already bound
 */
- (OFSocketAddress)bindToNetwork: (uint16_t)network
			    node: (uint8_t)node
			    port: (uint8_t)port
		    protocolType: (uint8_t)protocolType;
@end

OF_ASSUME_NONNULL_END
