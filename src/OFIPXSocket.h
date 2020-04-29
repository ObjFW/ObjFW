/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

/*!
 * @protocol OFIPXSocketDelegate OFIPXSocket.h ObjFW/OFIPXSocket.h
 *
 * @brief A delegate for OFIPXSocket.
 */
@protocol OFIPXSocketDelegate <OFDatagramSocketDelegate>
@end

/*!
 * @class OFIPXSocket OFIPXSocket.h ObjFW/OFIPXSocket.h
 *
 * @brief A class which provides methods to create and use IPX sockets.
 *
 * Addresses are of type @ref of_socket_address_t. You can use
 * @ref of_socket_address_ipx to create an address or
 * @ref of_socket_address_ipx_get to get the IPX network, node and port
 * (somtimes also called socket number).
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
	OF_RESERVE_IVARS(4)
}

/*!
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFIPXSocketDelegate> delegate;

/*!
 * @brief Bind the socket to the specified network, node and port with the
 *	  specified packet type.
 *
 * @param port The port (sometimes called socket number) to bind to. 0 means to
 *	       pick one and return it.
 * @param packetType The packet type to use on the socket
 * @return The address on which this socket can be reached
 */
- (of_socket_address_t)bindToPort: (uint16_t)port
		       packetType: (uint8_t)packetType;
@end

OF_ASSUME_NONNULL_END
