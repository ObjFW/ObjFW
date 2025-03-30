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

#import "OFStreamSocket.h"

OF_ASSUME_NONNULL_BEGIN

@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFString;

/**
 * @brief A key for UNIX socket credentials.
 *
 * Possible keys are:
 *
 *  * OFUNIXSocketCredentialsUserID
 *  * OFUNIXSocketCredentialsGroupID
 *  * OFUNIXSocketCredentialsProcessID
 */
typedef OFConstantString *OFUNIXSocketCredentialsKey;

/**
 * @brief Credentials for a UNIX socket.
 */
typedef OFDictionary OF_GENERIC(OFUNIXSocketCredentialsKey, id)
    *OFUNIXSocketCredentials;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The user ID of the credentials.
 *
 * This maps to an @ref OFNumber.
 */
extern OFUNIXSocketCredentialsKey OFUNIXSocketCredentialsUserID;

/**
 * @brief The group ID of the credentials.
 *
 * This maps to an @ref OFNumber.
 */
extern OFUNIXSocketCredentialsKey OFUNIXSocketCredentialsGroupID;

/**
 * @brief The process ID of the credentials.
 *
 * This maps to an @ref OFNumber.
 */
extern OFUNIXSocketCredentialsKey OFUNIXSocketCredentialsProcessID;
#ifdef __cplusplus
}
#endif

/**
 * @protocol OFUNIXStreamSocketDelegate OFUNIXStreamSocket.h ObjFW/ObjFW.h
 *
 * A delegate for OFUNIXStreamSocket.
 */
@protocol OFUNIXStreamSocketDelegate <OFStreamSocketDelegate>
@end

/**
 * @class OFUNIXStreamSocket OFUNIXStreamSocket.h ObjFW/ObjFW.h
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
 * @brief The credentials of the peer the socket is connected to.
 */
@property (readonly, nonatomic) OFUNIXSocketCredentials peerCredentials;

/**
 * @brief Connects the OFUNIXStreamSocket to the specified path.
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
