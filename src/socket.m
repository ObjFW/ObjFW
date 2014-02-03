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

#include "config.h"

#import "socket.h"

static bool initialized = false;

bool
of_init_sockets()
{
	if (initialized)
		return true;

#ifdef _WIN32
	WSADATA wsa;

	if (WSAStartup(MAKEWORD(2, 0), &wsa))
		return false;
#elif defined(__wii__)
	if (net_init() < 0)
		return false;
#endif

	initialized = true;
	return true;
}
