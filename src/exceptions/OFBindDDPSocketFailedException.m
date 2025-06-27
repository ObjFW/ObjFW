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

#import "OFBindDDPSocketFailedException.h"
#import "OFData.h"
#import "OFString.h"

@implementation OFBindDDPSocketFailedException
@synthesize network = _network, node = _node, port = _port;
@synthesize protocolType = _protocolType;

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithNetwork: (uint16_t)network
				node: (uint8_t)node
				port: (uint8_t)port
			protocolType: (uint8_t)protocolType
			      socket: (id)sock
			       errNo: (int)errNo
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithNetwork: network
				     node: node
				     port: port
			     protocolType: protocolType
				   socket: sock
				    errNo: errNo]);
}

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithNetwork: (uint16_t)network
			   node: (uint8_t)node
			   port: (uint8_t)port
		   protocolType: (uint8_t)protocolType
			 socket: (id)sock
			  errNo: (int)errNo
{
	self = [super initWithSocket: sock errNo: errNo];

	@try {
		_network = network;
		_node = node;
		_port = port;
		_protocolType = protocolType;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"Binding to port %" @PRIx8 @" of node %" @PRIx8 @" on network "
	    @"%" PRIx16 @" with protocol type 0x%" @PRIX8 @" failed in socket "
	    @"of type %@: %@",
	    _port, _node, _network, _protocolType, [_socket class],
	    OFStrError(_errNo)];
}
@end
