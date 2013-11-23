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
#import "macros.h"

@implementation OFAddressTranslationFailedException
+ (instancetype)exceptionWithSocket: (OFTCPSocket*)socket
{
	return [[[self alloc] initWithSocket: socket] autorelease];
}

+ (instancetype)exceptionWithHost: (OFString*)host
{
	return [[[self alloc] initWithHost: host] autorelease];
}

+ (instancetype)exceptionWithHost: (OFString*)host
			   socket: (OFTCPSocket*)socket
{
	return [[[self alloc] initWithHost: host
				    socket: socket] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithSocket: (OFTCPSocket*)socket
{
	return [self initWithHost: nil
			   socket: socket];
}

- initWithHost: (OFString*)host
{
	return [self initWithHost: host
			   socket: nil];
}

- initWithHost: (OFString*)host
	socket: (OFTCPSocket*)socket
{
	self = [super init];

	@try {
		_host   = [host copy];
		_socket = [socket retain];
		_errNo  = GET_AT_ERRNO;
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
	if (_host != nil && _socket != nil)
		return [OFString stringWithFormat:
		    @"The host %@ could not be translated to an address for a "
		    @"socket of type %@. This means that either the host was "
		    @"not found, there was a problem with the name server, "
		    @"there was a problem with your network connection or you "
		    @"specified an invalid host. " ERRFMT, _host,
		    [_socket class], AT_ERRPARAM];
	else if (_socket != nil)
		return [OFString stringWithFormat:
		    @"An address could not be translated for a socket of type "
		    @"%@! " ERRFMT, [_socket class],
		    AT_ERRPARAM];
	else if (_host != nil)
		return [OFString stringWithFormat:
		    @"The host %@ could not be translated to an address. This "
		    @"means that either the host was not found, there was a "
		    @"problem with the name server, there was a problem with "
		    @"your network connection or you specified an invalid "
		    @"host. " ERRFMT, _host, AT_ERRPARAM];
	else
		return [OFString stringWithFormat:
		    @"An address could not be translated! " ERRFMT,
		    AT_ERRPARAM];
}

- (OFString*)host
{
	OF_GETTER(_host, true)
}

- (OFTCPSocket*)socket
{
	OF_GETTER(_socket, true)
}

- (int)errNo
{
#ifdef _WIN32
	return of_wsaerr_to_errno(_errNo);
#else
	return _errNo;
#endif
}
@end
