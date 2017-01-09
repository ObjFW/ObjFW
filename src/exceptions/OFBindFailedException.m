/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#include <inttypes.h>

#import "OFBindFailedException.h"
#import "OFString.h"

@implementation OFBindFailedException
@synthesize host = _host, port = _port, socket = _socket, errNo = _errNo;

+ (instancetype)exceptionWithHost: (OFString*)host
			     port: (uint16_t)port
			   socket: (id)socket
			    errNo: (int)errNo
{
	return [[[self alloc] initWithHost: host
				      port: port
				    socket: socket
				     errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithHost: (OFString*)host
	  port: (uint16_t)port
	socket: (id)socket
	 errNo: (int)errNo
{
	self = [super init];

	@try {
		_host = [host copy];
		_port = port;
		_socket = [socket retain];
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

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Binding to port %" @PRIu16 @" on host %@ failed in socket of "
	    @"type %@: %@",
	    _port, _host, [_socket class], of_strerror(_errNo)];
}
@end
