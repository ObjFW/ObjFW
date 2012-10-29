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
 * \brief An exception indicating the translation of an address failed.
 */
@interface OFAddressTranslationFailedException: OFException
{
	OFTCPSocket *socket;
	OFString    *host;
	int	    errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFTCPSocket *socket;
@property (readonly, copy, nonatomic) OFString *host;
@property (readonly) int errNo;
#endif

/**
 * \brief Creates a new, autoreleased address translation failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param socket The socket which could not translate the address
 * \param host The host for which translation was requested
 * \return A new, autoreleased address translation failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    socket: (OFTCPSocket*)socket
			      host: (OFString*)host;

/**
 * \brief Initializes an already allocated address translation failed exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param socket The socket which could not translate the address
 * \param host The host for which translation was requested
 * \return An initialized address translation failed exception
 */
- initWithClass: (Class)class_
	 socket: (OFTCPSocket*)socket
	   host: (OFString*)host;

/**
 * \brief Returns the socket which could not translate the address.
 *
 * \return The socket which could not translate the address
 */
- (OFTCPSocket*)socket;

/**
 * \brief Returns the host for which the address translation was requested.
 *
 * \return The host for which the address translation was requested
 */
- (OFString*)host;

/**
 * \brief Returns the errno from when the exception was created.
 *
 * \return The errno from when the exception was created
 */
- (int)errNo;
@end
