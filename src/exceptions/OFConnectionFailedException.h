/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

/**
 * \brief An exception indicating that a connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	OFString *host;
	uint16_t port;
	int	 errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *host;
@property (readonly) uint16_t port;
@property (readonly) int errNo;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param host The host to which the connection failed
 * \param port The port on the host to which the connection failed
 * \return A new connection failed exception
 */
+ newWithClass: (Class)class_
	  host: (OFString*)host
	  port: (uint16_t)port;

/**
 * Initializes an already allocated connection failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param host The host to which the connection failed
 * \param port The port on the host to which the connection failed
 * \return An initialized connection failed exception
 */
- initWithClass: (Class)class_
	   host: (OFString*)host
	   port: (uint16_t)port;

/**
 * \return The errno from when the exception was created
 */
- (int)errNo;

/**
 * \return The host to which the connection failed
 */
- (OFString*)host;

/**
 * \return The port on the host to which the connection failed
 */
- (uint16_t)port;
@end
