/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

/*!
 * @brief The socket which could not accept a connection.
 */
@property (readonly, nonatomic) id socket;

/*!
 * @brief The errno from when the exception was created.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @param errNo The errno for the error
 * @return A new, autoreleased accept failed exception
 */
+ (instancetype)exceptionWithSocket: (id)socket
			      errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated accept failed exception.
 *
 * @param socket The socket which could not accept a connection
 * @param errNo The errno for the error
 * @return An initialized accept failed exception
 */
- (instancetype)initWithSocket: (id)socket
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
