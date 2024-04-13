/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFTLSHandshakeFailedException.h"
#import "OFString.h"

int _OFTLSHandshakeFailedException_reference;

@implementation OFTLSHandshakeFailedException
@synthesize stream = _stream, host = _host, errorCode = _errorCode;

+ (instancetype)exceptionWithStream: (OFTLSStream *)stream
			       host: (OFString *)host
			  errorCode: (OFTLSStreamErrorCode)errorCode
{
	return [[[self alloc] initWithStream: stream
					host: host
				   errorCode: errorCode] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithStream: (OFTLSStream *)stream
			  host: (OFString *)host
		     errorCode: (OFTLSStreamErrorCode)errorCode
{
	self = [super init];

	@try {
		_stream = [stream retain];
		_host = [host copy];
		_errorCode = errorCode;
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
	[_stream release];
	[_host release];

	[super dealloc];
}

- (OFString *)description
{
	if (_host != nil)
		return [OFString stringWithFormat:
		    @"TLS handshake in class %@ with host %@ failed: %@",
		    _stream.class, _host,
		    OFTLSStreamErrorCodeDescription(_errorCode)];
	else
		return [OFString stringWithFormat:
		    @"TLS handshake in class %@ failed: %@",
		    _stream.class, OFTLSStreamErrorCodeDescription(_errorCode)];
}
@end
