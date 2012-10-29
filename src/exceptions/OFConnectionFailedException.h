/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

@class OFTCPSocket;

/**
 * \brief An exception indicating that a connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	OFTCPSocket *socket;
	OFString    *host;
	uint16_t    port;
	int	    errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFTCPSocket *socket;
@property (readonly, copy, nonatomic) OFString *host;
@property (readonly) uint16_t port;
@property (readonly) int errNo;
#endif

/**
 * \brief Creates a new, autoreleased connection failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param socket The socket which could not connect
 * \param host The host to which the connection failed
 * \param port The port on the host to which the connection failed
 * \return A new, autoreleased connection failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    socket: (OFTCPSocket*)socket
			      host: (OFString*)host
			      port: (uint16_t)port;

/**
 * \brief Initializes an already allocated connection failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param socket The socket which could not connect
 * \param host The host to which the connection failed
 * \param port The port on the host to which the connection failed
 * \return An initialized connection failed exception
 */
- initWithClass: (Class)class_
	 socket: (OFTCPSocket*)socket
	   host: (OFString*)host
	   port: (uint16_t)port;

/**
 * \brief Returns the socket which could not connect.
 *
 * \return The socket which could not connect
 */
- (OFTCPSocket*)socket;

/**
 * \brief Returns the host to which the connection failed.
 *
 * \return The host to which the connection failed
 */
- (OFString*)host;

/**
 * \brief Returns the port on the host to which the connection failed.
 *
 * \return The port on the host to which the connection failed
 */
- (uint16_t)port;

/**
 * \brief Returns the errno from when the exception was created.
 *
 * \return The errno from when the exception was created
 */
- (int)errNo;
@end
