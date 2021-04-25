/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

/** @file */

@class OFTCPSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when the socket connected.
 *
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFTCPSocketAsyncConnectBlock)(id _Nullable exception);
#endif

/**
 * @protocol OFTCPSocketDelegate OFTCPSocket.h ObjFW/OFTCPSocket.h
 *
 * A delegate for OFTCPSocket.
 */
@protocol OFTCPSocketDelegate <OFStreamSocketDelegate>
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
-     (void)socket: (OFTCPSocket *)socket
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (nullable id)exception;
@end

/**
 * @class OFTCPSocket OFTCPSocket.h ObjFW/OFTCPSocket.h
 *
 * @brief A class which provides methods to create and use TCP sockets.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFTCPSocket: OFStreamSocket
{
	OFString *_Nullable _SOCKS5Host;
	uint16_t _SOCKS5Port;
#ifdef OF_WII
	uint16_t _port;
#endif
	OF_RESERVE_IVARS(OFTCPSocket, 4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, nullable, copy, nonatomic) OFString *SOCKS5Host;
@property (class, nonatomic) uint16_t SOCKS5Port;
#endif

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
/**
 * @brief Whether the socket sends keep alives for the connection.
 *
 * @warning This is not available on the Wii or Nintendo 3DS!
 */
@property (nonatomic) bool sendsKeepAlives;
#endif

#ifndef OF_WII
/**
 * @brief Whether sending segments can be delayed. Setting this to NO sets
 *        TCP_NODELAY on the socket.
 *
 * @warning This is not available on the Wii!
 */
@property (nonatomic) bool canDelaySendingSegments;
#endif

/**
 * @brief The host to use as a SOCKS5 proxy.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *SOCKS5Host;

/**
 * @brief The port to use on the SOCKS5 proxy.
 */
@property (nonatomic) uint16_t SOCKS5Port;

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFTCPSocketDelegate> delegate;

/**
 * @brief Sets the global SOCKS5 proxy host to use when creating a new socket
 *
 * @param SOCKS5Host The host to use as a SOCKS5 proxy when creating a new
 *		     socket
 */
+ (void)setSOCKS5Host: (nullable OFString *)SOCKS5Host;

/**
 * @brief Returns the host to use as a SOCKS5 proxy when creating a new socket
 *
 * @return The host to use as a SOCKS5 proxy when creating a new socket
 */
+ (nullable OFString *)SOCKS5Host;

/**
 * @brief Sets the global SOCKS5 proxy port to use when creating a new socket
 *
 * @param SOCKS5Port The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (void)setSOCKS5Port: (uint16_t)SOCKS5Port;

/**
 * @brief Returns the port to use as a SOCKS5 proxy when creating a new socket
 *
 * @return The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (uint16_t)SOCKS5Port;

/**
 * @brief Connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 */
- (void)connectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 */
- (void)asyncConnectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
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
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (OFTCPSocketAsyncConnectBlock)block;

/**
 * @brief Asynchronously connect the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFTCPSocketAsyncConnectBlock)block;
#endif

/**
 * @brief Bind the socket to the specified host and port.
 *
 * @param host The host to bind to. Use `@"0.0.0.0"` for IPv4 or `@"::"` for
 *	       IPv6 to bind to all.
 * @param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * @return The port the socket was bound to
 */
- (uint16_t)bindToHost: (OFString *)host port: (uint16_t)port;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern Class _Nullable OFTLSSocketClass;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
