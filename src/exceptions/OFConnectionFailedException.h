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
 * @class OFConnectionFailedException \
 *	  OFConnectionFailedException.h ObjFW/OFConnectionFailedException.h
 *
 * @brief An exception indicating that a connection could not be established.
 */
@interface OFConnectionFailedException: OFException
{
	id _socket;
	OFString *_host;
	uint16_t _port;
	int _errNo;
}

/*!
 * The socket which could not connect.
 */
@property (readonly, nonatomic) id socket;

/*!
 * The host to which the connection failed.
 */
@property (readonly, nonatomic) OFString *host;

/*!
 * The port on the host to which the connection failed.
 */
@property (readonly, nonatomic) uint16_t port;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased connection failed exception.
 *
 * @param host The host to which the connection failed
 * @param port The port on the host to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased connection failed exception
 */
+ (instancetype)exceptionWithHost: (OFString *)host
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated connection failed exception.
 *
 * @param host The host to which the connection failed
 * @param port The port on the host to which the connection failed
 * @param socket The socket which could not connect
 * @param errNo The errno of the error that occurred
 * @return An initialized connection failed exception
 */
- (instancetype)initWithHost: (OFString *)host
			port: (uint16_t)port
		      socket: (id)socket
		       errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
