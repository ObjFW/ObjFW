/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFConnectionFailedException \
 *	  OFConnectionFailedException.h ObjFW/OFConnectionFailedException.h
 *
 * @brief An exception indicating that a connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	OFString *_host;
	uint16_t _port;
	unsigned char _node[IPX_NODE_LEN];
	uint32_t _network;
	OFString *_Nullable _path;
	id _socket;
	int _errNo;
}

/**
 * @brief The host to which the connection failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *host;

/**
 * @brief The port on the host to which the connection failed.
 */
@property (readonly, nonatomic) uint16_t port;

/**
 * @brief The IPX node to which the connection failed.
 */
@property (readonly, nonatomic) unsigned char *node;

/**
 * @brief The IPX network of the node to which the connection failed.
 */
@property (readonly, nonatomic) uint32_t network;

/**
 * @brief The path to which the connection failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief The socket which could not connect.
 */
@property (readonly, nonatomic) id socket;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Creates a new, autoreleased connection failed exception.
 *
 * @param host The host to which the connection failed
 * @param port The port on the host to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connection failed exception
 */
+ (instancetype)exceptionWithHost: (nullable OFString *)host
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased connection failed exception.
 *
 * @param node The node to which the connection failed
 * @param network The IPX network of the node to which the connection failed
 * @param port The port on the node to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connection failed exception
 */
+ (instancetype)exceptionWithNode: (unsigned char [_Nullable IPX_NODE_LEN])node
			  network: (uint32_t)network
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased connection failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connection failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)socket
			    errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated connection failed exception.
 *
 * @param host The host to which the connection failed
 * @param port The port on the host to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connection failed exception
 */
- (instancetype)initWithHost: (nullable OFString *)host
			port: (uint16_t)port
		      socket: (id)socket
		       errNo: (int)errNo;

/**
 * @brief Initializes an already allocated connection failed exception.
 *
 * @param node The node to which the connection failed
 * @param network The IPX network of the node to which the connection failed
 * @param port The port on the node to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connection failed exception
 */
- (instancetype)initWithNode: (unsigned char [_Nullable IPX_NODE_LEN])node
		     network: (uint32_t)network
			port: (uint16_t)port
		      socket: (id)socket
		       errNo: (int)errNo;

/**
 * @brief Initializes an already allocated connection failed exception.
 *
 * @param path The path to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connection failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		      socket: (id)socket
		       errNo: (int)errNo;
@end

OF_ASSUME_NONNULL_END
