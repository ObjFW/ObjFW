/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithHost: host
			 addressFamily: addressFamily
			     errorCode: errorCode]);
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
		objc_release(self);
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
	objc_release(_host);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"The host %@ could not be resolved: %@",
	    _host, _OFDNSResolverErrorCodeDescription(_errorCode)];
}
@end
