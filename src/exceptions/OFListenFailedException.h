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

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) id socket;
@property (readonly) int backLog, errNo;
#endif

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

/*!
 * @brief Initializes an already allocated listen failed exception
 *
 * @param socket The socket which failed to listen
 * @param backLog The requested size of the back log
 * @param errNo The errno of the error that occurred
 * @return An initialized listen failed exception
 */
- initWithSocket: (id)socket
	 backLog: (int)backLog
	   errNo: (int)errNo;

/*!
 * @brief Returns the socket which failed to listen.
 *
 * @return The socket which failed to listen
 */
- (id)socket;

/*!
 * @brief Returns the requested back log.
 *
 * @return The requested back log
 */
- (int)backLog;

/*!
 * @brief Returns the errno of the error that occurred.
 *
 * @return The errno of the error that occurred
 */
- (int)errNo;
@end
