/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
of_dns_resolver_error_to_string(of_dns_resolver_error_t error)
{
	switch (error) {
	case OF_DNS_RESOLVER_ERROR_TIMEOUT:
		return @"The query timed out.";
	case OF_DNS_RESOLVER_ERROR_CANCELED:
		return @"The query was canceled.";
	case OF_DNS_RESOLVER_ERROR_NO_RESULT:
		return @"No result for the specified host with the specified "
		    @"type and class.";
	case OF_DNS_RESOLVER_ERROR_SERVER_INVALID_FORMAT:
		return @"The server considered the query to be malformed.";
	case OF_DNS_RESOLVER_ERROR_SERVER_FAILURE:
		return @"The server was unable to process due to an internal "
		    @"error.";
	case OF_DNS_RESOLVER_ERROR_SERVER_NAME_ERROR:
		return @"The server returned an error that the domain does not "
		    @"exist.";
	case OF_DNS_RESOLVER_ERROR_SERVER_NOT_IMPLEMENTED:
		return @"The server does not have support for the requested "
		    @"query.";
	case OF_DNS_RESOLVER_ERROR_SERVER_REFUSED:
		return @"The server refused the query.";
	default:
		return @"Unknown error.";
	}
}

@implementation OFDNSQueryFailedException
@synthesize query = _query, error = _error;

+ (instancetype)exceptionWithQuery: (OFDNSQuery *)query
			     error: (of_dns_resolver_error_t)error
{
	return [[[self alloc] initWithQuery: query
				      error: error] autorelease];
}

- (instancetype)initWithQuery: (OFDNSQuery *)query
			error: (of_dns_resolver_error_t)error
{
	self = [super init];

	@try {
		_query = [query copy];
		_error = error;
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
	    _query, of_dns_resolver_error_to_string(_error)];
}
@end
