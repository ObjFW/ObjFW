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

#include <string.h>

#import "OFHTTPRequest.h"
#import "OFString.h"
#import "OFURL.h"
#import "OFTCPSocket.h"
#import "OFDictionary.h"
#import "OFAutoreleasePool.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"

#import "macros.h"

Class of_http_request_tls_socket_class = Nil;

@implementation OFHTTPRequest
+ request
{
	return [[[self alloc] init] autorelease];
}

+ requestWithURL: (OFURL*)url
{
	return [[[self alloc] initWithURL: url] autorelease];
}

- init
{
	self = [super init];

	requestType = OF_HTTP_REQUEST_TYPE_GET;
	headers = [[OFDictionary alloc]
	    initWithObject: @"Something using ObjFW "
			    @"<https://webkeks.org/objfw/>"
		    forKey: @"User-Agent"];

	return self;
}

- initWithURL: (OFURL*)url
{
	self = [self init];

	@try {
		[self setURL: url];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[URL release];
	[queryString release];
	[headers release];

	[super dealloc];
}

- (void)setURL: (OFURL*)url
{
	OF_SETTER(URL, url, YES, YES)
}

- (OFURL*)URL
{
	OF_GETTER(URL, YES)
}

- (void)setRequestType: (of_http_request_type_t)type
{
	requestType = type;
}

- (of_http_request_type_t)requestType
{
	return requestType;
}

- (void)setQueryString: (OFString*)qs
{
	OF_SETTER(queryString, qs, YES, YES)
}

- (OFString*)queryString
{
	OF_GETTER(queryString, YES)
}

- (void)setHeaders: (OFDictionary*)headers_
{
	OF_SETTER(headers, headers_, YES, YES)
}

- (OFDictionary*)headers
{
	OF_GETTER(headers, YES)
}

- (void)setRedirectsFromHTTPSToHTTPAllowed: (BOOL)allowed
{
	redirectsFromHTTPSToHTTPAllowed = allowed;
}

- (BOOL)redirectsFromHTTPSToHTTPAllowed
{
	return redirectsFromHTTPSToHTTPAllowed;
}

- (OFHTTPRequestResult*)perform
{
	return [self performWithRedirects: 10];
}

- (OFHTTPRequestResult*)performWithRedirects: (size_t)redirects
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *scheme = [URL scheme];
	OFTCPSocket *sock;
	OFHTTPRequestResult *result;

	if (![scheme isEqual: @"http"] && ![scheme isEqual: @"https"])
		@throw [OFUnsupportedProtocolException newWithClass: isa
								URL: URL];

	if ([scheme isEqual: @"http"])
		sock = [OFTCPSocket socket];
	else {
		if (of_http_request_tls_socket_class == Nil)
			@throw [OFUnsupportedProtocolException
			    newWithClass: isa
				     URL: URL];

		sock = [[[of_http_request_tls_socket_class alloc] init]
		    autorelease];
	}

	@try {
		OFString *line, *path;
		OFMutableDictionary *s_headers;
		OFDataArray *data;
		OFEnumerator *enumerator;
		OFString *key;
		int status;
		const char *t = NULL;

		[sock connectToHost: [URL host]
			     onPort: [URL port]];

		/*
		 * Work around a bug with packet bisection in lighttpd when
		 * using HTTPS.
		 */
		[sock setBuffersWrites: YES];

		if (requestType == OF_HTTP_REQUEST_TYPE_GET)
			t = "GET";
		if (requestType == OF_HTTP_REQUEST_TYPE_HEAD)
			t = "HEAD";
		if (requestType == OF_HTTP_REQUEST_TYPE_POST)
			t = "POST";

		if ([(path = [URL path]) isEqual: @""])
			path = @"/";

		if ([URL query] != nil)
			[sock writeFormat: @"%s %@?%@ HTTP/1.0\r\n",
					   t, path, [URL query]];
		else
			[sock writeFormat: @"%s %@ HTTP/1.0\r\n", t, path];

		if ([URL port] == 80)
			[sock writeFormat: @"Host: %@\r\n", [URL host]];
		else
			[sock writeFormat: @"Host: %@:%d\r\n", [URL host],
					   [URL port]];

		enumerator = [headers keyEnumerator];

		while ((key = [enumerator nextObject]) != nil)
			[sock writeFormat: @"%@: %@\r\n",
					   key, [headers objectForKey: key]];

		if (requestType == OF_HTTP_REQUEST_TYPE_POST) {
			if ([headers objectForKey: @"Content-Type"] == nil)
				[sock writeString: @"Content-Type: "
				   @"application/x-www-form-urlencoded\r\n"];

			if ([headers objectForKey: @"Content-Length"] == nil)
				[sock writeFormat: @"Content-Length: %d\r\n",
				    [queryString cStringLength]];
		}

		[sock writeString: @"\r\n"];

		/* Work around a bug in lighttpd, see above */
		[sock flushWriteBuffer];
		[sock setBuffersWrites: NO];

		if (requestType == OF_HTTP_REQUEST_TYPE_POST)
			[sock writeString: queryString];

		/*
		 * We also need to check for HTTP/1.1 since Apache always
		 * declares the reply to be HTTP/1.1.
		 */
		line = [sock readLine];
		if (![line hasPrefix: @"HTTP/1.0 "] &&
		    ![line hasPrefix: @"HTTP/1.1 "])
			@throw [OFInvalidServerReplyException
			    newWithClass: isa];

		status = (int)[[line substringFromIndex: 9
						toIndex: 12] decimalValue];

		if (status != 200 && status != 301 && status != 302 &&
		    status != 303)
			@throw [OFHTTPRequestFailedException
			    newWithClass: isa
			     HTTPRequest: self
			      statusCode: status];

		s_headers = [OFMutableDictionary dictionary];

		while ((line = [sock readLine]) != nil) {
			OFString *key, *value;
			const char *line_c = [line cString], *tmp;

			if ([line isEqual: @""])
				break;

			if ((tmp = strchr(line_c, ':')) == NULL)
				@throw [OFInvalidServerReplyException
				    newWithClass: isa];

			key = [OFString stringWithCString: line_c
						   length: tmp - line_c];

			do {
				tmp++;
			} while (*tmp == ' ');

			value = [OFString stringWithCString: tmp];

			if ((redirects > 0 && (status == 301 || status == 302 ||
			    status == 303) && [key caseInsensitiveCompare:
			    @"Location"] == OF_ORDERED_SAME) &&
			    (redirectsFromHTTPSToHTTPAllowed ||
			    [scheme isEqual: @"http"] ||
			    ![value hasPrefix: @"http://"])) {
				OFURL *new;

				new = [[OFURL alloc] initWithString: value
						      relativeToURL: URL];
				[URL release];
				URL = new;

				if (status == 303) {
					requestType = OF_HTTP_REQUEST_TYPE_GET;
					[queryString release];
					queryString = nil;
				}

				[pool release];
				pool = nil;

				return [self performWithRedirects:
				    redirects - 1];
			}

			[s_headers setObject: value
				      forKey: key];
		}

		data = [sock readDataArrayTillEndOfStream];

		if ([s_headers objectForKey: @"Content-Length"] != nil) {
			intmax_t cl;

			cl = [[s_headers objectForKey: @"Content-Length"]
			    decimalValue];

			if (cl > SIZE_MAX)
				@throw [OFOutOfRangeException
				    newWithClass: isa];

			if (cl != [data count])
				@throw [OFTruncatedDataException
				    newWithClass: isa];
		}

		/*
		 * Class swizzle the dictionary to be immutable. We pass it as
		 * OFDictionary*, so it can't be modified anyway. But not
		 * swizzling it would create a real copy each time -[copy] is
		 * called.
		 */
		s_headers->isa = [OFDictionary class];

		result = [[OFHTTPRequestResult alloc]
		    initWithStatusCode: status
			       headers: s_headers
				  data: data];
	} @finally {
		[pool release];
	}

	return [result autorelease];
}
@end

@implementation OFHTTPRequestResult
- initWithStatusCode: (short)status
	     headers: (OFDictionary*)headers_
		data: (OFDataArray*)data_
{
	self = [super init];

	statusCode = status;
	data = [data_ retain];
	headers = [headers_ copy];

	return self;
}

- (void)dealloc
{
	[data release];
	[headers release];

	[super dealloc];
}

- (short)statusCode
{
	return statusCode;
}

- (OFDictionary*)headers
{
	return [[headers copy] autorelease];
}

- (OFDataArray*)data
{
	return [[data retain] autorelease];
}
@end
