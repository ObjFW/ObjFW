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
 * @ref OFSocketAddressIPXNode to get the IPX node and
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
 * @param port The port (sometimes called socket number) to bind to. 0 means to
 *	       pick one and return via the returned socket address.
 * @param packetType The packet type to use on the socket
 * @return The address on which this socket can be reached
 * @throw OFBindFailedException Binding failed
 * @throw OFAlreadyConnectedException The socket is already bound
 */
- (OFSocketAddress)bindToPort: (uint16_t)port packetType: (uint8_t)packetType;
@end

OF_ASSUME_NONNULL_END
