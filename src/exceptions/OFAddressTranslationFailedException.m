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

#import "OFAddressTranslationFailedException.h"
#import "OFString.h"
#import "OFTCPSocket.h"

#import "common.h"

@implementation OFAddressTranslationFailedException
+ (instancetype)exceptionWithClass: (Class)class
			    socket: (OFTCPSocket*)socket
			      host: (OFString*)host
{
	return [[[self alloc] initWithClass: class
				     socket: socket
				       host: host] autorelease];
}

- initWithClass: (Class)class
{
	self = [super initWithClass: class];

	_errNo = GET_AT_ERRNO;

	return self;
}

- initWithClass: (Class)class
	 socket: (OFTCPSocket*)socket
	   host: (OFString*)host
{
	self = [super initWithClass: class];

	@try {
		_socket = [socket retain];
		_host   = [host copy];
		_errNo  = GET_AT_ERRNO;
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
	if (_host != nil)
		return [OFString stringWithFormat:
		    @"The host %@ could not be translated to an address in "
		    @"class %@. This means that either the host was not found, "
		    @"there was a problem with the name server, there was a "
		    @"problem with your network connection or you specified an "
		    @"invalid host. " ERRFMT, _host, _inClass, AT_ERRPARAM];
	else
		return [OFString stringWithFormat:
		    @"An address translation failed in class %@! " ERRFMT,
		    _inClass, AT_ERRPARAM];
}

- (OFTCPSocket*)socket
{
	OF_GETTER(_socket, NO)
}

- (OFString*)host
{
	OF_GETTER(_host, NO)
}

- (int)errNo
{
	return _errNo;
}
@end
