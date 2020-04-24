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

#import "OFIPStreamSocket.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @protocol OFTCPSocketDelegate OFTCPSocket.h ObjFW/OFTCPSocket.h
 *
 * A delegate for OFIPStreamSocket.
 */
@protocol OFTCPSocketDelegate <OFIPStreamSocketDelegate>
@end

/*!
 * @class OFTCPSocket OFTCPSocket.h ObjFW/OFTCPSocket.h
 *
 * @brief A class which provides methods to create and use TCP sockets.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFTCPSocket: OFIPStreamSocket
{
	OFString *_Nullable _SOCKS5Host;
	uint16_t _SOCKS5Port;
	OF_RESERVE_IVARS(4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, nullable, copy, nonatomic) OFString *SOCKS5Host;
@property (class, nonatomic) uint16_t SOCKS5Port;
#endif

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
/*!
 * @brief Whether keep alives are enabled for the connection.
 *
 * @warning This is not available on the Wii or Nintendo 3DS!
 */
@property (nonatomic, getter=isKeepAliveEnabled) bool keepAliveEnabled;
#endif

#ifndef OF_WII
/*!
 * @brief Whether TCP_NODELAY is enabled for the connection
 *
 * @warning This is not available on the Wii!
 */
@property (nonatomic, getter=isNoDelayEnabled) bool noDelayEnabled;
#endif

/*!
 * @brief The host to use as a SOCKS5 proxy.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *SOCKS5Host;

/*!
 * @brief The port to use on the SOCKS5 proxy.
 */
@property (nonatomic) uint16_t SOCKS5Port;

/*!
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still outstanding.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFTCPSocketDelegate> delegate;

/*!
 * @brief Sets the global SOCKS5 proxy host to use when creating a new socket
 *
 * @param SOCKS5Host The host to use as a SOCKS5 proxy when creating a new
 *		     socket
 */
+ (void)setSOCKS5Host: (nullable OFString *)SOCKS5Host;

/*!
 * @brief Returns the host to use as a SOCKS5 proxy when creating a new socket
 *
 * @return The host to use as a SOCKS5 proxy when creating a new socket
 */
+ (nullable OFString *)SOCKS5Host;

/*!
 * @brief Sets the global SOCKS5 proxy port to use when creating a new socket
 *
 * @param SOCKS5Port The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (void)setSOCKS5Port: (uint16_t)SOCKS5Port;

/*!
 * @brief Returns the port to use as a SOCKS5 proxy when creating a new socket
 *
 * @return The port to use as a SOCKS5 proxy when creating a new socket
 */
+ (uint16_t)SOCKS5Port;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern Class _Nullable of_tls_socket_class;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
