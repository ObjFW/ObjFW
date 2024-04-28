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

#import "OFSequencedPacketSocket.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFSCTPSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when the socket connected.
 *
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFSCTPSocketAsyncConnectBlock)(id _Nullable exception);
#endif

/**
 * @protocol OFSCTPSocketDelegate OFSCTPSocket.h ObjFW/OFSCTPSocket.h
 *
 * A delegate for OFSCTPSocket.
 */
@protocol OFSCTPSocketDelegate <OFSequencedPacketSocketDelegate>
@optional
/**
 * @brief A method which is called when a socket connected.
 *
 * @param socket The socket which connected
 * @param host The host connected to
 * @param port The port on the host connected to
 * @param exception An exception that occurred while connecting, or nil on
 *		    success
 */
-     (void)socket: (OFSCTPSocket *)socket
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (nullable id)exception;
@end

/**
 * @class OFSCTPSocket OFSCTPSocket.h ObjFW/OFSCTPSocket.h
 *
 * @brief A class which provides methods to create and use SCTP sockets in
 *	  one-to-one mode.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFSCTPSocket: OFSequencedPacketSocket
{
	OF_RESERVE_IVARS(OFSCTPSocket, 4)
}

/**
 * @brief Whether sending packets can be delayed. Setting this to NO sets
 *        SCTP_NODELAY on the socket.
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool canDelaySendingPackets;

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFSCTPSocketDelegate> delegate;

/**
 * @brief Connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @throw OFConnectIPSocketFailedException Connecting failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)connectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 */
- (void)asyncConnectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (OFSCTPSocketAsyncConnectBlock)block;

/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFSCTPSocketAsyncConnectBlock)block;
#endif

/**
 * @brief Bind the socket to the specified host and port.
 *
 * @param host The host to bind to. Use `@"0.0.0.0"` for IPv4 or `@"::"` for
 *	       IPv6 to bind to all.
 * @param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * @return The address the socket was bound to
 * @throw OFBindIPSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (OFSocketAddress)bindToHost: (OFString *)host port: (uint16_t)port;
@end

OF_ASSUME_NONNULL_END
