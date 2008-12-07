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
 * The OFSocketAddress class is a class to build socket addresses.
 */
@interface OFSocketAddress: OFObject
{
	char *hoststr, portstr[6];
	struct addrinfo hints, *res;
}

/**
 * \param host The host of the address
 * \param port The port of the address
 * \param family The protocol family to use
 * \param type The socket type to use
 * \param protocol The specific protocol to use
 * \return A new OFSocketAddress
 */
+ newWithHost: (const char*)host
      andPort: (uint16_t)port
    andFamily: (int)family
      andType: (int)type
  andProtocol: (int)protocol;

/**
 * Initializes an already allocated OFSocketAddress.
 *
 * \param host The host of the address
 * \param port The port of the address
 * \param family The protocol family to use
 * \param type The socket type to use
 * \param protocol The specific protocol to use
 * \return An initialized OFSocketAddress
 */
- initWithHost: (const char*)host
       andPort: (uint16_t)port
     andFamily: (int)family
       andType: (int)type
   andProtocol: (int)protocol;

/*
 * \return The addrinfo struct for the OFSocketAddress
 */
- (struct addrinfo*)getAddressInfo;

- free;
@end

/**
 * The OFSocket class provides functions to create and use sockets.
 */
@interface OFSocket: OFObject <OFStream>
{
	int sock;
}

- free;

/**
 * Connect the OFSocket to a destination specified in an OFSocketAddress.
 *
 * \param addr A OFSocketAddress to connect to.
 */
- connect: (OFSocketAddress*)addr;

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
	   fromBuffer: (uint8_t*)buf;
@end
