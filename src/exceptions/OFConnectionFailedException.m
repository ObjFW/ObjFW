/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "OFConnectionFailedException.h"
#import "OFString.h"

@implementation OFConnectionFailedException
@synthesize host = _host, port = _port, network = _network, socket = _socket;
@synthesize errNo = _errNo;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithHost: (OFString *)host
			     port: (uint16_t)port
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithHost: host
				      port: port
				    socket: sock
				     errNo: errNo] autorelease];
}

+ (instancetype)exceptionWithNode: (unsigned char [IPX_NODE_LEN])node
			  network: (uint32_t)network
			     port: (uint16_t)port
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithNode: node
				   network: network
				      port: port
				    socket: sock
				     errNo: errNo] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithHost: (OFString *)host
			port: (uint16_t)port
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super init];

	@try {
		_host = [host copy];
		_port = port;
		_socket = [sock retain];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithNode: (unsigned char [IPX_NODE_LEN])node
		     network: (uint32_t)network
			port: (uint16_t)port
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super init];

	@try {
		memcpy(_node, node, IPX_NODE_LEN);
		_network = network;
		_port = port;
		_socket = [sock retain];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_host release];
	[_socket release];

	[super dealloc];
}

- (unsigned char *)node
{
	return _node;
}

- (OFString *)description
{
	if (_host != nil)
		return [OFString stringWithFormat:
		    @"A connection to %@ on port %" @PRIu16 @" could not be "
		    @"established in socket of type %@: %@",
		    _host, _port, [_socket class], of_strerror(_errNo)];
	else if (memcmp(_node, "\0\0\0\0\0", IPX_NODE_LEN) == 0)
		return [OFString stringWithFormat:
		    @"A connection to %02X%02X%02X%02X%02X%02X port %" @PRIu16
		    @" on network %" @PRIX32 " could not be established in "
		    @"socket of type %@: %@",
		    _node[0], _node[1], _node[2], _node[3], _node[4], _node[5],
		    _port, _network, [_socket class], of_strerror(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"A connection could not be established in socket of "
		    @"type %@: %@",
		    [_socket class], of_strerror(_errNo)];
}
@end
