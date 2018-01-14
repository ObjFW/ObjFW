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

#include <stdlib.h>
#include <string.h>

#import "OFHTTPServer.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFNumber.h"
#import "OFTCPSocket.h"
#import "OFTimer.h"
#import "OFURL.h"

#import "OFAlreadyConnectedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFWriteFailedException.h"

#import "socket_helpers.h"

#define BUFFER_SIZE 1024

/*
 * FIXME: Key normalization replaces headers like "DNT" with "Dnt".
 * FIXME: Errors are not reported to the user.
 */

@interface OFHTTPServer ()
- (bool)of_socket: (OFTCPSocket *)sock
  didAcceptSocket: (OFTCPSocket *)clientSocket
	  context: (id)context
	exception: (id)exception;
@end

static const char *
statusCodeToString(short code)
{
	switch (code) {
	case 100:
		return "Continue";
	case 101:
		return "Switching Protocols";
	case 200:
		return "OK";
	case 201:
		return "Created";
	case 202:
		return "Accepted";
	case 203:
		return "Non-Authoritative Information";
	case 204:
		return "No Content";
	case 205:
		return "Reset Content";
	case 206:
		return "Partial Content";
	case 300:
		return "Multiple Choices";
	case 301:
		return "Moved Permanently";
	case 302:
		return "Found";
	case 303:
		return "See Other";
	case 304:
		return "Not Modified";
	case 305:
		return "Use Proxy";
	case 307:
		return "Temporary Redirect";
	case 400:
		return "Bad Request";
	case 401:
		return "Unauthorized";
	case 402:
		return "Payment Required";
	case 403:
		return "Forbidden";
	case 404:
		return "Not Found";
	case 405:
		return "Method Not Allowed";
	case 406:
		return "Not Acceptable";
	case 407:
		return "Proxy Authentication Required";
	case 408:
		return "Request Timeout";
	case 409:
		return "Conflict";
	case 410:
		return "Gone";
	case 411:
		return "Length Required";
	case 412:
		return "Precondition Failed";
	case 413:
		return "Request Entity Too Large";
	case 414:
		return "Request-URI Too Long";
	case 415:
		return "Unsupported Media Type";
	case 416:
		return "Requested Range Not Satisfiable";
	case 417:
		return "Expectation Failed";
	case 500:
		return "Internal Server Error";
	case 501:
		return "Not Implemented";
	case 502:
		return "Bad Gateway";
	case 503:
		return "Service Unavailable";
	case 504:
		return "Gateway Timeout";
	case 505:
		return "HTTP Version Not Supported";
	default:
		return NULL;
	}
}

static OF_INLINE OFString *
normalizedKey(OFString *key)
{
	char *cString = of_strdup([key UTF8String]);
	unsigned char *tmp = (unsigned char *)cString;
	bool firstLetter = true;

	if (cString == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: strlen([key UTF8String])];

	while (*tmp != '\0') {
		if (!of_ascii_isalpha(*tmp)) {
			firstLetter = true;
			tmp++;
			continue;
		}

		*tmp = (firstLetter
		    ? of_ascii_toupper(*tmp)
		    : of_ascii_tolower(*tmp));

		firstLetter = false;
		tmp++;
	}

	return [OFString stringWithUTF8StringNoCopy: cString
				       freeWhenDone: true];
}

@interface OFHTTPServerResponse: OFHTTPResponse <OFReadyForWritingObserving>
{
	OFTCPSocket *_socket;
	OFHTTPServer *_server;
	OFHTTPRequest *_request;
	bool _chunked, _headersSent;
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			server: (OFHTTPServer *)server
		       request: (OFHTTPRequest *)request;
@end

@implementation OFHTTPServerResponse
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			server: (OFHTTPServer *)server
		       request: (OFHTTPRequest *)request
{
	self = [super init];

	_statusCode = 500;
	_socket = [sock retain];
	_server = [server retain];
	_request = [request retain];

	return self;
}

- (void)dealloc
{
	if (_socket != nil)
		[self close];	/* includes [_socket release] */

	[_server release];
	[_request release];

	[super dealloc];
}

- (void)of_sendHeaders
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *headers;
	OFEnumerator *keyEnumerator, *valueEnumerator;
	OFString *key, *value;

	[_socket writeFormat: @"HTTP/%@ %d %s\r\n",
			      [self protocolVersionString], _statusCode,
			      statusCodeToString(_statusCode)];

	headers = [[_headers mutableCopy] autorelease];

	if ([headers objectForKey: @"Date"] == nil) {
		OFString *date = [[OFDate date]
		    dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"];

		[headers setObject: date
			    forKey: @"Date"];
	}

	if ([headers objectForKey: @"Server"] == nil) {
		OFString *name = [_server name];

		if (name != nil)
			[headers setObject: name
				    forKey: @"Server"];
	}

	keyEnumerator = [headers keyEnumerator];
	valueEnumerator = [headers objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (value = [valueEnumerator nextObject]) != nil)
		[_socket writeFormat: @"%@: %@\r\n", key, value];

	[_socket writeString: @"\r\n"];

	_headersSent = true;
	_chunked = [[headers objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];

	objc_autoreleasePoolPop(pool);
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length
{
	/* TODO: Use non-blocking writes */

	void *pool;

	if (_socket == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!_headersSent)
		[self of_sendHeaders];

	if (!_chunked)
		return [_socket writeBuffer: buffer
				     length: length];

	pool = objc_autoreleasePoolPush();
	[_socket writeString: [OFString stringWithFormat: @"%zx\r\n", length]];
	objc_autoreleasePoolPop(pool);

	[_socket writeBuffer: buffer
		      length: length];
	[_socket writeBuffer: "\r\n"
		      length: 2];

	return length;
}

- (void)close
{
	if (_socket == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	@try {
		if (!_headersSent)
			[self of_sendHeaders];

		if (_chunked)
			[_socket writeBuffer: "0\r\n\r\n"
				      length: 5];
	} @catch (OFWriteFailedException *e) {
		id <OFHTTPServerDelegate> delegate = [_server delegate];

		if ([delegate respondsToSelector: @selector(server:
		  didReceiveExceptionForResponse:request:exception:)])
			[delegate		    server: _server
			    didReceiveExceptionForResponse: self
						   request: _request
						 exception: e];
	}

	[_socket release];
	_socket = nil;

	[super close];
}

- (int)fileDescriptorForWriting
{
	if (_socket == nil)
		return -1;

	return [_socket fileDescriptorForWriting];
}
@end

@interface OFHTTPServer_Connection: OFObject
{
	OFTCPSocket *_socket;
	OFHTTPServer *_server;
	OFTimer *_timer;
	enum {
		AWAITING_PROLOG,
		PARSING_HEADERS,
		SEND_RESPONSE
	} _state;
	uint8_t _HTTPMinorVersion;
	of_http_request_method_t _method;
	OFString *_host, *_path;
	uint16_t _port;
	OFMutableDictionary *_headers;
	size_t _contentLength;
	OFMutableData *_body;
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			server: (OFHTTPServer *)server;
- (bool)socket: (OFTCPSocket *)sock
   didReadLine: (OFString *)line
       context: (id)context
     exception: (id)exception;
- (bool)parseProlog: (OFString *)line;
- (bool)parseHeaders: (OFString *)line;
-      (bool)socket: (OFTCPSocket *)sock
  didReadIntoBuffer: (char *)buffer
	     length: (size_t)length
	    context: (id)context
	  exception: (id)exception;
- (bool)sendErrorAndClose: (short)statusCode;
- (void)createResponse;
@end

@implementation OFHTTPServer_Connection
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			server: (OFHTTPServer *)server
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_server = [server retain];
		_timer = [[OFTimer
		    scheduledTimerWithTimeInterval: 10
					    target: _socket
					  selector: @selector(
							cancelAsyncRequests)
					   repeats: false] retain];
		_state = AWAITING_PROLOG;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_socket release];
	[_server release];

	[_timer invalidate];
	[_timer release];

	[_host release];
	[_path release];
	[_headers release];
	[_body release];

	[super dealloc];
}

- (bool)socket: (OFTCPSocket *)sock
   didReadLine: (OFString *)line
       context: (id)context
     exception: (id)exception
{
	if (line == nil || exception != nil)
		return false;

	@try {
		switch (_state) {
		case AWAITING_PROLOG:
			return [self parseProlog: line];
		case PARSING_HEADERS:
			if (![self parseHeaders: line])
				return false;

			if (_state == SEND_RESPONSE) {
				[self createResponse];
				return false;
			}

			return true;
		default:
			return false;
		}
	} @catch (OFWriteFailedException *e) {
		return false;
	}

	OF_ENSURE(0);
}

- (bool)parseProlog: (OFString *)line
{
	OFString *method;
	OFMutableString *path;
	size_t pos;

	@try {
		OFString *version = [line
		    substringWithRange: of_range([line length] - 9, 9)];
		of_unichar_t tmp;

		if (![version hasPrefix: @" HTTP/1."])
			return [self sendErrorAndClose: 505];

		tmp = [version characterAtIndex: 8];
		if (tmp < '0' || tmp > '9')
			return [self sendErrorAndClose: 400];

		_HTTPMinorVersion = (uint8_t)(tmp - '0');
	} @catch (OFOutOfRangeException *e) {
		return [self sendErrorAndClose: 400];
	}

	pos = [line rangeOfString: @" "].location;
	if (pos == OF_NOT_FOUND)
		return [self sendErrorAndClose: 400];

	method = [line substringWithRange: of_range(0, pos)];
	@try {
		_method = of_http_request_method_from_string(
		    [method UTF8String]);
	} @catch (OFInvalidFormatException *e) {
		return [self sendErrorAndClose: 405];
	}

	@try {
		of_range_t range = of_range(pos + 1, [line length] - pos - 10);

		path = [[[line substringWithRange:
		    range] mutableCopy] autorelease];
	} @catch (OFOutOfRangeException *e) {
		return [self sendErrorAndClose: 400];
	}

	[path deleteEnclosingWhitespaces];
	[path makeImmutable];

	if (![path hasPrefix: @"/"])
		return [self sendErrorAndClose: 400];

	_headers = [[OFMutableDictionary alloc] init];
	_path = [path copy];
	_state = PARSING_HEADERS;

	return true;
}

- (bool)parseHeaders: (OFString *)line
{
	OFString *key, *value, *old;
	size_t pos;

	if ([line length] == 0) {
		intmax_t contentLength;

		@try {
			contentLength = [[_headers
			    objectForKey: @"Content-Length"] decimalValue];
		} @catch (OFInvalidFormatException *e) {
			return [self sendErrorAndClose: 400];
		}

		if (contentLength > 0) {
			char *buffer;

			if (contentLength < 0 ||
			    (uintmax_t)contentLength > SIZE_MAX)
				@throw [OFOutOfRangeException exception];

			buffer = [self allocMemoryWithSize: BUFFER_SIZE];
			_body = [[OFMutableData alloc] init];
			_contentLength = contentLength;

			[_socket asyncReadIntoBuffer: buffer
					      length: BUFFER_SIZE
					      target: self
					    selector: @selector(socket:
							  didReadIntoBuffer:
							  length:context:
							  exception:)
					     context: nil];
			[_timer setFireDate:
			    [OFDate dateWithTimeIntervalSinceNow: 5]];

			return false;
		}

		_state = SEND_RESPONSE;
		return true;
	}

	pos = [line rangeOfString: @":"].location;
	if (pos == OF_NOT_FOUND)
		return [self sendErrorAndClose: 400];

	key = [line substringWithRange: of_range(0, pos)];
	value = [line substringWithRange:
	    of_range(pos + 1, [line length] - pos - 1)];

	key = normalizedKey([key stringByDeletingTrailingWhitespaces]);
	value = [value stringByDeletingLeadingWhitespaces];

	old = [_headers objectForKey: key];
	if (old != nil)
		value = [old stringByAppendingFormat: @",%@", value];

	[_headers setObject: value
		     forKey: key];

	if ([key isEqual: @"Host"]) {
		pos = [value
		    rangeOfString: @":"
			  options: OF_STRING_SEARCH_BACKWARDS].location;

		if (pos != OF_NOT_FOUND) {
			[_host release];
			_host = [[value substringWithRange:
			    of_range(0, pos)] retain];

			@try {
				of_range_t range =
				    of_range(pos + 1, [value length] - pos - 1);
				intmax_t portTmp = [[value
				    substringWithRange: range] decimalValue];

				if (portTmp < 1 || portTmp > UINT16_MAX)
					return [self sendErrorAndClose: 400];

				_port = (uint16_t)portTmp;
			} @catch (OFInvalidFormatException *e) {
				return [self sendErrorAndClose: 400];
			}
		} else {
			[_host release];
			_host = [value retain];
			_port = 80;
		}
	}

	return true;
}

-      (bool)socket: (OFTCPSocket *)sock
  didReadIntoBuffer: (char *)buffer
	     length: (size_t)length
	    context: (id)context
	  exception: (id)exception
{
	if ([sock isAtEndOfStream] || exception != nil)
		return false;

	[_body addItems: buffer
		  count: length];

	if ([_body count] >= _contentLength) {
		/*
		 * Manually free the buffer here. While this is not required
		 * now as the async read is the only thing referencing self and
		 * the buffer is allocated on self, it is required once
		 * Connection: keep-alive is implemented.
		 */
		[self freeMemory: buffer];

		[_body makeImmutable];

		@try {
			[self createResponse];
		} @catch (OFWriteFailedException *e) {
			return false;
		}

		return false;
	}

	[_timer setFireDate: [OFDate dateWithTimeIntervalSinceNow: 5]];

	return true;
}

- (bool)sendErrorAndClose: (short)statusCode
{
	OFString *date = [[OFDate date]
	    dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"];

	[_socket writeFormat: @"HTTP/1.1 %d %s\r\n"
			      @"Date: %@\r\n"
			      @"Server: %@\r\n"
			      @"\r\n",
			      statusCode, statusCodeToString(statusCode),
			      date, [_server name]];

	return false;
}

- (void)createResponse
{
	OFMutableURL *URL;
	OFHTTPRequest *request;
	OFHTTPServerResponse *response;
	size_t pos;

	[_timer invalidate];
	[_timer release];
	_timer = nil;

	if (_host == nil || _port == 0) {
		if (_HTTPMinorVersion > 0) {
			[self sendErrorAndClose: 400];
			return;
		}

		[_host release];
		_host = [[_server host] retain];
		_port = [_server port];
	}

	URL = [OFMutableURL URL];
	[URL setScheme: @"http"];
	[URL setHost: _host];
	if (_port != 80)
		[URL setPort: [OFNumber numberWithUInt16: _port]];

	if ((pos = [_path rangeOfString: @"?"].location) != OF_NOT_FOUND) {
		OFString *path, *query;

		path = [_path substringWithRange: of_range(0, pos)];
		query = [_path substringWithRange:
		    of_range(pos + 1, [_path length] - pos - 1)];

		[URL setURLEncodedPath: path];
		[URL setURLEncodedQuery: query];
	} else
		[URL setURLEncodedPath: _path];

	[URL makeImmutable];

	request = [OFHTTPRequest requestWithURL: URL];
	[request setMethod: _method];
	[request setProtocolVersion:
	    (of_http_request_protocol_version_t){ 1, _HTTPMinorVersion }];
	[request setHeaders: _headers];
	[request setBody: _body];
	[request setRemoteAddress: [_socket remoteAddress]];

	response = [[[OFHTTPServerResponse alloc]
	    initWithSocket: _socket
		    server: _server
		   request: request] autorelease];

	[[_server delegate] server: _server
		 didReceiveRequest: request
			  response: response];
}
@end

@implementation OFHTTPServer
@synthesize host = _host, port = _port, delegate = _delegate, name = _name;

+ (instancetype)server
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	_name = @"OFHTTPServer (ObjFW's HTTP server class "
	    @"<https://heap.zone/objfw/>)";

	return self;
}

- (void)dealloc
{
	[_host release];
	[_listeningSocket release];
	[_name release];

	[super dealloc];
}

- (void)start
{
	if (_host == nil)
		@throw [OFInvalidArgumentException exception];

	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	_listeningSocket = [[OFTCPSocket alloc] init];
	_port = [_listeningSocket bindToHost: _host
					port: _port];
	[_listeningSocket listen];

	[_listeningSocket asyncAcceptWithTarget: self
				       selector: @selector(of_socket:
						     didAcceptSocket:context:
						     exception:)
					context: nil];
}

- (void)stop
{
	[_listeningSocket cancelAsyncRequests];
	[_listeningSocket release];
	_listeningSocket = nil;
}

- (bool)of_socket: (OFTCPSocket *)sock
  didAcceptSocket: (OFTCPSocket *)clientSocket
	  context: (id)context
	exception: (id)exception
{
	OFHTTPServer_Connection *connection;

	if (exception != nil) {
		if ([_delegate respondsToSelector:
		    @selector(server:didReceiveExceptionOnListeningSocket:)])
			return [_delegate		  server: self
			    didReceiveExceptionOnListeningSocket: exception];

		return false;
	}

	connection = [[[OFHTTPServer_Connection alloc]
	    initWithSocket: clientSocket
		    server: self] autorelease];

	[clientSocket asyncReadLineWithTarget: connection
				     selector: @selector(socket:didReadLine:
						  context:exception:)
				      context: nil];

	return true;
}
@end
