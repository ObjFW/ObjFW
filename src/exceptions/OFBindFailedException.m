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

#import "OFBindFailedException.h"
#import "OFString.h"
#import "OFTCPSocket.h"

#import "common.h"

@implementation OFBindFailedException
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
	if (_description != nil)
		return _description;

	_description = [[OFString alloc] initWithFormat:
	    @"Binding to port %" @PRIu16 @" on host %@ failed in class %@! "
	    ERRFMT, _port, _host, _inClass, ERRPARAM];

	return _description;
}

- (OFTCPSocket*)socket
{
	OF_GETTER(_socket, NO)
}

- (OFString*)host
{
	OF_GETTER(_host, NO)
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
