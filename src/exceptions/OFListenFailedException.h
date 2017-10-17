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
 * @class OFListenFailedException \
 *	  OFListenFailedException.h ObjFW/OFListenFailedException.h
 *
 * @brief An exception indicating that listening on the socket failed.
 */
@interface OFListenFailedException: OFException
{
	id _socket;
	int _backLog, _errNo;
}

/*!
 * The socket which failed to listen.
 */
@property (readonly, nonatomic) id socket;

/*!
 * The requested back log.
 */
@property (readonly, nonatomic) int backLog;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased listen failed exception.
 *
 * @param socket The socket which failed to listen
 * @param backLog The requested size of the back log
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased listen failed exception
 */
+ (instancetype)exceptionWithSocket: (id)socket
			    backLog: (int)backLog
			      errNo: (int)errNo;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated listen failed exception
 *
 * @param socket The socket which failed to listen
 * @param backLog The requested size of the back log
 * @param errNo The errno of the error that occurred
 * @return An initialized listen failed exception
 */
- (instancetype)initWithSocket: (id)socket
		       backLog: (int)backLog
			 errNo: (int)errNo OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
