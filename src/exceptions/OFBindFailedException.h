/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

/*!
 * The host on which binding failed.
 */
@property (readonly, copy) OFString *host;

/*!
 * The port on which binding failed.
 */
@property (readonly) uint16_t port;

/*!
 * The socket which could not be bound.
 */
@property (readonly, retain) id socket;

/*!
 * The errno of the error that occurred.
 */
@property (readonly) int errNo;

/*!
 * @brief Creates a new, autoreleased bind failed exception.
 *
 * @param host The host on which binding failed
 * @param port The port on which binding failed
 * @param socket The socket which could not be bound
 * @param errNo The errno of the error that occurred
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
 * @param errNo The errno of the error that occurred
 * @return An initialized bind failed exception
 */
- initWithHost: (OFString*)host
	  port: (uint16_t)port
	socket: (id)socket
	 errNo: (int)errNo;
@end
