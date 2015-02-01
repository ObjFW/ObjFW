/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

/*!
 * @class OFBindFailedException \
 *	  OFBindFailedException.h ObjFW/OFBindFailedException.h
 *
 * @brief An exception indicating that binding a socket failed.
 */
@interface OFBindFailedException: OFException
{
	id _socket;
	OFString *_host;
	uint16_t _port;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *host;
@property (readonly) uint16_t port;
@property (readonly, retain) id socket;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased bind failed exception.
 *
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error
 * @return A new, autoreleased bind failed exception
 */
+ (instancetype)exceptionWithHost: (OFString*)host
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated bind failed exception.
 *
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error
 * @return An initialized bind failed exception
 */
- initWithHost: (OFString*)host
	  port: (uint16_t)port
	socket: (id)socket
	 errNo: (int)errNo;

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
 * @brief Returns the socket which could not be bound.
 *
 * @return The socket which could not be bound
 */
- (id)socket;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
