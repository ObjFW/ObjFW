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

@class OFStreamSocket;

/*!
 * @brief An exception indicating a socket is not connected or bound.
 */
@interface OFNotConnectedException: OFException
{
	OFStreamSocket *socket;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFStreamSocket *socket;
#endif

/*!
 * @brief Creates a new, autoreleased not connected exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param socket The socket which is not connected
 * @return A new, autoreleased not connected exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			    socket: (OFStreamSocket*)socket;

/*!
 * @brief Initializes an already allocated not connected exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param socket The socket which is not connected
 * @return An initialized not connected exception
 */
- initWithClass: (Class)class_
	 socket: (OFStreamSocket*)socket;

/*!
 * @brief Returns the socket which is not connected.
 *
 * @return The socket which is not connected
 */
- (OFStreamSocket*)socket;
@end
