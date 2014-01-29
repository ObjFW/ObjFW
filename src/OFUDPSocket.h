/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFObject.h"
#import "OFKernelEventObserver.h"

#import "socket.h"

/*! @file */

/*!
 * @brief A struct which represents a host / port pair for a UDP socket.
 */
typedef struct {
	struct sockaddr_storage address;
	socklen_t length;
} of_udp_socket_address_t;

/*!
 * @brief A class which provides functions to create and use UDP sockets.
 *
 * Addresses are of type @ref of_udp_socket_address_t. You can use
 * @ref resolveAddressForHost:port:address: to create an address for a host /
 * port pair and @ref hostForAddress:port: to get the host / port pair for an
 * address. If you want to compare two addresses, you can use
 * @ref of_udp_socket_address_equal and you can use
 * @ref of_udp_socket_address_hash to get a hash to use in e.g. @ref OFMapTable.
 */
@interface OFUDPSocket: OFObject <OFReadyForReadingObserving,
    OFReadyForWritingObserving>
{
	int _socket;
}

/*!
 * @brief Returns a new, autoreleased OFUDPSocket.
 *
 * @return A new, autoreleased OFUDPSocket
 */
+ (instancetype)socket;

/*!
 * @brief Resolves the specified host and creates a host / port pair together
 *	  with the specified port.
 *
 * @param host The host to resolve
 * @param port The port for the resulting host / port pair
 * @param address A pointer to the address that should be filled with the
 *		  host / port pair
 */
+ (void)resolveAddressForHost: (OFString*)host
			 port: (uint16_t)port
		      address: (of_udp_socket_address_t*)address;

/*!
 * @brief Returns the host for the specified address and optionally the port.
 *
 * @param address The address for which the host and (optionally) the port
 *		  should be returned
 * @param port A pointer to an uint16_t. If it is not NULL, the port of the
 *	       host / port pair will be written to it.
 * @return The host of the host / port pair
 */
+ (OFString*)hostForAddress: (of_udp_socket_address_t*)address
		       port: (uint16_t*)port;

/*!
 * @brief Binds the socket to the specified host and port.
 *
 * @param host The host to bind to. Use `@"0.0.0.0"` for IPv4 or `@"::"` for
 *	       IPv6 to bind to all.
 * @param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * @return The port the socket was bound to
 */
- (uint16_t)bindToHost: (OFString*)host
		  port: (uint16_t)port;

/*!
 * @brief Receives a datagram and stores it into the specified buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param sender A pointer to an @ref of_udp_socket_address_t, which will be
 *		 set to the address of the sender
 * @return The length of the received datagram
 */
- (size_t)receiveIntoBuffer: (void*)buffer
		     length: (size_t)length
		     sender: (of_udp_socket_address_t*)sender;

/*!
 * @brief Sends the specified datagram to the specified address.
 *
 * @param buffer The buffer to send as a datagram
 * @param length The length of the buffer
 * @param receiver A pointer to an @ref of_udp_socket_address_t to which the
 *		   datagram should be sent
 */
- (void)sendBuffer: (const void*)buffer
	    length: (size_t)length
	  receiver: (of_udp_socket_address_t*)receiver;

/*!
 * @brief Closes the socket so that it can neither receive nor send any more
 *	  datagrams.
 */
- (void)close;
@end

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief Compares two of_udp_socket_address_t for equality.
 *
 * @param address1 The address to compare with the second address
 * @param address2 The second address
 * @return Whether the two addresses are equal
 */
extern bool of_udp_socket_address_equal(of_udp_socket_address_t *address1,
    of_udp_socket_address_t *address2);

/*!
 * @brief Returns the hash for the specified of_udp_socket_address_t.
 *
 * @param address The address to hash
 * @return The hash for the specified of_udp_socket_address_t
 */
extern uint32_t of_udp_socket_address_hash(of_udp_socket_address_t *address);
#ifdef __cplusplus
}
#endif
