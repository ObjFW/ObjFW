/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFResolveHostFailedException.h"
#import "OFString.h"

@implementation OFResolveHostFailedException
@synthesize host = _host, recordClass = _recordClass, recordType = _recordType;
@synthesize error = _error;

+ (instancetype)exceptionWithHost: (OFString *)host
		      recordClass: (of_dns_resource_record_class_t)recordClass
		       recordType: (of_dns_resource_record_type_t)recordType
			    error: (of_dns_resolver_error_t)error
{
	return [[[self alloc] initWithHost: host
			       recordClass: recordClass
				recordType: recordType
				     error: error] autorelease];
}

- (instancetype)initWithHost: (OFString *)host
		 recordClass: (of_dns_resource_record_class_t)recordClass
		  recordType: (of_dns_resource_record_type_t)recordType
		       error: (of_dns_resolver_error_t)error
{
	self = [super init];

	@try {
		_host = [host copy];
		_recordClass = recordClass;
		_recordType = recordType;
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
	OFString *error;

	switch (_error) {
	case OF_DNS_RESOLVER_ERROR_TIMEOUT:
		error = @"The query timed out.";
		break;
	case OF_DNS_RESOLVER_ERROR_CANCELED:
		error = @"The query was canceled.";
		break;
	case OF_DNS_RESOLVER_ERROR_NO_RESULT:
		error = @"No result for the specified host with the specified "
		    @"type and class.";
		break;
	case OF_DNS_RESOLVER_ERROR_SERVER_INVALID_FORMAT:
		error = @"The server considered the query to be malformed.";
		break;
	case OF_DNS_RESOLVER_ERROR_SERVER_FAILURE:
		error = @"The server was unable to process due to an internal "
		    @"error.";
		break;
	case OF_DNS_RESOLVER_ERROR_SERVER_NAME_ERROR:
		error = @"The server returned an error that the domain does "
		    @"not exist.";
		break;
	case OF_DNS_RESOLVER_ERROR_SERVER_NOT_IMPLEMENTED:
		error = @"The server does not have support for the requested "
		    @"query.";
	case OF_DNS_RESOLVER_ERROR_SERVER_REFUSED:
		error = @"The server refused the query.";
		break;
	default:
		error = @"Unknown error.";
		break;
	}

	return [OFString stringWithFormat:
	    @"The host %@ could not be resolved: %@", _host, error];
}
@end
