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

#import "OFConnectIPSocketFailedException.h"
#import "OFString.h"

@implementation OFConnectIPSocketFailedException
@synthesize host = _host, port = _port;

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
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

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithHost: (OFString *)host
			port: (uint16_t)port
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super initWithSocket: sock errNo: errNo];

	@try {
		_host = [host copy];
		_port = port;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_host release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"A connection to %@ on port %" @PRIu16 @" could not be "
	    @"established in socket of type %@: %@",
	    _host, _port, [_socket class], OFStrError(_errNo)];
}
@end
