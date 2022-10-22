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
 * @class OFBindFailedException \
 *	  OFBindFailedException.h ObjFW/OFBindFailedException.h
 *
 * @brief An exception indicating that binding a socket failed.
 */
@interface OFBindFailedException: OFException
{
	/* IP */
	OFString *_Nullable _host;
	uint16_t _port;
	/* IPX */
	uint8_t _packetType;
	/* UNIX socket */
	OFString *_Nullable _path;
	id _socket;
	int _errNo;
	OF_RESERVE_IVARS(OFBindFailedException, 4)
}

/**
 * @brief The host on which binding failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *host;

/**
 * @brief The port on which binding failed.
 */
@property (readonly, nonatomic) uint16_t port;

/**
 * @brief The IPX packet type for which binding failed.
 */
@property (readonly, nonatomic) uint8_t packetType;

/**
 * @brief The path on which binding failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *path;

/**
 * @brief The socket which could not be bound.
 */
@property (readonly, nonatomic) id socket;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased bind failed exception.
 *
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind failed exception
 */
+ (instancetype)exceptionWithHost: (OFString *)host
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased bind failed exception.
 *
 * @param path The path on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind failed exception
 */
+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)socket
			    errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased bind failed exception.
 *
 * @param port The port to which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind failed exception
 */
+ (instancetype)exceptionWithPort: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

/**
 * @brief Creates a new, autoreleased bind failed exception.
 *
 * @param port The port to which binding failed
 * @param packetType The IPX packet type for which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind failed exception
 */
+ (instancetype)exceptionWithPort: (uint16_t)port
		       packetType: (uint8_t)packetType
			   socket: (id)socket
			    errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind failed exception.
 *
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind failed exception
 */
- (instancetype)initWithHost: (OFString *)host
			port: (uint16_t)port
		      socket: (id)socket
		       errNo: (int)errNo;
/**
 * @brief Initializes an already allocated bind failed exception.
 *
 * @param path The path on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind failed exception
 */
- (instancetype)initWithPath: (OFString *)path
		      socket: (id)socket
		       errNo: (int)errNo;

/**
 * @brief Initializes an already allocated bind failed exception.
 *
 * @param port The port to which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind failed exception
 */
- (instancetype)initWithPort: (uint16_t)port
		      socket: (id)socket
		       errNo: (int)errNo;

/**
 * @brief Initializes an already allocated bind failed exception.
 *
 * @param port The port to which binding failed
 * @param packetType The IPX packet type for which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind failed exception
 */
- (instancetype)initWithPort: (uint16_t)port
		  packetType: (uint8_t)packetType
		      socket: (id)socket
		       errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
