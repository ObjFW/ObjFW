/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
@synthesize host = _host, addressFamily = _addressFamily, error = _error;

+ (instancetype)exceptionWithHost: (OFString *)host
		    addressFamily: (OFSocketAddressFamily)addressFamily
			    error: (of_dns_resolver_error_t)error
{
	return [[[self alloc] initWithHost: host
			     addressFamily: addressFamily
				     error: error] autorelease];
}

- (instancetype)initWithHost: (OFString *)host
	       addressFamily: (OFSocketAddressFamily)addressFamily
		       error: (of_dns_resolver_error_t)error
{
	self = [super init];

	@try {
		_host = [host copy];
		_addressFamily = addressFamily;
		_error = error;
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
	    @"The host %@ could not be resolved: %@",
	    _host, of_dns_resolver_error_to_string(_error)];
}
@end
