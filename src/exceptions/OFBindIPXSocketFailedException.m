/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
	return [OFString stringWithFormat:
	    @"Binding to network %" @PRIx16 " on node "
	    @"%02X:%02X:%02X:%02X:%02X:%02X with port %" @PRIx16 @" failed for "
	    @"packet type %" @PRIx8 " in socket of type %@: %@",
	    _network, _node[0], _node[1], _node[2], _node[3], _node[4],
	    _node[5], _port, _packetType, [_socket class], OFStrError(_errNo)];
}
@end
