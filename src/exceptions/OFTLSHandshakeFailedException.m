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
