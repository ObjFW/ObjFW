/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFHTTPRequestFailedException.h"
#import "OFString.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"

@implementation OFHTTPRequestFailedException
@synthesize request = _request, response = _response;

+ (instancetype)exceptionWithRequest: (OFHTTPRequest *)request
			    response: (OFHTTPResponse *)response
{
	return [[[self alloc] initWithRequest: request
				     response: response] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithRequest: (OFHTTPRequest *)request
	 response: (OFHTTPResponse *)response
{
	self = [super init];

	_request = [request retain];
	_response = [response retain];

	return self;
}

- (void)dealloc
{
	[_request release];
	[_response release];

	[super dealloc];
}

- (OFString *)description
{
	const char *method =
	    of_http_request_method_to_string([_request method]);

	return [OFString stringWithFormat:
	    @"An HTTP %s request with URL %@ failed with code %d!", method,
	    [_request URL], [_response statusCode]];
}
@end
