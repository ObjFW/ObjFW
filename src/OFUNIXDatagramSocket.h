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

#import "OFDatagramSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @protocol OFUNIXDatagramSocketDelegate OFUNIXDatagramSocket.h \
 *	     ObjFW/OFUNIXDatagramSocket.h
 *
 * @brief A delegate for OFUNIXDatagramSocket.
 */
@protocol OFUNIXDatagramSocketDelegate <OFDatagramSocketDelegate>
@end

/**
 * @class OFUNIXDatagramSocket OFUNIXDatagramSocket.h \
 *	  ObjFW/OFUNIXDatagramSocket.h
 *
 * @brief A class which provides methods to create and use UNIX datagram
 *	  sockets.
 *
 * Addresses are of type @ref OFSocketAddress. You can use
 * @ref OFSocketAddressMakeUNIX to create an address or
 * @ref OFSocketAddressUNIXPath to get the socket path.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the socket, but instead retains it.
 *	    This is so that the socket can be used as a key for a dictionary,
 *	    so context can be associated with a socket. Using a socket in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 */
@interface OFUNIXDatagramSocket: OFDatagramSocket
{
	OF_RESERVE_IVARS(OFUNIXDatagramSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFUNIXDatagramSocketDelegate> delegate;

/**
 * @brief Bind the socket to the specified path.
 *
 * @param path The path to bind to or `nil` for an anonymous socket
 * @return The address on which this socket can be reached, if a path was
 *	   specified
 * @throw OFBindUNIXSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already bound
 */
- (OFSocketAddress)bindToPath: (nullable OFString *)path;
@end

OF_ASSUME_NONNULL_END
