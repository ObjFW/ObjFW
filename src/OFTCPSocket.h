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

/**
 * Receive data from the socket into a buffer.
 *
 * \param buf The buffer into which the data is read
 * \param size The size of the data that should be read.
 *	  The buffer MUST be at least size big!
 * \return The number of bytes read
 */
- (size_t)readNBytes: (size_t)size
	  intoBuffer: (uint8_t*)buf;

/**
 * Receive data from the socket into a new buffer.
 *
 * \param size The size of the data that should be read
 * \return A new buffer with the data read.
 *	   It is part of the memory pool of the OFFile.
 */
- (uint8_t*)readNBytes: (size_t)size;

/**
 * Sends data from a buffer.
 *
 * \param buf The buffer from which the data is written to the file
 * \param size The size of the data that should be written
 * \return The number of bytes written
 */
- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const uint8_t*)buf;

/**
 * Sends a C string, without the trailing zero.
 *
 * \param str The C string from which the data is sent
 * \return The number of bytes written
 */
- (size_t)writeCString: (const char*)str;
@end
