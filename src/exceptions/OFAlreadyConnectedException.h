/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFAlreadyConnectedException \
 *	  OFAlreadyConnectedException.h ObjFW/OFAlreadyConnectedException.h
 *
 * @brief An exception indicating an attempt to connect or bind an already
 *        connected or bound socket.
 */
@interface OFAlreadyConnectedException: OFException
{
	id _socket;
}

/*!
 * @brief The socket which is already connected.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id socket;

/*!
 * @brief Creates a new, autoreleased already connected exception.
 *
 * @param socket The socket which is already connected
 * @return A new, autoreleased already connected exception
 */
+ (instancetype)exceptionWithSocket: (nullable id)socket;

/*!
 * @brief Initializes an already allocated already connected exception.
 *
 * @param socket The socket which is already connected
 * @return An initialized already connected exception
 */
- (instancetype)initWithSocket: (nullable id)socket OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
