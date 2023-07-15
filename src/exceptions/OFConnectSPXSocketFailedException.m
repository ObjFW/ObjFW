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
	return [[[self alloc] initWithNetwork: network
					 node: node
					 port: port
				       socket: sock
					errNo: errNo] autorelease];
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
	    @"A connection to %02X:%02X:%02X:%02X:%02X:%02X port %" @PRIu16
	    @" on network %" @PRIX32 " could not be established in socket of "
	    @"type %@: %@",
	    _node[0], _node[1], _node[2], _node[3], _node[4], _node[5], _port,
	    _network, [_socket class], OFStrError(_errNo)];
}
@end
