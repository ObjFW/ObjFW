/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdlib.h>

#import "OFConnectionFailedException.h"
#import "OFString.h"
#import "OFTCPSocket.h"

#import "common.h"

@implementation OFConnectionFailedException
+ (instancetype)exceptionWithClass: (Class)class
			    socket: (OFTCPSocket*)socket
			      host: (OFString*)host
			      port: (uint16_t)port
{
	return [[[self alloc] initWithClass: class
				     socket: socket
				       host: host
				       port: port] autorelease];
}

- initWithClass: (Class)class
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithClass: (Class)class
	 socket: (OFTCPSocket*)socket
	   host: (OFString*)host
	   port: (uint16_t)port
{
	self = [super initWithClass: class];

	@try {
		_socket = [socket retain];
		_host   = [host copy];
		_port   = port;
		_errNo  = GET_SOCK_ERRNO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_socket release];
	[_host release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"A connection to %@ on port %" @PRIu16 @" could not be "
	    @"established in class %@! " ERRFMT, _host, _port, _inClass,
	    ERRPARAM];
}

- (OFTCPSocket*)socket
{
	OF_GETTER(_socket, false)
}

- (OFString*)host
{
	OF_GETTER(_host, false)
}

- (uint16_t)port
{
	return _port;
}

- (int)errNo
{
	return _errNo;
}
@end
