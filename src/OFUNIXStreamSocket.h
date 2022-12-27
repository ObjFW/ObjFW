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

#import "OFStreamSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/**
 * @protocol OFUNIXStreamSocketDelegate OFUNIXStreamSocket.h \
 *	     ObjFW/OFUNIXStreamSocket.h
 *
 * A delegate for OFUNIXStreamSocket.
 */
@protocol OFUNIXStreamSocketDelegate <OFStreamSocketDelegate>
@end

/**
 * @class OFUNIXStreamSocket OFUNIXStreamSocket.h ObjFW/OFUNIXStreamSocket.h
 *
 * @brief A class which provides methods to create and use UNIX stream sockets.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFUNIXStreamSocket: OFStreamSocket
{
	OF_RESERVE_IVARS(OFUNIXStreamSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFUNIXStreamSocketDelegate> delegate;

/**
 * @brief Connects the OFUNIXStreamSocket to the specified destination.
 *
 * @param path The path to connect to
 * @throw OFConnectUNIXSocketFailedException Connecting failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)connectToPath: (OFString *)path;

/**
 * @brief Binds the socket to the specified host and port.
 *
 * @param path The path to bind to
 * @throw OFBindUNIXSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)bindToPath: (OFString *)path;
@end

OF_ASSUME_NONNULL_END
