/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFStream.h"

#import "socket.h"

/*!
 * @class OFStreamSocket OFStreamSocket.h ObjFW/OFStreamSocket.h
 *
 * @brief A class which provides functions to create and use stream sockets.
 */
@interface OFStreamSocket: OFStream
{
#ifndef _WIN32
	int    _socket;
#else
	SOCKET _socket;
#endif
	bool  _atEndOfStream;
}

/*!
 * @brief Returns a new, autoreleased OFTCPSocket.
 *
 * @return A new, autoreleased OFTCPSocket
 */
+ (instancetype)socket;
@end
