/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import <stdio.h>

#import <sys/types.h>
#import <sys/socket.h>
#import <netdb.h>

#import "OFObject.h"
#import "OFStream.h"

/**
 * The OFTCPSocket class provides functions to create and use sockets.
 */
@interface OFTCPSocket: OFObject <OFStream>
{
	int sock;
}

- free;

/**
 * Connect the OFTCPSocket to the specified destination.
 *
 * \param host The host to connect to
 * \param port The port of the host to connect to
 */
- connectTo: (const char*)host
     onPort: (uint16_t)port;
@end
