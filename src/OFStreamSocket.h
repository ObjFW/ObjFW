/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFStream.h"

#ifdef _WIN32
# ifndef _WIN32_WINNT
#  define _WIN32_WINNT 0x0501
# endif
# include <winsock2.h>
#endif

/**
 * \brief A class which provides functions to create and use stream sockets.
 */
@interface OFStreamSocket: OFStream
{
@public
#ifndef _WIN32
	int    sock;
#else
	SOCKET sock;
#endif
	BOOL   listening;
@protected
	BOOL   eos;
}

/**
 * \return A new autoreleased OFTCPSocket
 */
+ socket;

/**
 * Enables/disables non-blocking I/O.
 */
- (void)setBlocking: (BOOL)enable;
@end
