/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFBindIPXSocketFailedException.h"
#import "OFData.h"
#import "OFString.h"

@implementation OFBindIPXSocketFailedException
@synthesize network = _network, port = _port, packetType = _packetType;

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)
    exceptionWithNetwork: (uint32_t)network
		    node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
		    port: (uint16_t)port
	      packetType: (uint8_t)packetType
		  socket: (id)sock
		   errNo: (int)errNo
{
	return [[[self alloc] initWithNetwork: network
					 node: node
					 port: port
				   packetType: packetType
				       socket: sock
					errNo: errNo] autorelease];
}

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)
    initWithNetwork: (uint32_t)network
	       node: (const unsigned char [_Nonnull IPX_NODE_LEN])node
	       port: (uint16_t)port
	 packetType: (uint8_t)packetType
	     socket: (id)sock
	      errNo: (int)errNo
{
	self = [super initWithSocket: sock errNo: errNo];

	@try {
		_network = network;
		memcpy(_node, node, sizeof(_node));
		_port = port;
		_packetType = packetType;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)getNode: (unsigned char [IPX_NODE_LEN])node
{
	memcpy(node, _node, sizeof(_node));
}

- (OFString *)description
{
	OFData *node = [OFData dataWithItems: _node count: sizeof(_node)];

	return [OFString stringWithFormat:
	    @"Binding to network %" @PRIx16 " on node %@ with port %" @PRIx16
	    @" failed for packet type %" @PRIx8 " in socket of type %@: %@",
	    _network, node, _port, _packetType, [_socket class],
	    OFStrError(_errNo)];
}
@end
