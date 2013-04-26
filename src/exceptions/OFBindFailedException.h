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

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

@class OFTCPSocket;

/*!
 * @brief An exception indicating that binding a socket failed.
 */
@interface OFBindFailedException: OFException
{
	OFTCPSocket *_socket;
	OFString    *_host;
	uint16_t    _port;
	int	    _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFTCPSocket *socket;
@property (readonly, copy, nonatomic) OFString *host;
@property (readonly) uint16_t port;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased bind failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param socket The socket which could not be bound
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @return A new, autoreleased bind failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    socket: (OFTCPSocket*)socket
			      host: (OFString*)host
			      port: (uint16_t)port;

/*!
 * @brief Initializes an already allocated bind failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param socket The socket which could not be bound
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @return An initialized bind failed exception
 */
- initWithClass: (Class)class_
	 socket: (OFTCPSocket*)socket
	   host: (OFString*)host
	   port: (uint16_t)port;

/*!
 * @brief Returns the socket which could not be bound.
 *
 * @return The socket which could not be bound
 */
- (OFTCPSocket*)socket;

/*!
 * @brief Returns the host on which binding failed.
 *
 * @return The host on which binding failed
 */
- (OFString*)host;

/*!
 * @brief Return the port on which binding failed.
 *
 * @return The port on which binding failed
 */
- (uint16_t)port;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
