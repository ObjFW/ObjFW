/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFSequencedPacketSocket.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFSPXSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when the socket connected.
 *
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFSPXSocketAsyncConnectBlock)(id _Nullable exception);
#endif

/**
 * @protocol OFSPXSocketDelegate OFSPXSocket.h ObjFW/OFSPXSocket.h
 *
 * A delegate for OFSPXSocket.
 */
@protocol OFSPXSocketDelegate <OFSequencedPacketSocketDelegate>
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
-	 (void)socket: (OFSPXSocket *)socket
  didConnectToNetwork: (uint32_t)network
		 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
		 port: (uint16_t)port
	    exception: (nullable id)exception;
@end

/**
 * @class OFSPXSocket OFSPXSocket.h ObjFW/OFSPXSocket.h
 *
 * @brief A class which provides methods to create and use SPX sockets.
 *
 * @note If you want to use SPX in streaming mode instead of in message mode,
 *	 use @ref OFSPXStreamSocket instead.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFSPXSocket: OFSequencedPacketSocket
{
	OF_RESERVE_IVARS(OFSPXSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFSPXSocketDelegate> delegate;

/**
 * @brief Connect the OFSPXSocket to the specified destination.
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
 * @brief Asynchronously connect the OFSPXSocket to the specified destination.
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
 * @brief Asynchronously connect the OFSPXSocket to the specified destination.
 *
 * @param network The network on which the node to connect to is
 * @param node The node to connect to
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 */
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
			 port: (uint16_t)port
		  runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously connect the OFSPXSocket to the specified destination.
 *
 * @param node The node to connect to
 * @param network The network on which the node to connect to is
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
			 port: (uint16_t)port
			block: (OFSPXSocketAsyncConnectBlock)block;

/**
 * @brief Asynchronously connect the OFSPXSocket to the specified destination.
 *
 * @param node The node to connect to
 * @param network The network on which the node to connect to is
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
			 port: (uint16_t)port
		  runLoopMode: (OFRunLoopMode)runLoopMode
			block: (OFSPXSocketAsyncConnectBlock)block;
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
