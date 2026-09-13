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

#import "OFDNSQueryFailedException.h"
#import "OFString.h"

OFString *
_OFDNSResolverErrorCodeDescription(OFDNSResolverErrorCode errorCode)
{
	switch (errorCode) {
	case OFDNSResolverErrorCodeTimeout:
		return @"The query timed out.";
	case OFDNSResolverErrorCodeCanceled:
		return @"The query was canceled.";
	case OFDNSResolverErrorCodeNoResult:
		return @"No result for the specified host with the specified "
		    @"type and class.";
	case OFDNSResolverErrorCodeServerInvalidFormat:
		return @"The server considered the query to be malformed.";
	case OFDNSResolverErrorCodeServerFailure:
		return @"The server was unable to process due to an internal "
		    @"error.";
	case OFDNSResolverErrorCodeServerNameError:
		return @"The server returned an error that the domain does not "
		    @"exist.";
	case OFDNSResolverErrorCodeServerNotImplemented:
		return @"The server does not have support for the requested "
		    @"query.";
	case OFDNSResolverErrorCodeServerRefused:
		return @"The server refused the query.";
	case OFDNSResolverErrorCodeNoNameServer:
		return @"There was no name server to query.";
	default:
		return @"Unknown error.";
	}
}

@implementation OFDNSQueryFailedException
@synthesize query = _query, errorCode = _errorCode;

+ (instancetype)exceptionWithQuery: (OFDNSQuery *)query
			 errorCode: (OFDNSResolverErrorCode)errorCode
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithQuery: query
			      errorCode: errorCode]);
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithQuery: (OFDNSQuery *)query
		    errorCode: (OFDNSResolverErrorCode)errorCode
{
	self = [super init];

	@try {
		_query = [query copy];
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
	objc_release(_query);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"DNS query %@ could not be performed: %@",
	    _query, _OFDNSResolverErrorCodeDescription(_errorCode)];
}
@end
