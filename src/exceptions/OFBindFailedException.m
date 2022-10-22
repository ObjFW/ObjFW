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

#import "OFBindFailedException.h"
#import "OFString.h"

@implementation OFBindFailedException
@synthesize host = _host, port = _port, packetType = _packetType, path = _path;
@synthesize socket = _socket, errNo = _errNo;

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

+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path
				    socket: sock
				     errNo: errNo] autorelease];
}

+ (instancetype)exceptionWithPort: (uint16_t)port
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPort: port
				    socket: sock
				     errNo: errNo] autorelease];
}

+ (instancetype)exceptionWithPort: (uint16_t)port
		       packetType: (uint8_t)packetType
			   socket: (id)sock
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPort: port
				packetType: packetType
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

- (instancetype)initWithPort: (uint16_t)port
		      socket: (id)sock
		       errNo: (int)errNo
{
	return [self initWithPort: port
		       packetType: 0
			   socket: sock
			    errNo: errNo];
}

- (instancetype)initWithPort: (uint16_t)port
		  packetType: (uint8_t)packetType
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super init];

	@try {
		_port = port;
		_packetType = packetType;
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
	[_path release];
	[_socket release];

	[super dealloc];
}

- (OFString *)description
{
	if (_path != nil)
		return [OFString stringWithFormat:
		    @"Binding to path %@ failed in socket of type %@: %@",
		    _path, [_socket class], OFStrError(_errNo)];
	else if (_host != nil)
		return [OFString stringWithFormat:
		    @"Binding to port %" @PRIu16 @" on host %@ failed in "
		    @"socket of type %@: %@",
		    _port, _host, [_socket class], OFStrError(_errNo)];
	else if (_port != 0)
		return [OFString stringWithFormat:
		    @"Binding to port %" @PRIx16 @" for packet type %" @PRIx8
		    @" failed in socket of type %@: %@",
		    _port, _packetType, [_socket class], OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Binding to port %" @PRIx16 @" failed in socket of type "
		    @"%@: %@",
		    _port, [_socket class], OFStrError(_errNo)];
}
@end
