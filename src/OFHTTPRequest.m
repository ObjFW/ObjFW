/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#define OF_HTTP_REQUEST_M

#include <string.h>
#include <ctype.h>

#import "OFHTTPRequest.h"
#import "OFString.h"
#import "OFURL.h"
#import "OFTCPSocket.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFAutoreleasePool.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFUnsupportedVersionException.h"

#import "macros.h"

Class of_http_request_tls_socket_class = Nil;

static OF_INLINE void
normalizeKey(OFString *key)
{
	uint8_t *str = (uint8_t*)[key UTF8String];
	BOOL firstLetter = YES;

	while (*str != '\0') {
		if (!isalnum(*str)) {
			firstLetter = YES;
			str++;
			continue;
		}

		*str = (firstLetter ? toupper(*str) : tolower(*str));

		firstLetter = NO;
		str++;
	}
}

@implementation OFHTTPRequest
+ request
{
	return [[[self alloc] init] autorelease];
}

+ requestWithURL: (OFURL*)URL
{
	return [[[self alloc] initWithURL: URL] autorelease];
}

- init
{
	self = [super init];

	requestType = OF_HTTP_REQUEST_TYPE_GET;
	headers = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"Connection", @"close",
	    @"User-Agent", @"Something using ObjFW "
			   @"<https://webkeks.org/objfw/>", nil];
	storesData = YES;

	return self;
}

- initWithURL: (OFURL*)URL_
{
	self = [self init];

	@try {
		[self setURL: URL_];
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

- (void)setURL: (OFURL*)URL_
{
	OF_SETTER(URL, URL_, YES, 1)
}

- (OFURL*)URL
{
	OF_GETTER(URL, YES)
}

- (void)setRequestType: (of_http_request_type_t)requestType_
{
	requestType = requestType_;
}

- (of_http_request_type_t)requestType
{
	return requestType;
}

- (void)setQueryString: (OFString*)queryString_
{
	OF_SETTER(queryString, queryString_, YES, 1)
}

- (OFString*)queryString
{
	OF_GETTER(queryString, YES)
}

- (void)setHeaders: (OFDictionary*)headers_
{
	OF_SETTER(headers, headers_, YES, 1)
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

- (void)setDelegate: (id <OFHTTPRequestDelegate>)delegate_
{
	delegate = delegate_;
}

- (id <OFHTTPRequestDelegate>)delegate
{
	return delegate;
}

- (void)setStoresData: (BOOL)storesData_
{
	storesData = storesData_;
}

- (BOOL)storesData
{
	return storesData;
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
	OFString *line, *path, *version;
	OFMutableDictionary *serverHeaders;
	OFDataArray *data;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFString *key, *object, *contentLengthHeader;
	int status;
	const char *type = NULL;
	size_t contentLength = 0;
	BOOL chunked;
	char *buffer;
	size_t bytesReceived;

	if (![scheme isEqual: @"http"] && ![scheme isEqual: @"https"])
		@throw [OFUnsupportedProtocolException
		    exceptionWithClass: [self class]
				   URL: URL];

	if ([scheme isEqual: @"http"])
		sock = [OFTCPSocket socket];
	else {
		if (of_http_request_tls_socket_class == Nil)
			@throw [OFUnsupportedProtocolException
			    exceptionWithClass: [self class]
					   URL: URL];

		sock = [[[of_http_request_tls_socket_class alloc] init]
		    autorelease];
	}

	[delegate request: self
	  didCreateSocket: sock];

	[sock connectToHost: [URL host]
		       port: [URL port]];

	/*
	 * Work around a bug with packet bisection in lighttpd when using
	 * HTTPS.
	 */
	[sock setWriteBufferEnabled: YES];

	if (requestType == OF_HTTP_REQUEST_TYPE_GET)
		type = "GET";
	if (requestType == OF_HTTP_REQUEST_TYPE_HEAD)
		type = "HEAD";
	if (requestType == OF_HTTP_REQUEST_TYPE_POST)
		type = "POST";

	if ([(path = [URL path]) isEqual: @""])
		path = @"/";

	if ([URL query] != nil)
		[sock writeFormat: @"%s %@?%@ HTTP/1.1\r\n",
		    type, path, [URL query]];
	else
		[sock writeFormat: @"%s %@ HTTP/1.1\r\n", type, path];

	if ([URL port] == 80)
		[sock writeFormat: @"Host: %@\r\n", [URL host]];
	else
		[sock writeFormat: @"Host: %@:%d\r\n", [URL host],
		    [URL port]];

	keyEnumerator = [headers keyEnumerator];
	objectEnumerator = [headers objectEnumerator];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil)
		[sock writeFormat: @"%@: %@\r\n", key, object];

	if (requestType == OF_HTTP_REQUEST_TYPE_POST) {
		if ([headers objectForKey: @"Content-Type"] == nil)
			[sock writeString: @"Content-Type: "
			    @"application/x-www-form-urlencoded; "
			    @"charset=UTF-8\r\n"];

		if ([headers objectForKey: @"Content-Length"] == nil)
			[sock writeFormat: @"Content-Length: %d\r\n",
			    [queryString UTF8StringLength]];
	}

	[sock writeString: @"\r\n"];

	/* Work around a bug in lighttpd, see above */
	[sock flushWriteBuffer];
	[sock setWriteBufferEnabled: NO];

	if (requestType == OF_HTTP_REQUEST_TYPE_POST)
		[sock writeString: queryString];

	@try {
		line = [sock readLine];
	} @catch (OFInvalidEncodingException *e) {
		@throw [OFInvalidServerReplyException
		    exceptionWithClass: [self class]];
	}

	if (![line hasPrefix: @"HTTP/"] || [line characterAtIndex: 8] != ' ')
		@throw [OFInvalidServerReplyException
		    exceptionWithClass: [self class]];

	version = [line substringWithRange: of_range(5, 3)];
	if (![version isEqual: @"1.0"] && ![version isEqual: @"1.1"])
		@throw [OFUnsupportedVersionException
		    exceptionWithClass: [self class]
			       version: version];

	status = (int)[[line substringWithRange: of_range(9, 3)] decimalValue];

	serverHeaders = [OFMutableDictionary dictionary];

	for (;;) {
		OFString *key, *value;
		const char *line_c, *tmp;

		@try {
			line = [sock readLine];
		} @catch (OFInvalidEncodingException *e) {
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];
		}

		if (line == nil)
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];

		if ([line isEqual: @""])
			break;

		line_c = [line UTF8String];

		if ((tmp = strchr(line_c, ':')) == NULL)
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];

		key = [OFString stringWithUTF8String: line_c
					      length: tmp - line_c];
		normalizeKey(key);

		do {
			tmp++;
		} while (*tmp == ' ');

		value = [OFString stringWithUTF8String: tmp];

		if ((redirects > 0 && (status == 301 || status == 302 ||
		    status == 303 || status == 307) &&
		    [key isEqual: @"Location"]) &&
		    (redirectsFromHTTPSToHTTPAllowed ||
		    [scheme isEqual: @"http"] ||
		    ![value hasPrefix: @"http://"])) {
			OFURL *new;
			BOOL follow;

			new = [OFURL URLWithString: value
				     relativeToURL: URL];

			follow = [delegate request: self
			      willFollowRedirectTo: new];

			if (!follow && delegate != nil) {
				[serverHeaders setObject: value
						  forKey: key];
				continue;
			}

			new = [new retain];
			[URL release];
			URL = new;

			if (status == 303) {
				requestType = OF_HTTP_REQUEST_TYPE_GET;
				[queryString release];
				queryString = nil;
			}

			[pool release];

			return [self performWithRedirects: redirects - 1];
		}

		[serverHeaders setObject: value
				  forKey: key];
	}

	[delegate request: self
	didReceiveHeaders: serverHeaders
	   withStatusCode: status];

	data = (storesData ? [OFDataArray dataArray] : nil);
	chunked = [[serverHeaders objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];

	contentLengthHeader = [serverHeaders objectForKey: @"Content-Length"];

	if (contentLengthHeader != nil) {
		contentLength = (size_t)[contentLengthHeader decimalValue];

		if (contentLength > SIZE_MAX)
			@throw [OFOutOfRangeException
			    exceptionWithClass: [self class]];
	}

	buffer = [self allocMemoryWithSize: of_pagesize];
	bytesReceived = 0;
	@try {
		OFAutoreleasePool *pool2 = [[OFAutoreleasePool alloc] init];

		if (chunked) {
			for (;;) {
				size_t pos, toRead;

				@try {
					line = [sock readLine];
				} @catch (OFInvalidEncodingException *e) {
					@throw [OFInvalidServerReplyException
					    exceptionWithClass: [self class]];
				}

				pos = [line
				    indexOfFirstOccurrenceOfString: @";"];
				if (pos != OF_INVALID_INDEX)
					line = [line substringWithRange:
					    of_range(0, pos)];

				@try {
					toRead =
					    (size_t)[line hexadecimalValue];
				} @catch (OFInvalidFormatException *e) {
					@throw [OFInvalidServerReplyException
					    exceptionWithClass: [self class]];
				}

				if (toRead == 0 ||
				    (contentLengthHeader != nil &&
				    contentLength >= bytesReceived))
					break;

				while (toRead > 0) {
					size_t length = (toRead < of_pagesize
					    ? toRead : of_pagesize);

					length = [sock readIntoBuffer: buffer
							       length: length];

					[delegate request: self
					   didReceiveData: buffer
					       withLength: length];
					[pool2 releaseObjects];

					bytesReceived += length;
					[data addItemsFromCArray: buffer
							   count: length];

					toRead -= length;
				}

				@try {
					line = [sock readLine];
				} @catch (OFInvalidEncodingException *e) {
					@throw [OFInvalidServerReplyException
					    exceptionWithClass: [self class]];
				}

				if (![line isEqual: @""])
					@throw [OFInvalidServerReplyException
					    exceptionWithClass: [self class]];

				[pool2 releaseObjects];
			}
		} else {
			size_t length;

			while ((length = [sock
			    readIntoBuffer: buffer
				    length: of_pagesize]) > 0) {
				[delegate request: self
				   didReceiveData: buffer
				       withLength: length];
				[pool2 releaseObjects];

				bytesReceived += length;
				[data addItemsFromCArray: buffer
						   count: length];

				if (contentLengthHeader != nil &&
				    bytesReceived >= contentLength)
					break;
			}
		}

		[pool2 release];
	} @finally {
		[self freeMemory: buffer];
	}

	[sock close];

	/*
	 * We only want to throw on these status codes as we will throw an
	 * OFHTTPRequestFailedException for all other status codes later.
	 */
	if (contentLengthHeader != nil && contentLength != bytesReceived &&
	    (status == 200 || status == 301 || status == 302 || status == 303 ||
	    status == 307))
		@throw [OFTruncatedDataException
		    exceptionWithClass: [self class]];

	[serverHeaders makeImmutable];

	result = [[OFHTTPRequestResult alloc] initWithStatusCode: status
							 headers: serverHeaders
							    data: data];

	switch (status) {
	case 200:
	case 301:
	case 302:
	case 303:
	case 307:
		break;
	default:
		[result release];
		@throw [OFHTTPRequestFailedException
		    exceptionWithClass: [self class]
			   HTTPRequest: self
				result: result];
	}

	[pool release];

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

@implementation OFObject (OFHTTPRequestDelegate)
-   (void)request: (OFHTTPRequest*)request
  didCreateSocket: (OFTCPSocket*)socket
{
}

-     (void)request: (OFHTTPRequest*)request
  didReceiveHeaders: (OFDictionary*)headers
     withStatusCode: (int)statusCode
{
}

-  (void)request: (OFHTTPRequest*)request
  didReceiveData: (const char*)data
      withLength: (size_t)len
{
}

-	 (BOOL)request: (OFHTTPRequest*)request
  willFollowRedirectTo: (OFURL*)url
{
	return YES;
}
@end
