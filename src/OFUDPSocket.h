/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFRunLoop.h"

#import "socket.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFUDPSocket;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block which is called when a packet has been received.
 *
 * @param socket The UDP socket which received a packet
 * @param buffer The buffer the packet has been written to
 * @param length The length of the packet
 * @param sender The address of the sender of the packet
 * @param exception An exception which occurred while receiving or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
typedef bool (^of_udp_socket_async_receive_block_t)(
    OFUDPSocket *_Nonnull socket, void *_Nonnull buffer, size_t length,
    const of_socket_address_t *_Nonnull sender, id _Nullable exception);

/*!
 * @brief A block which is called when a packet has been sent.
 *
 * @param socket The UDP socket which sent a packet
 * @param data The data which was sent
 * @param receiver The receiver for the UDP packet
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return The data to repeat the send with or nil if it should not repeat
 */
typedef OFData *_Nullable (^of_udp_socket_async_send_data_block_t)(
    OFUDPSocket *_Nonnull socket, OFData *_Nonnull data,
    const of_socket_address_t *_Nonnull receiver, id _Nullable exception);
#endif

/*!
 * @protocol OFUDPSocketDelegate OFUDPSocket.h ObjFW/OFUDPSocket.h
 *
 * @brief A delegate for OFUDPSocket.
 */
@protocol OFUDPSocketDelegate <OFObject>
@optional
/*!
 * @brief This method is called when a packet has been received.
 *
 * @param socket The UDP socket which received a packet
 * @param buffer The buffer the packet has been written to
 * @param length The length of the packet
 * @param sender The address of the sender of the packet
 * @param exception An exception that occurred while receiving, or nil on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
-	  (bool)socket: (OFUDPSocket *)socket
  didReceiveIntoBuffer: (void *)buffer
		length: (size_t)length
		sender: (const of_socket_address_t *_Nonnull)sender
	     exception: (nullable id)exception;

/*!
 * @brief This which is called when a packet has been sent.
 *
 * @param socket The UDP socket which sent a packet
 * @param data The data which was sent
 * @param receiver The receiver for the UDP packet
 * @param exception An exception that occurred while sending, or nil on success
 * @return The data to repeat the send with or nil if it should not repeat
 */
- (nullable OFData *)socket: (OFUDPSocket *)socket
		didSendData: (OFData *)data
		   receiver: (const of_socket_address_t *_Nonnull)receiver
		  exception: (nullable id)exception;
@end

/*!
 * @class OFUDPSocket OFUDPSocket.h ObjFW/OFUDPSocket.h
 *
 * @brief A class which provides methods to create and use UDP sockets.
 *
 * Addresses are of type @ref of_socket_address_t. You can use the current
 * thread's @ref OFDNSResolver to create an address for a host / port pair and
 * @ref of_socket_address_ip_string to get the IP string / port pair for an
 * address. If you want to compare two addresses, you can use @ref
 * of_socket_address_equal and you can use @ref of_socket_address_hash to get a
 * hash to use in e.g. @ref OFMapTable.
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
	bool _blocking;
	id _Nullable _delegate;
}

/*!
 * @brief Whether the socket is in blocking mode.
 *
 * By default, a socket is in blocking mode.
 */
@property (nonatomic, getter=isBlocking) bool blocking;

/*!
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still outstanding.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFUDPSocketDelegate> delegate;

/*!
 * @brief Returns a new, autoreleased OFUDPSocket.
 *
 * @return A new, autoreleased OFUDPSocket
 */
+ (instancetype)socket;

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
 * @param sender A pointer to an @ref of_socket_address_t, which will be set to
 *		 the address of the sender
 * @return The length of the received datagram
 */
- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (of_socket_address_t *)sender;

/*!
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length;

/*!
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the async receive
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (of_run_loop_mode_t)runLoopMode;

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

/*!
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the async receive
 * @param block The block to call when the datagram has been received. If the
 *		block returns true, it will be called again with the same
 *		buffer and maximum length when more datagrams have been
 *		received. If you want the next method in the queue to handle
 *		the datagram received next, you need to return false from the
 *		method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (of_run_loop_mode_t)runLoopMode
			 block: (of_udp_socket_async_receive_block_t)block;
#endif

/*!
 * @brief Sends the specified datagram to the specified address.
 *
 * @param buffer The buffer to send as a datagram
 * @param length The length of the buffer
 * @param receiver A pointer to an @ref of_socket_address_t to which the
 *		   datagram should be sent
 */
- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const of_socket_address_t *)receiver;

/*!
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref of_socket_address_t to which the
 *		   datagram should be sent. The receiver is copied.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver;

/*!
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref of_socket_address_t to which the
 *		   datagram should be sent. The receiver is copied.
 * @param runLoopMode The run loop mode in which to perform the async send
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver
	  runLoopMode: (of_run_loop_mode_t)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref of_socket_address_t to which the
 *		   datagram should be sent. The receiver is copied.
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver
		block: (of_udp_socket_async_send_data_block_t)block;

/*!
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref of_socket_address_t to which the
 *		   datagram should be sent. The receiver is copied.
 * @param runLoopMode The run loop mode in which to perform the async send
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver
	  runLoopMode: (of_run_loop_mode_t)runLoopMode
		block: (of_udp_socket_async_send_data_block_t)block;
#endif

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

OF_ASSUME_NONNULL_END
