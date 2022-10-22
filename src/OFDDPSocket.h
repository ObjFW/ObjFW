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

#import "OFDatagramSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @protocol OFDDPSocketDelegate OFDDPSocket.h ObjFW/OFDDPSocket.h
 *
 * @brief A delegate for OFDDPSocket.
 */
@protocol OFDDPSocketDelegate <OFDatagramSocketDelegate>
@end

/**
 * @class OFDDPSocket OFDDPSocket.h ObjFW/OFDDPSocket.h
 *
 * @brief A class which provides methods to create and use AppleTalk DDP
 *	  sockets.
 *
 * Addresses are of type @ref OFSocketAddress. You can use
 * @ref OFSocketAddressMakeAppleTalk to create an address or
 * @ref OFSocketAddressAppleTalkNetwork to get the AppleTalk network,
 * @ref OFSocketAddressAppleTalkNode to get the AppleTalk node and
 * @ref OFSocketAddressPort to get the port (sometimes also called
 * socket number).
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
 * @brief Bind the socket to the specified network, node and port with the
 *	  specified packet type.
 *
 * @param port The port to bind to. 0 means to pick one and return it via the
 *	       returned socket address.
 * @return The address on which this socket can be reached
 * @throw OFBindDDPSockeFailedException Binding failed
 * @throw OFAlreadyConnectedException The socket is already bound
 */
- (OFSocketAddress)bindToNetwork: (uint16_t)network
			    node: (uint8_t)node
			    port: (uint8_t)port;
@end

OF_ASSUME_NONNULL_END
