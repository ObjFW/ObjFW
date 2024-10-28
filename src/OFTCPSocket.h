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

@class OFTCPSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when the socket connected.
 *
 * @deprecated Use @ref OFTCPSocketConnectedHandler instead.
 *
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFTCPSocketAsyncConnectBlock)(id _Nullable exception)
    OF_DEPRECATED(ObjFW, 1, 2, "Use OFTCPSocketConnecetedHandler instead");

/**
 * @brief A handler which is called when the socket connected.
 *
 * @param socket The socket which connected
 * @param host The host connected to
 * @param port The port on the host connected to
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFTCPSocketConnectedHandler)(OFTCPSocket *socket,
    OFString *host, uint16_t port, id _Nullable exception);
#endif

/**
 * @protocol OFTCPSocketDelegate OFTCPSocket.h ObjFW/ObjFW.h
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
 * @class OFTCPSocket OFTCPSocket.h ObjFW/ObjFW.h
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
	uintptr_t _usesMPTCP;	/* Change to bool on ABI bump */
	OF_RESERVE_IVARS(OFTCPSocket, 3)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, nullable, copy, nonatomic) OFString *SOCKS5Host;
@property (class, nonatomic) uint16_t SOCKS5Port;
#endif

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
/**
 * @brief Whether the socket sends keep-alives for the connection.
 *
 * @warning This is not available on the Wii or Nintendo 3DS!
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool sendsKeepAlives;
#endif

#ifndef OF_WII
/**
 * @brief Whether sending segments can be delayed. Setting this to `false` sets
 *        TCP_NODELAY on the socket.
 *
 * @warning This is not available on the Wii!
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool canDelaySendingSegments;
#endif

/**
 * @brief Whether the socket uses MPTCP.
 *
 * If you want to use MPTCP, set this to true before connecting or binding.
 * After connecting or binding, this returns whether MPTCP was used.
 */
@property (nonatomic) bool usesMPTCP;

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
 * @brief Connects the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @throw OFConnectIPSocketFailedException Connecting failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)connectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connects the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 */
- (void)asyncConnectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connects the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      connect
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously connects the OFTCPSocket to the specified destination.
 *
 * @deprecated Use @ref asyncConnectToHost:port:handler: instead.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (OFTCPSocketAsyncConnectBlock)block
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use -[asyncConnectToHost:port:handler:] instead");

/**
 * @brief Asynchronously connects the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param handler The handler to call once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		   handler: (OFTCPSocketConnectedHandler)handler;

/**
 * @brief Asynchronously connects the OFTCPSocket to the specified destination.
 *
 * @deprecated Use @ref asyncConnectToHost:port:runLoopMode:handler: instead.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFTCPSocketAsyncConnectBlock)block
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use -[asyncConnectToHost:port:runLoopMode:handler:] instead");

/**
 * @brief Asynchronously connects the OFTCPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      connect
 * @param handler The handler to call once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		   handler: (OFTCPSocketConnectedHandler)handler;
#endif

/**
 * @brief Binds the socket to the specified host and port.
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
