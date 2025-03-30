/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFSequencedPacketSocket.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFUNIXSequencedPacketSocketDelegate \
 *	     OFUNIXSequencedPacketSocket.h ObjFW/ObjFW.h
 *
 * A delegate for OFUNIXSequencedPacketSocket.
 */
@protocol OFUNIXSequencedPacketSocketDelegate <OFSequencedPacketSocketDelegate>
@end

/**
 * @class OFUNIXSequencedPacketSocket \
 *	  OFUNIXSequencedPacketSocket.h ObjFW/ObjFW.h
 *
 * @brief A class which provides methods to create and use UNIX sequenced
 *	  packet sockets.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFUNIXSequencedPacketSocket: OFSequencedPacketSocket
{
	OF_RESERVE_IVARS(OFUNIXSequencedPacketSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFUNIXSequencedPacketSocketDelegate> delegate;

/**
 * @brief Connects the OFUNIXSequencedPacketSocket to the specified path.
 *
 * @param path The path to connect to. If the path starts with an `@`, an
 *	       abstract UNIX socket is used on Linux.
 * @throw OFConnectUNIXSocketFailedException Connecting failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)connectToPath: (OFString *)path;

/**
 * @brief Binds the socket to the specified path.
 *
 * @param path The path to bind to. If the path starts with an `@`, an abstract
 *	       UNIX socket is used on Linux.
 * @throw OFBindUNIXSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)bindToPath: (OFString *)path;
@end

OF_ASSUME_NONNULL_END
