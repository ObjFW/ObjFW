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

#import "OFHTTPServer.h"
#import "OFDataArray.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFURL.h"
#import "OFHTTPRequest.h"
#import "OFHTTPRequestReply.h"
#import "OFTCPSocket.h"
#import "OFTimer.h"

#import "OFAlreadyConnectedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFWriteFailedException.h"

#import "macros.h"

#define BUFFER_SIZE 1024

/*
 * TODO: Add support for chunked transfer encoding.
 * FIXME: Key normalization replaces headers like "DNT" with "Dnt".
 * FIXME: Errors are not reported to the user.
 */

static const char*
status_code_to_string(short code)
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

static OF_INLINE OFString*
normalized_key(OFString *key)
{
	char *cString = strdup([key UTF8String]);
	uint8_t *tmp = (uint8_t*)cString;
	BOOL firstLetter = YES;

	if (cString == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithClass: nil
			 requestedSize: strlen([key UTF8String])];

	while (*tmp != '\0') {
		if (!isalnum(*tmp)) {
			firstLetter = YES;
			tmp++;
			continue;
		}

		*tmp = (firstLetter ? toupper(*tmp) : tolower(*tmp));

		firstLetter = NO;
		tmp++;
	}

	return [OFString stringWithUTF8StringNoCopy: cString
				       freeWhenDone: YES];
}

@interface OFHTTPServer_Connection: OFObject
{
	OFTCPSocket *sock;
	OFHTTPServer *server;
	OFTimer *timer;
	enum {
		AWAITING_PROLOG,
		PARSING_HEADERS,
		SEND_REPLY
	} state;
	uint8_t HTTPMinorVersion;
	of_http_request_type_t requestType;
	OFString *host, *path;
	uint16_t port;
	OFMutableDictionary *headers;
	size_t contentLength;
	OFDataArray *POSTData;
}

- initWithSocket: (OFTCPSocket*)socket
	  server: (OFHTTPServer*)server;
- (BOOL)socket: (OFTCPSocket*)sock
   didReadLine: (OFString*)line
     exception: (OFException*)exception;
- (BOOL)parseProlog: (OFString*)line;
- (BOOL)parseHeaders: (OFString*)line;
-      (BOOL)socket: (OFTCPSocket*)sock
  didReadIntoBuffer: (const char*)buffer
	     length: (size_t)length
	  exception: (OFException*)exception;
- (BOOL)sendErrorAndClose: (short)statusCode;
- (void)sendReply;
@end

@implementation OFHTTPServer_Connection
- initWithSocket: (OFTCPSocket*)sock_
	  server: (OFHTTPServer*)server_
{
	self = [super init];

	@try {
		sock = [sock_ retain];
		server = [server_ retain];
		timer = [[OFTimer
		    scheduledTimerWithTimeInterval: 10
					    target: sock
					  selector: @selector(
							cancelAsyncRequests)
					   repeats: NO] retain];
		state = AWAITING_PROLOG;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[sock release];
	[server release];

	[timer invalidate];
	[timer release];

	[host release];
	[path release];
	[headers release];
	[POSTData release];

	[super dealloc];
}

- (BOOL)socket: (OFTCPSocket*)sock_
   didReadLine: (OFString*)line
     exception: (OFException*)exception
{
	if (line == nil || exception != nil)
		return NO;

	@try {
		switch (state) {
		case AWAITING_PROLOG:
			return [self parseProlog: line];
		case PARSING_HEADERS:
			if (![self parseHeaders: line])
				return NO;

			if (state == SEND_REPLY) {
				[self sendReply];
				return NO;
			}

			return YES;
		default:
			return NO;
		}
	} @catch (OFWriteFailedException *e) {
		return NO;
	}
}

- (BOOL)parseProlog: (OFString*)line
{
	OFString *type;
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

		HTTPMinorVersion = (uint8_t)(tmp - '0');
	} @catch (OFOutOfRangeException *e) {
		return [self sendErrorAndClose: 400];
	}

	pos = [line rangeOfString: @" "].location;
	if (pos == OF_NOT_FOUND)
		return [self sendErrorAndClose: 400];

	type = [line substringWithRange: of_range(0, pos)];
	if ([type isEqual: @"GET"])
		requestType = OF_HTTP_REQUEST_TYPE_GET;
	else if ([type isEqual: @"POST"])
		requestType = OF_HTTP_REQUEST_TYPE_POST;
	else if ([type isEqual: @"HEAD"])
		requestType = OF_HTTP_REQUEST_TYPE_HEAD;
	else
		return [self sendErrorAndClose: 501];

	@try {
		path = [line substringWithRange:
		    of_range(pos + 1, [line length] - pos - 10)];
	} @catch (OFOutOfRangeException *e) {
		return [self sendErrorAndClose: 400];
	}
	path = [[path stringByDeletingEnclosingWhitespaces] retain];

	if (![path hasPrefix: @"/"])
		return [self sendErrorAndClose: 400];

	headers = [[OFMutableDictionary alloc] init];
	state = PARSING_HEADERS;

	return YES;
}

- (BOOL)parseHeaders: (OFString*)line
{
	OFString *key, *value;
	size_t pos;

	if ([line isEqual: @""]) {
		switch (requestType) {
		case OF_HTTP_REQUEST_TYPE_GET:
		case OF_HTTP_REQUEST_TYPE_HEAD:
			state = SEND_REPLY;
			break;
		case OF_HTTP_REQUEST_TYPE_POST:;
			OFString *tmp;
			char *buffer;

			tmp = [headers objectForKey: @"Content-Length"];
			if (tmp == nil)
				return [self sendErrorAndClose: 411];

			@try {
				contentLength = (size_t)[tmp decimalValue];
			} @catch (OFInvalidFormatException *e) {
				return [self sendErrorAndClose: 400];
			}

			buffer = [self allocMemoryWithSize: BUFFER_SIZE];
			POSTData = [[OFDataArray alloc] init];

			[sock asyncReadIntoBuffer: buffer
					   length: BUFFER_SIZE
					   target: self
					 selector: @selector(socket:
						       didReadIntoBuffer:
						       length:exception:)];
			[timer setFireDate:
			    [OFDate dateWithTimeIntervalSinceNow: 5]];

			return NO;
		}

		return YES;
	}

	pos = [line rangeOfString: @":"].location;
	if (pos == OF_NOT_FOUND)
		return [self sendErrorAndClose: 400];

	key = [line substringWithRange: of_range(0, pos)];
	value = [line substringWithRange:
	    of_range(pos + 1, [line length] - pos - 1)];

	key = normalized_key([key stringByDeletingTrailingWhitespaces]);
	value = [value stringByDeletingLeadingWhitespaces];

	[headers setObject: value
		    forKey: key];

	if ([key isEqual: @"Host"]) {
		pos = [value
		    rangeOfString: @":"
			  options: OF_STRING_SEARCH_BACKWARDS].location;

		if (pos != OF_NOT_FOUND) {
			[host release];
			host = [[value substringWithRange:
			    of_range(0, pos)] retain];

			@try {
				of_range_t range =
				    of_range(pos + 1, [value length] - pos - 1);
				intmax_t portTmp = [[value
				    substringWithRange: range] decimalValue];

				if (portTmp < 1 || portTmp > UINT16_MAX)
					return [self sendErrorAndClose: 400];

				port = (uint16_t)portTmp;
			} @catch (OFInvalidFormatException *e) {
				return [self sendErrorAndClose: 400];
			}
		} else {
			[host release];
			host = [value retain];
			port = 80;
		}
	}

	return YES;
}

-      (BOOL)socket: (OFTCPSocket*)sock_
  didReadIntoBuffer: (const char*)buffer
	     length: (size_t)length
	  exception: (OFException*)exception
{
	if ([sock_ isAtEndOfStream] || exception != nil)
		return NO;

	[POSTData addItems: buffer
		     count: length];

	if ([POSTData count] >= contentLength) {
		@try {
			[self sendReply];
		} @catch (OFWriteFailedException *e) {
			return NO;
		}

		return NO;
	}

	[timer setFireDate: [OFDate dateWithTimeIntervalSinceNow: 5]];

	return YES;
}

- (BOOL)sendErrorAndClose: (short)statusCode
{
	OFString *date = [[OFDate date]
	    dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"];

	[sock writeFormat: @"HTTP/1.1 %d %s\r\n"
			   @"Date: %@\r\n"
			   @"Server: %@\r\n"
			   @"\r\n",
			   statusCode, status_code_to_string(statusCode), date,
			   [server name]];
	[sock close];

	return NO;
}

- (void)sendReply
{
	OFURL *URL;
	OFHTTPRequest *request;
	OFHTTPRequestReply *reply;
	OFDictionary *replyHeaders;
	OFDataArray *replyData;
	OFEnumerator *keyEnumerator, *valueEnumerator;
	OFString *key, *value;
	size_t pos;

	[timer invalidate];
	[timer release];
	timer = nil;

	if (host == nil || port == 0) {
		if (HTTPMinorVersion > 0) {
			[self sendErrorAndClose: 400];
			return;
		}

		host = [[server host] retain];
		port = [server port];
	}

	URL = [OFURL URL];
	[URL setScheme: @"http"];
	[URL setHost: host];
	[URL setPort: port];

	if ((pos = [path rangeOfString: @"?"].location) != OF_NOT_FOUND) {
		OFString *path_, *query;

		path_ = [path substringWithRange: of_range(0, pos)];
		query = [path substringWithRange:
		    of_range(pos + 1, [path length] - pos - 1)];

		[URL setPath: path_];
		[URL setQuery: query];
	} else
		[URL setPath: path];

	request = [OFHTTPRequest requestWithURL: URL];
	[request setRequestType: requestType];
	[request setHeaders: headers];
	[request setPOSTData: POSTData];
	[request setRemoteAddress: [sock remoteAddress]];

	reply = [[server delegate] server: server
			didReceiveRequest: request];

	if (reply == nil) {
		[self sendErrorAndClose: 500];
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [(id)[server delegate] class]
			      selector: @selector(server:didReceiveRequest:)];
	}

	replyHeaders = [reply headers];
	replyData = [reply data];

	[sock writeFormat: @"HTTP/1.1 %d %s\r\n"
			   @"Server: %@\r\n",
			   [reply statusCode],
			   status_code_to_string([reply statusCode]),
			   [server name]];

	if ([replyHeaders objectForKey: @"Date"] == nil) {
		OFString *date = [[OFDate date]
		    dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"];
		[sock writeFormat: @"Date: %@\r\n", date];
	}

	if (requestType != OF_HTTP_REQUEST_TYPE_HEAD)
		[sock writeFormat: @"Content-Length: %zu\r\n",
				   [replyData count] * [replyData itemSize]];

	keyEnumerator = [replyHeaders keyEnumerator];
	valueEnumerator = [replyHeaders objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (value = [valueEnumerator nextObject]) != nil)
		[sock writeFormat: @"%@: %@\r\n", key, value];

	[sock writeString: @"\r\n"];

	if (requestType != OF_HTTP_REQUEST_TYPE_HEAD)
		[sock writeBuffer: [replyData items]
			   length: [replyData count] * [replyData itemSize]];
}
@end

@implementation OFHTTPServer
+ (instancetype)server
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	name = @"OFHTTPServer (ObjFW's HTTP server class "
	    @"<https://webkeks.org/objfw/>)";

	return self;
}

- (void)dealloc
{
	[host release];
	[listeningSocket release];
	[name release];

	[super dealloc];
}

- (void)setHost: (OFString*)host_
{
	OF_SETTER(host, host_, YES, 1)
}

- (OFString*)host
{
	OF_GETTER(host, YES)
}

- (void)setPort: (uint16_t)port_
{
	port = port_;
}

- (uint16_t)port
{
	return port;
}

- (void)setDelegate: (id <OFHTTPServerDelegate>)delegate_
{
	delegate = delegate_;
}

- (id <OFHTTPServerDelegate>)delegate
{
	return delegate;
}

- (void)setName: (OFString*)name_
{
	OF_SETTER(name, name_, YES, 1)
}

- (OFString*)name
{
	OF_GETTER(name, YES)
}

- (void)start
{
	if (host == nil || port == 0)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	if (listeningSocket != nil)
		@throw [OFAlreadyConnectedException
		    exceptionWithClass: [self class]
				socket: listeningSocket];

	listeningSocket = [[OFTCPSocket alloc] init];
	[listeningSocket bindToHost: host
			       port: port];
	[listeningSocket listen];

	[listeningSocket asyncAcceptWithTarget: self
				      selector: @selector(OF_socket:
						    didAcceptSocket:
						    exception:)];
}

- (void)stop
{
	[listeningSocket cancelAsyncRequests];
	[listeningSocket release];
	listeningSocket = nil;
}

- (BOOL)OF_socket: (OFTCPSocket*)socket
  didAcceptSocket: (OFTCPSocket*)clientSocket
	exception: (OFException*)exception
{
	OFHTTPServer_Connection *connection;

	if (exception != nil) {
		if ([delegate respondsToSelector:
		    @selector(server:didReceiveExceptionOnListeningSocket:)])
			return [delegate		  server: self
			    didReceiveExceptionOnListeningSocket: exception];

		return NO;
	}

	connection = [[[OFHTTPServer_Connection alloc]
	    initWithSocket: clientSocket
		    server: self] autorelease];

	[clientSocket asyncReadLineWithTarget: connection
				     selector: @selector(socket:didReadLine:
						  exception:)];

	return YES;
}
@end
