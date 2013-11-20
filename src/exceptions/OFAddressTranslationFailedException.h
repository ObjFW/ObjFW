/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <errno.h>

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

@class OFTCPSocket;

/*!
 * @brief An exception indicating the translation of an address failed.
 */
@interface OFAddressTranslationFailedException: OFException
{
	OFTCPSocket *_socket;
	OFString    *_host;
	int	    _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *host;
@property (readonly, retain) OFTCPSocket *socket;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased address translation failed exception.
 *
 * @param socket The socket which could not translate the address
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithSocket: (OFTCPSocket*)socket;

/*!
 * @brief Creates a new, autoreleased address translation failed exception.
 *
 * @param host The host for which translation was requested
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithHost: (OFString*)host;

/*!
 * @brief Creates a new, autoreleased address translation failed exception.
 *
 * @param host The host for which translation was requested
 * @param socket The socket which could not translate the address
 * @return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithHost: (OFString*)host
			   socket: (OFTCPSocket*)socket;

/*!
 * @brief Initializes an already allocated address translation failed exception.
 *
 * @param socket The socket which could not translate the address
 * @return An initialized address translation failed exception
 */
- initWithSocket: (OFTCPSocket*)socket;

/*!
 * @brief Initializes an already allocated address translation failed exception.
 *
 * @param host The host for which translation was requested
 * @return An initialized address translation failed exception
 */
- initWithHost: (OFString*)host;

/*!
 * @brief Initializes an already allocated address translation failed exception.
 *
 * @param host The host for which translation was requested
 * @param socket The socket which could not translate the address
 * @return An initialized address translation failed exception
 */
- initWithHost: (OFString*)host
	socket: (OFTCPSocket*)socket;

/*!
 * @brief Returns the host for which the address translation was requested.
 *
 * @return The host for which the address translation was requested
 */
- (OFString*)host;

/*!
 * @brief Returns the socket which could not translate the address.
 *
 * @return The socket which could not translate the address
 */
- (OFTCPSocket*)socket;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
