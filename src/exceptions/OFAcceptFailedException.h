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
 * @class OFAcceptFailedException \
 *	  OFAcceptFailedException.h ObjFW/OFAcceptFailedException.h
 *
 * @brief An exception indicating that accepting a connection failed.
 */
@interface OFAcceptFailedException: OFException
{
	id _socket;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) id socket;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @param errNo The errno for the error
 * @return A new, autoreleased accept failed exception
 */
+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @param errNo The errno for the error
 * @return An initialized accept failed exception
 */
- initWithSocket: (id)socket
	   errNo: (int)errNo;

/*!
 * @brief Returns the socket which could not accept a connection.
 *
 * @return The socket which could not accept a connection
 */
- (id)socket;

/*!
 * @brief Returns the errno from when the exception was created.
 *
 * @return The errno from when the exception was created
 */
- (int)errNo;
@end
