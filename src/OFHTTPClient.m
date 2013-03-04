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

#include <string.h>
#include <ctype.h>

#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPRequestReply.h"
#import "OFString.h"
#import "OFURL.h"
#import "OFTCPSocket.h"
#import "OFDictionary.h"
#import "OFDataArray.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFUnsupportedVersionException.h"

#import "autorelease.h"
#import "macros.h"

static OF_INLINE void
normalize_key(char *str_)
{
	uint8_t *str = (uint8_t*)str_;
	bool firstLetter = true;

	while (*str != '\0') {
		if (!isalnum(*str)) {
			firstLetter = true;
			str++;
			continue;
		}

		*str = (firstLetter ? toupper(*str) : tolower(*str));

		firstLetter = false;
		str++;
	}
}

@interface OFHTTPClientReply: OFHTTPRequestReply
{
	OFTCPSocket *_socket;
	bool _chunked, _atEndOfStream;
	size_t _toRead;
}

- initWithSocket: (OFTCPSocket*)socket;
@end

@implementation OFHTTPClientReply
- initWithSocket: (OFTCPSocket*)socket
{
	self = [super init];

	_socket = [socket retain];

	return self;
}

- (void)dealloc
{
	[_socket release];

	[super dealloc];
}

- (void)setHeaders: (OFDictionary*)headers
{
	[super setHeaders: headers];

	_chunked = [[headers objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	if (!_chunked)
		return [_socket readIntoBuffer: buffer
					length: length];

	if (_toRead > 0) {
		if (length > _toRead)
			length = _toRead;

		length = [_socket readIntoBuffer: buffer
					  length: length];

		_toRead -= length;

		if (_toRead == 0)
			if ([[_socket readLine] length] > 0)
				@throw [OFInvalidServerReplyException
				    exceptionWithClass: [self class]];

		return length;
	} else {
		void *pool = objc_autoreleasePoolPush();
		OFString *line;
		of_range_t range;

		@try {
			line = [_socket readLine];
		} @catch (OFInvalidEncodingException *e) {
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];
		}

		range = [line rangeOfString: @";"];
		if (range.location != OF_NOT_FOUND)
			line = [line substringWithRange:
			    of_range(0, range.location)];

		@try {
			_toRead =
			    (size_t)[line hexadecimalValue];
		} @catch (OFInvalidFormatException *e) {
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];
		}

		if (_toRead == 0) {
			[_socket close];
			_atEndOfStream = true;
		}

		objc_autoreleasePoolPop(pool);

		return 0;
	}
}

- (bool)lowlevelIsAtEndOfStream
{
	if (!_chunked)
		return [_socket isAtEndOfStream];

	return _atEndOfStream;
}

- (int)fileDescriptorForReading
{
	return [_socket fileDescriptorForReading];
}

- (size_t)numberOfBytesInReadBuffer
{
	return [super numberOfBytesInReadBuffer] +
	    [_socket numberOfBytesInReadBuffer];
}

- (void)close
{
	[_socket close];
}
@end

@implementation OFHTTPClient
+ (instancetype)client
{
	return [[[self alloc] init] autorelease];
}

- (void)setDelegate: (id <OFHTTPClientDelegate>)delegate
{
	_delegate = delegate;
}

- (id <OFHTTPClientDelegate>)delegate
{
	return _delegate;
}

- (void)setInsecureRedirectsAllowed: (bool)allowed
{
	_insecureRedirectsAllowed = allowed;
}

- (bool)insecureRedirectsAllowed
{
	return _insecureRedirectsAllowed;
}

- (OFHTTPRequestReply*)performRequest: (OFHTTPRequest*)request
{
	return [self performRequest: request
			  redirects: 10];
}

- (OFHTTPRequestReply*)performRequest: (OFHTTPRequest*)request
			    redirects: (size_t)redirects
{
	void *pool = objc_autoreleasePoolPush();
	OFURL *URL = [request URL];
	OFString *scheme = [URL scheme];
	of_http_request_type_t requestType = [request requestType];
	OFDictionary *headers = [request headers];
	OFDataArray *POSTData = [request POSTData];
	OFTCPSocket *socket;
	OFHTTPClientReply *reply;
	OFString *line, *path, *version;
	OFMutableDictionary *serverHeaders;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFString *key, *object;
	int status;
	const char *type = NULL;

	if (![scheme isEqual: @"http"] && ![scheme isEqual: @"https"])
		@throw [OFUnsupportedProtocolException
		    exceptionWithClass: [self class]
				   URL: URL];

	if ([scheme isEqual: @"http"])
		socket = [OFTCPSocket socket];
	else {
		if (of_tls_socket_class == Nil)
			@throw [OFUnsupportedProtocolException
			    exceptionWithClass: [self class]
					   URL: URL];

		socket = [[[of_tls_socket_class alloc] init] autorelease];
	}

	if ([_delegate respondsToSelector:
	    @selector(client:didCreateSocket:request:)])
		[_delegate client: self
		  didCreateSocket: socket
			  request: request];

	[socket connectToHost: [URL host]
			 port: [URL port]];

	/*
	 * Work around a bug with packet splitting in lighttpd when using
	 * HTTPS.
	 */
	[socket setWriteBufferEnabled: true];

	if (requestType == OF_HTTP_REQUEST_TYPE_GET)
		type = "GET";
	if (requestType == OF_HTTP_REQUEST_TYPE_HEAD)
		type = "HEAD";
	if (requestType == OF_HTTP_REQUEST_TYPE_POST)
		type = "POST";

	if ([(path = [URL path]) length] == 0)
		path = @"/";

	if ([URL query] != nil)
		[socket writeFormat: @"%s %@?%@ HTTP/%@\r\n",
		    type, path, [URL query], [request protocolVersionString]];
	else
		[socket writeFormat: @"%s %@ HTTP/%@\r\n",
		    type, path, [request protocolVersionString]];

	if ([URL port] == 80)
		[socket writeFormat: @"Host: %@\r\n", [URL host]];
	else
		[socket writeFormat: @"Host: %@:%d\r\n", [URL host],
		    [URL port]];

	[socket writeString: @"Connection: close\r\n"];

	if ([headers objectForKey: @"User-Agent"] == nil)
		[socket writeString: @"User-Agent: Something using ObjFW "
				     @"<https://webkeks.org/objfw>\r\n"];

	keyEnumerator = [headers keyEnumerator];
	objectEnumerator = [headers objectEnumerator];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil)
		[socket writeFormat: @"%@: %@\r\n", key, object];

	if (requestType == OF_HTTP_REQUEST_TYPE_POST) {
		OFString *contentType = [request MIMEType];

		if (contentType == nil)
			contentType = @"application/x-www-form-urlencoded; "
			    @"charset=UTF-8\r\n";

		[socket writeFormat: @"Content-Type: %@\r\n", contentType];
		[socket writeFormat: @"Content-Length: %d\r\n",
		    [POSTData count] * [POSTData itemSize]];
	}

	[socket writeString: @"\r\n"];

	/* Work around a bug in lighttpd, see above */
	[socket flushWriteBuffer];
	[socket setWriteBufferEnabled: false];

	if (requestType == OF_HTTP_REQUEST_TYPE_POST)
		[socket writeBuffer: [POSTData items]
			     length: [POSTData count] * [POSTData itemSize]];

	@try {
		line = [socket readLine];
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
		const char *lineC, *tmp;
		char *keyC;

		@try {
			line = [socket readLine];
		} @catch (OFInvalidEncodingException *e) {
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];
		}

		if (line == nil)
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];

		if ([line length] == 0)
			break;

		lineC = [line UTF8String];

		if ((tmp = strchr(lineC, ':')) == NULL)
			@throw [OFInvalidServerReplyException
			    exceptionWithClass: [self class]];

		if ((keyC = malloc(tmp - lineC + 1)) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithClass: [self class]
				 requestedSize: tmp - lineC + 1];

		memcpy(keyC, lineC, tmp - lineC);
		keyC[tmp - lineC] = '\0';
		normalize_key(keyC);

		@try {
			key = [OFString stringWithUTF8StringNoCopy: keyC
						      freeWhenDone: true];
		} @catch (id e) {
			free(keyC);
			@throw e;
		}

		do {
			tmp++;
		} while (*tmp == ' ');

		value = [OFString stringWithUTF8String: tmp];

		if ((redirects > 0 && (status == 301 || status == 302 ||
		    status == 303 || status == 307) &&
		    [key isEqual: @"Location"]) && (_insecureRedirectsAllowed ||
		    [scheme isEqual: @"http"] ||
		    ![value hasPrefix: @"http://"])) {
			OFURL *newURL;
			OFHTTPRequest *newRequest;
			bool follow = true;

			newURL = [OFURL URLWithString: value
					relativeToURL: URL];

			if ([_delegate respondsToSelector:
			    @selector(client:shouldFollowRedirect:request:)])
				follow = [_delegate client: self
				      shouldFollowRedirect: newURL
						   request: request];

			if (!follow) {
				[serverHeaders setObject: value
						  forKey: key];
				continue;
			}

			newRequest = [OFHTTPRequest requestWithURL: newURL];
			[newRequest setRequestType: requestType];
			[newRequest setHeaders: headers];
			[newRequest setPOSTData: POSTData];
			[newRequest setMIMEType: [request MIMEType]];

			if (status == 303) {
				[newRequest
				    setRequestType: OF_HTTP_REQUEST_TYPE_GET];
				[newRequest setPOSTData: nil];
				[newRequest setMIMEType: nil];
			}

			[newRequest retain];
			objc_autoreleasePoolPop(pool);
			[newRequest autorelease];

			return [self performRequest: newRequest
					  redirects: redirects - 1];
		}

		[serverHeaders setObject: value
				  forKey: key];
	}

	[serverHeaders makeImmutable];

	if ([_delegate respondsToSelector:
	    @selector(client:didReceiveHeaders:statusCode:request:)])
		[_delegate     client: self
		    didReceiveHeaders: serverHeaders
			   statusCode: status
			      request: request];

	reply = [[OFHTTPClientReply alloc] initWithSocket: socket];
	[reply setProtocolVersionFromString: version];
	[reply setStatusCode: status];
	[reply setHeaders: serverHeaders];

	objc_autoreleasePoolPop(pool);

	[reply autorelease];

	if (status / 100 != 2)
		@throw [OFHTTPRequestFailedException
		    exceptionWithClass: [self class]
			       request: request
				 reply: reply];

	return reply;
}
@end
