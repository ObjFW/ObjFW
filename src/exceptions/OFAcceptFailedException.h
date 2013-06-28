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
 * @brief An exception indicating that accepting a connection failed.
 */
@interface OFAcceptFailedException: OFException
{
	OFTCPSocket *_socket;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFTCPSocket *socket;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @return A new, autoreleased accept failed exception
 */
+ (instancetype)exceptionWithSocket: (OFTCPSocket*)socket;

/*!
 * @brief Initializes an already allocated accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @return An initialized accept failed exception
 */
- initWithSocket: (OFTCPSocket*)socket;

/*!
 * @brief Returns the socket which could not accept a connection.
 *
 * @return The socket which could not accept a connection
 */
- (OFTCPSocket*)socket;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
