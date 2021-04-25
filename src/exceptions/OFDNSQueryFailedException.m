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

#import "OFDNSQueryFailedException.h"
#import "OFString.h"

OFString *
OFDNSResolverErrorCodeDescription(OFDNSResolverErrorCode errorCode)
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
	return [[[self alloc] initWithQuery: query
				  errorCode: errorCode] autorelease];
}

- (instancetype)initWithQuery: (OFDNSQuery *)query
		    errorCode: (OFDNSResolverErrorCode)errorCode
{
	self = [super init];

	@try {
		_query = [query copy];
		_errorCode = errorCode;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_query release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"DNS query %@ could not be performed: %@",
	    _query, OFDNSResolverErrorCodeDescription(_errorCode)];
}
@end
