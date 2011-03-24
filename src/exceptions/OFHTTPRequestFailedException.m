/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

@implementation OFHTTPRequestFailedException
+ newWithClass: (Class)class_
   HTTPRequest: (OFHTTPRequest*)request
    statusCode: (short)code
{
	return [[self alloc] initWithClass: class_
			       HTTPRequest: request
				statusCode: code];
}

- initWithClass: (Class)class_
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithClass: (Class)class_
    HTTPRequest: (OFHTTPRequest*)request
     statusCode: (short)code
{
	self = [super initWithClass: class_];

	@try {
		HTTPRequest = [request retain];
		statusCode = code;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[HTTPRequest release];

	[super dealloc];
}

- (OFString*)description
{
	OFAutoreleasePool *pool;
	const char *type = "(unknown)";

	if (description != nil)
		return description;

	switch ([HTTPRequest requestType]) {
	case OF_HTTP_REQUEST_TYPE_GET:
		type = "GET";
		break;
	case OF_HTTP_REQUEST_TYPE_HEAD:
		type = "HEAD";
		break;
	case OF_HTTP_REQUEST_TYPE_POST:
		type = "POST";
		break;
	}

	pool = [[OFAutoreleasePool alloc] init];

	description = [[OFString alloc] initWithFormat:
	    @"A HTTP %s request in class %@ with URL %@ failed with code %d",
	    type, inClass, [HTTPRequest URL], statusCode];

	[pool release];

	return description;
}

- (OFHTTPRequest*)HTTPRequest
{
	return HTTPRequest;
}

- (short)statusCode
{
	return statusCode;
}
@end
