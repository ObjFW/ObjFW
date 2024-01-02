/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @protocol OFUDPSocketDelegate OFUDPSocket.h ObjFW/OFUDPSocket.h
 *
 * @brief A delegate for OFUDPSocket.
 */
@protocol OFUDPSocketDelegate <OFDatagramSocketDelegate>
@end

/**
 * @class OFUDPSocket OFUDPSocket.h ObjFW/OFUDPSocket.h
 *
 * @brief A class which provides methods to create and use UDP sockets.
 *
 * Addresses are of type @ref OFSocketAddress. You can use the current thread's
 * @ref OFDNSResolver to create an address for a host / port pair,
 * @ref OFSocketAddressString to get the IP address string for an address and
 * @ref OFSocketAddressIPPort to get the port for an address. If you want to
 * compare two addresses, you can use
 * @ref OFSocketAddressEqual and you can use @ref OFSocketAddressHash to get a
 * hash to use in e.g. @ref OFMapTable.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the socket, but instead retains it.
 *	    This is so that the socket can be used as a key for a dictionary,
 *	    so context can be associated with a socket. Using a socket in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 */
@interface OFUDPSocket: OFDatagramSocket
{
#ifdef OF_WII
	uint16_t _port;
#endif
	OF_RESERVE_IVARS(OFUDPSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFUDPSocketDelegate> delegate;

/**
 * @brief Binds the socket to the specified host and port.
 *
 * @param host The host to bind to. Use `@"0.0.0.0"` for IPv4 or `@"::"` for
 *	       IPv6 to bind to all.
 * @param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * @return The address the socket was bound to
 * @throw OFBindIPSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already bound
 */
- (OFSocketAddress)bindToHost: (OFString *)host port: (uint16_t)port;
@end

OF_ASSUME_NONNULL_END
