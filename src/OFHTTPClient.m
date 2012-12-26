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
#import "OFSystemInfo.h"

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

@implementation OFHTTPClient
+ (instancetype)client
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	storesData = YES;

	return self;
}

- (void)setDelegate: (id <OFHTTPClientDelegate>)delegate_
{
	delegate = delegate_;
}

- (id <OFHTTPClientDelegate>)delegate
{
	return delegate;
}

- (void)setInsecureRedirectsAllowed: (BOOL)allowed
{
	insecureRedirectsAllowed = allowed;
}

- (BOOL)insecureRedirectsAllowed
{
	return insecureRedirectsAllowed;
}

- (void)setStoresData: (BOOL)storesData_
{
	storesData = storesData_;
}

- (BOOL)storesData
{
	return storesData;
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
	OFTCPSocket *sock;
	OFHTTPRequestReply *reply;
	OFString *line, *path, *version;
	OFMutableDictionary *serverHeaders;
	OFDataArray *data;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	OFString *key, *object, *contentLengthHeader;
	int status;
	const char *type = NULL;
	size_t contentLength = 0;
	BOOL chunked;
	size_t pageSize;
	char *buffer;
	size_t bytesReceived;

	if (![scheme isEqual: @"http"] && ![scheme isEqual: @"https"])
		@throw [OFUnsupportedProtocolException
		    exceptionWithClass: [self class]
				   URL: URL];

	if ([scheme isEqual: @"http"])
		sock = [OFTCPSocket socket];
	else {
		if (of_tls_socket_class == Nil)
			@throw [OFUnsupportedProtocolException
			    exceptionWithClass: [self class]
					   URL: URL];

		sock = [[[of_tls_socket_class alloc] init] autorelease];
	}

	if ([delegate respondsToSelector:
	    @selector(client:didCreateSocket:request:)])
		[delegate client: self
		 didCreateSocket: sock
			 request: request];

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

	[sock writeString: @"Connection: close\r\n"];

	if ([headers objectForKey: @"User-Agent"] == nil)
		[sock writeString: @"User-Agent: Something using ObjFW "
				   @"<https://webkeks.org/objfw>\r\n"];

	keyEnumerator = [headers keyEnumerator];
	objectEnumerator = [headers objectEnumerator];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil)
		[sock writeFormat: @"%@: %@\r\n", key, object];

	if (requestType == OF_HTTP_REQUEST_TYPE_POST) {
		OFString *contentType = [request MIMEType];

		if (contentType == nil)
			contentType = @"application/x-www-form-urlencoded; "
			    @"charset=UTF-8\r\n";

		[sock writeFormat: @"Content-Type: %@\r\n", contentType];
		[sock writeFormat: @"Content-Length: %d\r\n",
		    [POSTData count] * [POSTData itemSize]];
	}

	[sock writeString: @"\r\n"];

	/* Work around a bug in lighttpd, see above */
	[sock flushWriteBuffer];
	[sock setWriteBufferEnabled: NO];

	if (requestType == OF_HTTP_REQUEST_TYPE_POST)
		[sock writeBuffer: [POSTData items]
			   length: [POSTData count] * [POSTData itemSize]];

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
		const char *lineC, *tmp;
		char *keyC;

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
						      freeWhenDone: YES];
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
		    [key isEqual: @"Location"]) && (insecureRedirectsAllowed ||
		    [scheme isEqual: @"http"] ||
		    ![value hasPrefix: @"http://"])) {
			OFURL *newURL;
			OFHTTPRequest *newRequest;
			BOOL follow = YES;

			newURL = [OFURL URLWithString: value
					relativeToURL: URL];

			if ([delegate respondsToSelector:
			    @selector(client:shouldFollowRedirect:request:)])
				follow = [delegate client: self
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

	if ([delegate respondsToSelector:
	    @selector(client:didReceiveHeaders:statusCode:request:)])
		[delegate      client: self
		    didReceiveHeaders: serverHeaders
			   statusCode: status
			      request: request];

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

	pageSize = [OFSystemInfo pageSize];
	buffer = [self allocMemoryWithSize: pageSize];
	bytesReceived = 0;
	@try {
		if (chunked) {
			for (;;) {
				void *pool2 = objc_autoreleasePoolPush();
				size_t toRead;
				of_range_t range;

				@try {
					line = [sock readLine];
				} @catch (OFInvalidEncodingException *e) {
					@throw [OFInvalidServerReplyException
					    exceptionWithClass: [self class]];
				}

				range = [line rangeOfString: @";"];
				if (range.location != OF_NOT_FOUND)
					line = [line substringWithRange:
					    of_range(0, range.location)];

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
					size_t length = (toRead < pageSize
					    ? toRead : pageSize);

					length = [sock readIntoBuffer: buffer
							       length: length];

					if ([delegate respondsToSelector:
					    @selector(client:didReceiveData:
					    length:request:)])
						[delegate client: self
						  didReceiveData: buffer
							  length: length
							 request: request];

					objc_autoreleasePoolPop(pool2);
					pool2 = objc_autoreleasePoolPush();

					bytesReceived += length;
					[data addItems: buffer
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

				objc_autoreleasePoolPop(pool2);
			}
		} else {
			size_t length;

			while (![sock isAtEndOfStream]) {
				void *pool2;

				length = [sock readIntoBuffer: buffer
						       length: pageSize];

				pool2 = objc_autoreleasePoolPush();

				if ([delegate respondsToSelector:
				    @selector(client:didReceiveData:length:
				    request:)])
					[delegate client: self
					  didReceiveData: buffer
						  length: length
						 request: request];

				objc_autoreleasePoolPop(pool2);

				bytesReceived += length;
				[data addItems: buffer
					 count: length];

				if (contentLengthHeader != nil &&
				    bytesReceived >= contentLength)
					break;
			}
		}
	} @finally {
		[self freeMemory: buffer];
	}

	[sock close];

	/*
	 * We only want to throw on status code 200 as we will throw an
	 * OFHTTPRequestFailedException for all other status codes later.
	 */
	if (status == 200 && contentLengthHeader != nil &&
	    contentLength != bytesReceived)
		@throw [OFTruncatedDataException
		    exceptionWithClass: [self class]];

	[serverHeaders makeImmutable];

	reply = [[OFHTTPRequestReply alloc] initWithStatusCode: status
						       headers: serverHeaders
							  data: data];

	objc_autoreleasePoolPop(pool);

	[reply autorelease];

	if (status != 200)
		@throw [OFHTTPRequestFailedException
		    exceptionWithClass: [self class]
			       request: request
				 reply: reply];

	return reply;
}
@end
