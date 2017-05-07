/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFUDPSocket;
@class OFException;

/*!
 * @struct of_udp_socket_address_t OFUDPSocket.h ObjFW/OFUDPSocket.h
 *
 * @brief A struct which represents a host / port pair for a UDP socket.
 */
typedef struct {
	struct sockaddr_storage address;
	socklen_t length;
} of_udp_socket_address_t;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block which is called when the host / port pair for the UDP socket
 *	  has been resolved.
 *
 * @param host The host that has been resolved
 * @param port The port of the host / port pair
 * @param address The address of the resolved host / port pair
 * @param exception An exception which occurred while resolving or `nil` on
 *		    success
 */
typedef void (^of_udp_socket_async_resolve_block_t)(OFString *host,
    uint16_t port, of_udp_socket_address_t address,
    OFException *_Nullable exception);

/*!
 * @brief A block which is called when a packet has been received.
 *
 * @param socket The UDP which received a packet
 * @param buffer The buffer the packet has been written to
 * @param length The length of the packet
 * @param sender The address of the sender of the packet
 * @param exception An exception which occurred while receiving or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
typedef bool (^of_udp_socket_async_receive_block_t)(OFUDPSocket *socket,
    void *buffer, size_t length, of_udp_socket_address_t sender,
    OFException *_Nullable exception);
#endif

/*!
 * @class OFUDPSocket OFUDPSocket.h ObjFW/OFUDPSocket.h
 *
 * @brief A class which provides methods to create and use UDP sockets.
 *
 * Addresses are of type @ref of_udp_socket_address_t. You can use
 * @ref resolveAddressForHost:port:address: to create an address for a host /
 * port pair and @ref getHost:andPort:forAddress: to get the host / port pair
 * for an address. If you want to compare two addresses, you can use
 * @ref of_udp_socket_address_equal and you can use
 * @ref of_udp_socket_address_hash to get a hash to use in e.g.
 * @ref OFMapTable.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the socket, but instead retains it.
 *	    This is so that the socket can be used as a key for a dictionary,
 *	    so context can be associated with a socket. Using a socket in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 */
@interface OFUDPSocket: OFObject <OFCopying, OFReadyForReadingObserving,
    OFReadyForWritingObserving>
{
	of_socket_t _socket;
#ifdef OF_WII
	uint16_t _port;
#endif
}

/*!
 * @brief Returns a new, autoreleased OFUDPSocket.
 *
 * @return A new, autoreleased OFUDPSocket
 */
+ (instancetype)socket;

/*!
 * @brief Resolves the specified host and creates a an address for the host /
 *	  port pair.
 *
 * @param host The host to resolve
 * @param port The port for the resulting address
 * @param address A pointer to the address that should be filled with the
 *		  host / port pair
 */
+ (void)resolveAddressForHost: (OFString *)host
			 port: (uint16_t)port
		      address: (of_udp_socket_address_t *)address;

#ifdef OF_HAVE_THREADS
/*!
 * @brief Asynchronously resolves the specified host and creates an address for
 *	  the host / port pair.
 *
 * @param host The host to resolve
 * @param port The port for the resulting address
 * @param target The target on which to call the selector once the host has been
 *		 resolved
 * @param selector The selector to call on the target. The signature must be
 *		   `void (OFString *host, uint16_t port,
 *		   of_udp_socket_address_t address, OFException *exception)`.
 */
+ (void)asyncResolveAddressForHost: (OFString *)host
			      port: (uint16_t)port
			    target: (id)target
			  selector: (SEL)selector;

# ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously resolves the specified host and creates an address for
 *	  the host / port pair.
 *
 * @param host The host to resolve
 * @param port The port for the resulting address
 * @param block The block to execute once the host has been resolved
 */
+ (void)asyncResolveAddressForHost: (OFString *)host
			      port: (uint16_t)port
			     block: (of_udp_socket_async_resolve_block_t)block;
# endif
#endif

/*!
 * @brief Gets the host and port for the specified address.
 *
 * @param host A pointer to an @ref OFString *. If it is not NULL, it will be
 *	       set to the host of the host / port pair.
 * @param port A pointer to an uint16_t. If it is not NULL, the port of the
 *	       host / port pair will be written to it.
 * @param address The address for which the host and port should be retrieved
 */
+ (void)getHost: (OFString *__autoreleasing _Nonnull *_Nullable)host
	andPort: (uint16_t *_Nullable)port
     forAddress: (of_udp_socket_address_t *)address;

/*!
 * @brief Binds the socket to the specified host and port.
 *
 * @param host The host to bind to. Use `@"0.0.0.0"` for IPv4 or `@"::"` for
 *	       IPv6 to bind to all.
 * @param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * @return The port the socket was bound to
 */
- (uint16_t)bindToHost: (OFString *)host
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
- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (of_udp_socket_address_t *)sender;

/*!
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param target The target on which the selector should be called when the
 *		 datagram has been received. If the method returns true, it
 *		 will be called again with the same buffer and maximum length
 *		 when more datagrams have been received. If you want the next
 *		 method in the queue to handle the datagram received next, you
 *		 need to return false from the method.
 * @param selector The selector to call on the target. The signature must be
 *		   `bool (OFUDPSocket *socket, void *buffer, size_t length,
 *		   of_udp_socket_address_t, OFException *exception)`.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			target: (id)target
		      selector: (SEL)selector;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param block The block to call when the datagram has been received. If the
 *		block returns true, it will be called again with the same
 *		buffer and maximum length when more datagrams have been
 *		received. If you want the next method in the queue to handle
 *		the datagram received next, you need to return false from the
 *		method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			 block: (of_udp_socket_async_receive_block_t)block;
#endif

/*!
 * @brief Sends the specified datagram to the specified address.
 *
 * @param buffer The buffer to send as a datagram
 * @param length The length of the buffer
 * @param receiver A pointer to an @ref of_udp_socket_address_t to which the
 *		   datagram should be sent
 */
- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const of_udp_socket_address_t *)receiver;

/*!
 * @brief Cancels all pending asynchronous requests on the socket.
 */
- (void)cancelAsyncRequests;

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

OF_ASSUME_NONNULL_END
