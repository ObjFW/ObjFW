/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFConnectSPXSocketFailedException.h"
#import "OFData.h"
#import "OFString.h"

@implementation OFConnectSPXSocketFailedException
@synthesize network = _network, port = _port;

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithNetwork: (uint32_t)network
				node: (const unsigned char [IPX_NODE_LEN])node
				port: (uint16_t)port
			      socket: (id)sock
			       errNo: (int)errNo
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithNetwork: network
				     node: node
				     port: port
				   socket: sock
				    errNo: errNo]);
}

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithNetwork: (uint32_t)network
			   node: (const unsigned char [IPX_NODE_LEN])node
			   port: (uint16_t)port
			 socket: (id)sock
			  errNo: (int)errNo
{
	self = [super initWithSocket: sock errNo: errNo];

	@try {
		_network = network;
		memcpy(_node, node, IPX_NODE_LEN);
		_port = port;
	} @catch (id e) {
		objc_release(self);
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
	    @"A connection to %02X:%02X:%02X:%02X:%02X:%02X port %" @PRIu16
	    @" on network %" @PRIX32 " could not be established in socket of "
	    @"type %@: %@",
	    _node[0], _node[1], _node[2], _node[3], _node[4], _node[5], _port,
	    _network, [_socket class], OFStrError(_errNo)];
}
@end
