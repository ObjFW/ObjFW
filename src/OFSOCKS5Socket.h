/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFTCPSocket.h"

/**
 * \brief A class which provides functions to create and use TCP sockets using a
 *	  SOCKS5 proxy.
 */
@interface OFSOCKS5Socket: OFTCPSocket
{
	OFString *proxyHost;
	uint16_t proxyPort;
}

/**
 * \brief Creates a new OFSOCKS5Socket which uses the specified SOCKS5 proxy.
 *
 * \param proxyHost The host of the SOCKS5 proxy
 * \param proxyPort The port of the SOCKS5 proxy
 * \return A new, autoreleased OFSOCKS5Socket
 */
+ socketWithProxyHost: (OFString*)proxyHost
		 port: (uint16_t)proxyPort;

/**
 * \brief Initializes an already allocated OFSOCKS5Socket with the specified
 *	  SOCKS5 proxy.
 *
 * \param proxyHost The host of the SOCKS5 proxy
 * \param proxyPort The port of the SOCKS5 proxy
 * \return An initialized OFSOCKS5Socket
 */
- initWithProxyHost: (OFString*)proxyHost
	       port: (uint16_t)proxyPort;
@end
