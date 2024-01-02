/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFResolveHostFailedException.h"
#import "OFDNSQueryFailedException.h"
#import "OFString.h"

@implementation OFResolveHostFailedException
@synthesize host = _host, addressFamily = _addressFamily;
@synthesize errorCode = _errorCode;

+ (instancetype)exceptionWithHost: (OFString *)host
		    addressFamily: (OFSocketAddressFamily)addressFamily
			errorCode: (OFDNSResolverErrorCode)errorCode
{
	return [[[self alloc] initWithHost: host
			     addressFamily: addressFamily
				 errorCode: errorCode] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithHost: (OFString *)host
	       addressFamily: (OFSocketAddressFamily)addressFamily
		   errorCode: (OFDNSResolverErrorCode)errorCode
{
	self = [super init];

	@try {
		_host = [host copy];
		_addressFamily = addressFamily;
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
	[_host release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The host %@ could not be resolved: %@",
	    _host, OFDNSResolverErrorCodeDescription(_errorCode)];
}
@end
