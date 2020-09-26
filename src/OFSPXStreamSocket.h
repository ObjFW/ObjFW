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

#import "OFStreamSocket.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFSPXStreamSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block which is called when the socket connected.
 *
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^of_spx_stream_socket_async_connect_block_t)(
    id _Nullable exception);
#endif

/*!
 * @protocol OFSPXStreamSocketDelegate OFSPXStreamSocket.h \
 *	     ObjFW/OFSPXStreamSocket.h
 *
 * A delegate for OFSPXStreamSocket.
 */
@protocol OFSPXStreamSocketDelegate <OFStreamSocketDelegate>
@optional
/*!
 * @brief A method which is called when a socket connected.
 *
 * @param socket The socket which connected
 * @param node The node the socket connected to
 * @param network The network of the node the socket connected to
 * @param port The port of the node to which the socket connected
 * @param exception An exception that occurred while connecting, or nil on
 *		    success
 */
-     (void)socket: (OFSPXStreamSocket *)socket
  didConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
	   network: (uint32_t)network
	      port: (uint16_t)port
	 exception: (nullable id)exception;
@end

/*!
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

/*!
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFSPXStreamSocketDelegate> delegate;

/*!
 * @brief Connect the OFSPXStreamSocket to the specified destination.
 *
 * @param node The node to connect to
 * @param network The network on which the node to connect to is
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 */
- (void)connectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
	      network: (uint32_t)network
		 port: (uint16_t)port;

/*!
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param node The node to connect to
 * @param network The network on which the node to connect to is
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 */
- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port;

/*!
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param node The node to connect to
 * @param network The network on which the node to connect to is
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 */
- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port
	       runLoopMode: (of_run_loop_mode_t)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param node The node to connect to
 * @param network The network on which the node to connect to is
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port
		     block: (of_spx_stream_socket_async_connect_block_t)block;

/*!
 * @brief Asynchronously connect the OFSPXStreamSocket to the specified
 *	  destination.
 *
 * @param node The node to connect to
 * @param network The network on which the node to connect to is
 * @param port The port (sometimes also called socket number) on the node to
 *	       connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port
	       runLoopMode: (of_run_loop_mode_t)runLoopMode
		     block: (of_spx_stream_socket_async_connect_block_t)block;
#endif

/*!
 * @brief Bind the socket to the specified network, node and port.
 *
 * @param port The port (sometimes called socket number) to bind to. 0 means to
 *	       pick one and return it.
 * @return The address on which this socket can be reached
 */
- (of_socket_address_t)bindToPort: (uint16_t)port;
@end

OF_ASSUME_NONNULL_END
