/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
@synthesize host = _host, port = _port, path = _path, network = _network;
@synthesize socket = _socket, errNo = _errNo;

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

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path
				    socket: sock
				     errNo: errNo] autorelease];
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

- (instancetype)initWithPath: (OFString *)path
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super init];

	@try {
		_path = [path copy];
		_socket = [sock retain];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithNetwork: (uint32_t)network
			   node: (const unsigned char [IPX_NODE_LEN])node
			   port: (uint16_t)port
			 socket: (id)sock
			  errNo: (int)errNo
{
	self = [super init];

	@try {
		_network = network;
		memcpy(_node, node, IPX_NODE_LEN);
		_port = port;
		_socket = [sock retain];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_host release];
	[_path release];
	[_socket release];

	[super dealloc];
}

- (unsigned char *)node
{
	return _node;
}

- (OFString *)description
{
	if (_path != nil)
		return [OFString stringWithFormat:
		    @"A connection to %@ could not be established in socket of "
		    @"type %@: %@",
		    _path, [_socket class], OFStrError(_errNo)];
	else if (_host != nil)
		return [OFString stringWithFormat:
		    @"A connection to %@ on port %" @PRIu16 @" could not be "
		    @"established in socket of type %@: %@",
		    _host, _port, [_socket class], OFStrError(_errNo)];
	else if (memcmp(_node, "\0\0\0\0\0", IPX_NODE_LEN) == 0)
		return [OFString stringWithFormat:
		    @"A connection to %02X%02X%02X%02X%02X%02X port %" @PRIu16
		    @" on network %" @PRIX32 " could not be established in "
		    @"socket of type %@: %@",
		    _node[0], _node[1], _node[2], _node[3], _node[4], _node[5],
		    _port, _network, [_socket class], OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"A connection could not be established in socket of "
		    @"type %@: %@",
		    [_socket class], OFStrError(_errNo)];
}
@end
