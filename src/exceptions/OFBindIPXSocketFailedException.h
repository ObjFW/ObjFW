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

#import "OFBindSocketFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFBindIPXSocketFailedException \
 *	  OFBindIPXSocketFailedException.h \
 *	  ObjFW/OFBindIPXSocketFailedException.h
 *
 * @brief An exception indicating that binding an IPX socket failed.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFBindIPXSocketFailedException: OFBindSocketFailedException
{
	uint16_t _port;
	uint8_t _packetType;
}

/**
 * @brief The IPX port on which binding failed.
 */
@property (readonly, nonatomic) uint16_t port;

/**
 * @brief The IPX packet type for which binding failed.
 */
@property (readonly, nonatomic) uint8_t packetType;

/**
 * @brief Creates a new, autoreleased bind IPX socket failed exception.
 *
 * @param port The IPX port to which binding failed
 * @param packetType The IPX packet type for which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased bind IPX socket failed exception
 */
+ (instancetype)exceptionWithPort: (uint16_t)port
		       packetType: (uint8_t)packetType
			   socket: (id)socket
			    errNo: (int)errNo;

+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated bind IPX socket failed exception.
 *
 * @param port The IPX port to which binding failed
 * @param packetType The IPX packet type for which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
 * @return An initialized bind IPX socket failed exception
 */
- (instancetype)initWithPort: (uint16_t)port
		  packetType: (uint8_t)packetType
		      socket: (id)socket
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSocket: (id)socket errNo: (int)errNo OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
