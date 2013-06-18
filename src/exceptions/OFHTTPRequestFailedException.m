/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <stdlib.h>

#import "OFHTTPRequestFailedException.h"
#import "OFString.h"
#import "OFHTTPRequest.h"
#import "OFHTTPRequestReply.h"

#import "common.h"

@implementation OFHTTPRequestFailedException
+ (instancetype)exceptionWithRequest: (OFHTTPRequest*)request
			       reply: (OFHTTPRequestReply*)reply
{
	return [[[self alloc] initWithRequest: request
					reply: reply] autorelease];
}

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- initWithRequest: (OFHTTPRequest*)request
	    reply: (OFHTTPRequestReply*)reply
{
	self = [super init];

	_request = [request retain];
	_reply = [reply retain];

	return self;
}

- (void)dealloc
{
	[_request release];
	[_reply release];

	[super dealloc];
}

- (OFString*)description
{
	const char *type = "(unknown)";

	switch ([_request requestType]) {
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

	return [OFString stringWithFormat:
	    @"A HTTP %s request with URL %@ failed with code %d!", type,
	    [_request URL], [_reply statusCode]];
}

- (OFHTTPRequest*)request
{
	OF_GETTER(_request, false)
}

- (OFHTTPRequestReply*)reply
{
	OF_GETTER(_reply, false)
}
@end
