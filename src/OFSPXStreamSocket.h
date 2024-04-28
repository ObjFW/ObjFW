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

#import "OFStreamSocket.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFSPXStreamSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when the socket connected.
 *
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFSPXStreamSocketAsyncConnectBlock)(id _Nullable exception);
#endif

/**
 * @protocol OFSPXStreamSocketDelegate OFSPXStreamSocket.h \
 *	     ObjFW/OFSPXStreamSocket.h
 *
 * A delegate for OFSPXStreamSocket.
 */
@protocol OFSPXStreamSocketDelegate <OFStreamSocketDelegate>
@optional
/**
 * @brief A method which is called when a socket connected.
 *
 * @param socket The socket which connected
 * @param network The network of the node the socket connected to
 * @param node The node the socket connected to
 * @param port The port of the node to which the socket connected
 * @param exception An exception that occurred while connecting, or nil on
 *		    success
 */
-	 (void)socket: (OFSPXStreamSocket *)socket
  didConnectToNetwork: (uint32_t)network
		 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
		 port: (uint16_t)port
	    exception: (nullable id)exception;
@end

/**
 * @class OFSPXStreamSocket OFSPXStreamSocket.h ObjFW/OFSPXStreamSocket.h
 *
 * @brief A class which provides methods to create and use SPX stream sockets.
 *
 * @note If you want to use SPX in message mode instead of in streaming mode,
 *	 use @ref OFSPXSocket instead.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFSPXStreamSocket: OFStreamSocket
{
	OF_RESERVE_IVARS(OFSPXStreamSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFSPXStreamSocketDelegate> delegate;

/**
 * @brief Connect the OFSPXStreamSocket to the specified destination.
 *
 * @param network The network on which the node to connect to is
 * @param node The node to connect to
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @throw OFConnectSPXSocketFailedException Connecting failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)connectToNetwork: (uint32_t)network
		    node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
		    port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param network The network on which the node to connect to is
 * @param node The node to connect to
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 */
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
			 port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param network The network on which the node to connect to is
 * @param node The node to connect to
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      connect
 */
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
			 port: (uint16_t)port
		  runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param network The network on which the node to connect to is
 * @param node The node to connect to
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
			 port: (uint16_t)port
			block: (OFSPXStreamSocketAsyncConnectBlock)block;

/**
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param network The network on which the node to connect to is
 * @param node The node to connect to
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
			 port: (uint16_t)port
		  runLoopMode: (OFRunLoopMode)runLoopMode
			block: (OFSPXStreamSocketAsyncConnectBlock)block;
#endif

/**
 * @brief Bind the socket to the specified network, node and port.
 *
 * @param network The IPX network to bind to. 0 means the current network.
 * @param node The IPX network to bind to. An all zero node means the
 *	       computer's node.
 * @param port The port (sometimes called socket number) to bind to. 0 means to
 *	       pick one and return via the returned socket address.
 * @return The address on which this socket can be reached
 * @throw OFBindIPXSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (OFSocketAddress)
    bindToNetwork: (uint32_t)network
	     node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
	     port: (uint16_t)port;
@end

OF_ASSUME_NONNULL_END
