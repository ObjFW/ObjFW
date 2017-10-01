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

#define OF_HTTPCLIENT_M

#include "config.h"

#include <errno.h>
#include <string.h>

#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFString.h"
#import "OFURL.h"
#import "OFTCPSocket.h"
#import "OFDictionary.h"
#import "OFData.h"

#import "OFAlreadyConnectedException.h"
#import "OFHTTPRequestFailedException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFUnsupportedVersionException.h"
#import "OFWriteFailedException.h"

@interface OFHTTPClientRequestHandler: OFObject
{
	OFHTTPClient *_client;
	OFHTTPRequest *_request;
	unsigned int _redirects;
	id _context;
	bool _firstLine;
	OFString *_version;
	int _status;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *_serverHeaders;
}

- initWithClient: (OFHTTPClient *)client
	 request: (OFHTTPRequest *)request
       redirects: (unsigned int)redirects
	 context: (id)context;
- (void)start;
@end

@interface OFHTTPClientResponse: OFHTTPResponse
{
	OFTCPSocket *_socket;
	bool _hasContentLength, _chunked, _keepAlive, _atEndOfStream;
	size_t _toRead;
}

@property (nonatomic, setter=of_setKeepAlive:) bool of_keepAlive;

- initWithSocket: (OFTCPSocket *)socket;
@end

static OFString *
constructRequestString(OFHTTPRequest *request)
{
	void *pool = objc_autoreleasePoolPush();
	of_http_request_method_t method = [request method];
	OFURL *URL = [request URL];
	OFString *scheme = [URL scheme], *path = [URL path];
	OFString *user = [URL user], *password = [URL password];
	OFData *body = [request body];
	OFMutableString *requestString;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *headers;
	OFEnumerator OF_GENERIC(OFString *) *keyEnumerator, *objectEnumerator;
	OFString *key, *object;

	if (path == nil)
		path = @"/";

	requestString = [OFMutableString stringWithFormat:
	    @"%s %@", of_http_request_method_to_string(method), path];

	if ([URL query] != nil) {
		[requestString appendString: @"?"];
		[requestString appendString: [URL query]];
	}

	[requestString appendString: @" HTTP/"];
	[requestString appendString: [request protocolVersionString]];
	[requestString appendString: @"\r\n"];

	headers = [[[request headers] mutableCopy] autorelease];
	if (headers == nil)
		headers = [OFMutableDictionary dictionary];

	if ([headers objectForKey: @"Host"] == nil) {
		if (([scheme isEqual: @"http"] && [URL port] != 80) ||
		    ([scheme isEqual: @"https"] && [URL port] != 443)) {
			OFString *host = [OFString stringWithFormat:
			    @"%@:%d", [URL host], [URL port]];

			[headers setObject: host
				    forKey: @"Host"];
		} else
			[headers setObject: [URL host]
				    forKey: @"Host"];
	}

	if (([user length] > 0 || [password length] > 0) &&
	    [headers objectForKey: @"Authorization"] == nil) {
		OFMutableData *authorizationData = [OFMutableData data];
		OFString *authorization;

		[authorizationData addItems: [user UTF8String]
				      count: [user UTF8StringLength]];
		[authorizationData addItem: ":"];
		[authorizationData addItems: [password UTF8String]
				      count: [password UTF8StringLength]];

		authorization = [OFString stringWithFormat:
		    @"Basic %@", [authorizationData stringByBase64Encoding]];

		[headers setObject: authorization
			    forKey: @"Authorization"];
	}

	if ([headers objectForKey: @"User-Agent"] == nil)
		[headers setObject: @"Something using ObjFW "
				    @"<https://heap.zone/objfw>"
			    forKey: @"User-Agent"];

	if (body != nil) {
		if ([headers objectForKey: @"Content-Length"] == nil) {
			OFString *contentLength = [OFString stringWithFormat:
			    @"%zd", [body itemSize] * [body count]];

			[headers setObject: contentLength
				    forKey: @"Content-Length"];
		}

		if ([headers objectForKey: @"Content-Type"] == nil)
			[headers setObject: @"application/x-www-form-"
					    @"urlencoded; charset=UTF-8"
				    forKey: @"Content-Type"];
	}

	if ([request protocolVersion].major == 1 &&
	    [request protocolVersion].minor == 0 &&
	    [headers objectForKey: @"Connection"] == nil)
		[headers setObject: @"keep-alive"
			    forKey: @"Connection"];

	keyEnumerator = [headers keyEnumerator];
	objectEnumerator = [headers objectEnumerator];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil)
		[requestString appendFormat: @"%@: %@\r\n", key, object];

	[requestString appendString: @"\r\n"];

	[requestString retain];

	objc_autoreleasePoolPop(pool);

	return [requestString autorelease];
}

static OF_INLINE void
normalizeKey(char *str_)
{
	unsigned char *str = (unsigned char *)str_;
	bool firstLetter = true;

	while (*str != '\0') {
		if (!of_ascii_isalpha(*str)) {
			firstLetter = true;
			str++;
			continue;
		}

		*str = (firstLetter
		    ? of_ascii_toupper(*str)
		    : of_ascii_tolower(*str));

		firstLetter = false;
		str++;
	}
}

@implementation OFHTTPClientRequestHandler
- initWithClient: (OFHTTPClient *)client
	 request: (OFHTTPRequest *)request
       redirects: (unsigned int)redirects
	 context: (id)context
{
	self = [super init];

	@try {
		_client = [client retain];
		_request = [request retain];
		_redirects = redirects;
		_context = [context retain];
		_firstLine = true;
		_serverHeaders = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_client release];
	[_request release];
	[_context release];
	[_version release];
	[_serverHeaders release];

	[super dealloc];
}

- (void)closeAndReconnect
{
	OFURL *URL = [_request URL];
	OFTCPSocket *socket;

	[_client close];

	if ([[URL scheme] isEqual: @"https"]) {
		if (of_tls_socket_class == Nil)
			@throw [OFUnsupportedProtocolException
			    exceptionWithURL: URL];

		socket = [[[of_tls_socket_class alloc] init]
		    autorelease];
	} else
		socket = [OFTCPSocket socket];

	[socket asyncConnectToHost: [URL host]
			      port: [URL port]
			    target: self
			  selector: @selector(socketDidConnect:context:
					exception:)
			   context: nil];
}

- (void)createResponseWithSocket: (OFTCPSocket *)socket
{
	OFURL *URL = [_request URL];
	OFHTTPClientResponse *response;
	OFString *connectionHeader;
	bool keepAlive;
	OFString *location;

	response = [[[OFHTTPClientResponse alloc] initWithSocket: socket]
	    autorelease];
	[response setProtocolVersionFromString: _version];
	[response setStatusCode: _status];
	[response setHeaders: _serverHeaders];

	connectionHeader = [_serverHeaders objectForKey: @"Connection"];
	if ([_version isEqual: @"1.1"]) {
		if (connectionHeader != nil)
			keepAlive = ([connectionHeader caseInsensitiveCompare:
			    @"close"] != OF_ORDERED_SAME);
		else
			keepAlive = true;
	} else {
		if (connectionHeader != nil)
			keepAlive = ([connectionHeader caseInsensitiveCompare:
			    @"keep-alive"] == OF_ORDERED_SAME);
		else
			keepAlive = false;
	}

	if (keepAlive) {
		[response of_setKeepAlive: true];

		_client->_socket = [socket retain];
		_client->_lastURL = [URL copy];
		_client->_lastWasHEAD =
		    ([_request method] == OF_HTTP_REQUEST_METHOD_HEAD);
		_client->_lastResponse = [response retain];
	}

	/* FIXME: Case-insensitive check of redirect's scheme */
	if (_redirects > 0 && (_status == 301 || _status == 302 ||
	    _status == 303 || _status == 307) &&
	    (location = [_serverHeaders objectForKey: @"Location"]) != nil &&
	    (_client->_insecureRedirectsAllowed ||
	    [[URL scheme] isEqual: @"http"] ||
	    [location hasPrefix: @"https://"])) {
		OFURL *newURL;
		bool follow;

		newURL = [OFURL URLWithString: location
				relativeToURL: URL];

		if ([_client->_delegate respondsToSelector: @selector(client:
		    shouldFollowRedirect:statusCode:request:response:context:)])
			follow = [_client->_delegate client: _client
				       shouldFollowRedirect: newURL
						 statusCode: _status
						    request: _request
						   response: response
						    context: _context];
		else {
			of_http_request_method_t method = [_request method];

			/*
			 * 301, 302 and 307 should only redirect with user
			 * confirmation if the request method is not GET or
			 * HEAD. Asking the delegate and getting true returned
			 * is considered user confirmation.
			 */
			if (method == OF_HTTP_REQUEST_METHOD_GET ||
			    method == OF_HTTP_REQUEST_METHOD_HEAD)
				follow = true;
			/*
			 * 303 should always be redirected and converted to a
			 * GET request.
			 */
			else if (_status == 303)
				follow = true;
			else
				follow = false;
		}

		if (follow) {
			OFDictionary OF_GENERIC(OFString *, OFString *)
			    *headers = [_request headers];
			OFHTTPRequest *newRequest =
			    [[_request copy] autorelease];
			OFMutableDictionary *newHeaders =
			    [[headers mutableCopy] autorelease];

			if (![[newURL host] isEqual: [URL host]])
				[newHeaders removeObjectForKey: @"Host"];

			/*
			 * 303 means the request should be converted to a GET
			 * request before redirection. This also means stripping
			 * the entity of the request.
			 */
			if (_status == 303) {
				OFEnumerator *keyEnumerator, *objectEnumerator;
				id key, object;

				keyEnumerator = [headers keyEnumerator];
				objectEnumerator = [headers objectEnumerator];
				while ((key = [keyEnumerator nextObject]) !=
				    nil &&
				    (object = [objectEnumerator nextObject]) !=
				    nil)
					if ([key hasPrefix: @"Content-"])
						[newHeaders
						    removeObjectForKey: key];

				[newRequest setMethod:
				    OF_HTTP_REQUEST_METHOD_GET];
				[newRequest setBody: nil];
			}

			[newRequest setURL: newURL];
			[newRequest setHeaders: newHeaders];

			_client->_inProgress = false;

			[_client asyncPerformRequest: newRequest
					   redirects: _redirects - 1
					     context: _context];
			return;
		}
	}

	if (_status / 100 != 2)
		@throw [OFHTTPRequestFailedException
		    exceptionWithRequest: _request
				response: response];

	_client->_inProgress = false;

	[_client->_delegate performSelector: @selector(client:didPerformRequest:
						 response:context:)
				 withObject: _client
				 withObject: _request
				 withObject: response
				 withObject: _context
				 afterDelay: 0];
}

- (bool)handleFirstLine: (OFString *)line
{
	/*
	 * It's possible that the write succeeds on a connection that is
	 * keep-alive, but the connection has already been closed by the remote
	 * end due to a timeout. In this case, we need to reconnect.
	 */
	if (line == nil) {
		[self closeAndReconnect];
		return false;
	}

	if (![line hasPrefix: @"HTTP/"] || [line length] < 9 ||
	    [line characterAtIndex: 8] != ' ')
		@throw [OFInvalidServerReplyException exception];

	_version = [[line substringWithRange: of_range(5, 3)] copy];
	if (![_version isEqual: @"1.0"] && ![_version isEqual: @"1.1"])
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: _version];

	_status = (int)[[line substringWithRange: of_range(9, 3)] decimalValue];

	return true;
}

- (bool)handleServerHeader: (OFString *)line
		    socket: (OFTCPSocket *)socket
{
	OFString *key, *value, *old;
	const char *lineC, *tmp;
	char *keyC;

	if (line == nil)
		@throw [OFInvalidServerReplyException exception];

	if ([line length] == 0) {
		[_serverHeaders makeImmutable];

		if ([_client->_delegate respondsToSelector: @selector(client:
		    didReceiveHeaders:statusCode:request:context:)])
			[_client->_delegate client: _client
				 didReceiveHeaders: _serverHeaders
					statusCode: _status
					   request: _request
					   context: _context];

		[self performSelector: @selector(createResponseWithSocket:)
			   withObject: socket
			   afterDelay: 0];

		return false;
	}

	lineC = [line UTF8String];

	if ((tmp = strchr(lineC, ':')) == NULL)
		@throw [OFInvalidServerReplyException exception];

	if ((keyC = malloc(tmp - lineC + 1)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: tmp - lineC + 1];

	memcpy(keyC, lineC, tmp - lineC);
	keyC[tmp - lineC] = '\0';
	normalizeKey(keyC);

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

	old = [_serverHeaders objectForKey: key];
	if (old != nil)
		value = [old stringByAppendingFormat: @",%@", value];

	[_serverHeaders setObject: value
			   forKey: key];

	return true;
}

- (bool)socket: (OFTCPSocket *)socket
   didReadLine: (OFString *)line
       context: (id)context
     exception: (id)exception
{
	if (exception != nil) {
		if ([exception isKindOfClass:
		    [OFInvalidEncodingException class]])
			exception = [OFInvalidServerReplyException exception];

		[_client->_delegate client: _client
		     didEncounterException: exception
				forRequest: _request
				   context: _context];
		return false;
	}

	@try {
		if (_firstLine) {
			_firstLine = false;
			return [self handleFirstLine: line];
		} else
			return [self handleServerHeader: line
						 socket: socket];
	} @catch (id e) {
		[_client->_delegate client: _client
		     didEncounterException: e
				forRequest: _request
				   context: _context];
		return false;
	}
}

- (size_t)socket: (OFTCPSocket *)socket
    didWriteBody: (const void **)body
	  length: (size_t)length
	 context: (id)context
       exception: (id)exception
{
	if (exception != nil) {
		[_client->_delegate client: _client
		     didEncounterException: exception
				forRequest: _request
				   context: _context];
		return 0;
	}

	[socket asyncReadLineWithTarget: self
			       selector: @selector(socket:didReadLine:context:
					      exception:)
				context: nil];
	return 0;
}

-  (size_t)socket: (OFTCPSocket *)socket
  didWriteRequest: (const void **)request
	   length: (size_t)length
	  context: (id)context
	exception: (id)exception
{
	OFData *body;

	if (exception != nil) {
		if ([exception isKindOfClass: [OFWriteFailedException class]] &&
		    ([exception errNo] == ECONNRESET ||
		    [exception errNo] == EPIPE)) {
			/* In case a keep-alive connection timed out */
			[self closeAndReconnect];
			return false;
		}

		[_client->_delegate client: _client
		     didEncounterException: exception
				forRequest: _request
				   context: _context];
		return 0;
	}

	if ((body = [_request body]) != nil) {
		[socket asyncWriteBuffer: [body items]
				  length: [body count] * [body itemSize]
				  target: self
				selector: @selector(socket:didWriteBody:length:
					      context:exception:)
				 context: nil];
		return 0;
	} else
		return [self socket: socket
		       didWriteBody: NULL
			     length: 0
			    context: nil
			  exception: nil];
}

- (void)handleSocket: (OFTCPSocket *)socket
{
	/*
	 * As a work around for a bug with split packets in lighttpd when using
	 * HTTPS, we construct the complete request in a buffer string and then
	 * send it all at once.
	 *
	 * We do not use the socket's write buffer in case we need to resend
	 * the entire request (e.g. in case a keep-alive connection timed out).
	 */

	@try {
		OFString *requestString = constructRequestString(_request);
		const char *UTF8String = [requestString UTF8String];
		size_t UTF8StringLength = [requestString UTF8StringLength];

		/*
		 * Pass requestString as context to retain it so that the
		 * underlying buffer lives long enough.
		 */
		[socket asyncWriteBuffer: UTF8String
				  length: UTF8StringLength
				  target: self
				selector: @selector(socket:didWriteRequest:
					      length:context:exception:)
				 context: requestString];
	} @catch (id e) {
		[_client->_delegate client: _client
		     didEncounterException: e
				forRequest: _request
				   context: _context];
		return;
	}
}

- (void)socketDidConnect: (OFTCPSocket *)socket
		 context: (id)context
	       exception: (id)exception
{
	if ([_client->_delegate respondsToSelector:
	    @selector(client:didCreateSocket:forRequest:context:)])
		[_client->_delegate client: _client
			   didCreateSocket: socket
				forRequest: _request
				   context: _context];

	[self performSelector: @selector(handleSocket:)
		   withObject: socket
		   afterDelay: 0];
}

- (bool)throwAwayContent: (OFHTTPClientResponse *)response
		  buffer: (char *)buffer
		  length: (size_t)length
		 context: (OFTCPSocket *)socket
	       exception: (id)exception
{
	if (exception != nil) {
		[_client->_delegate client: _client
		     didEncounterException: exception
				forRequest: _request
				   context: _context];
		return false;
	}

	if ([response isAtEndOfStream]) {
		[self freeMemory: buffer];

		[_client->_lastResponse release];
		_client->_lastResponse = nil;

		[self performSelector: @selector(handleSocket:)
			   withObject: socket
			   afterDelay: 0];
		return false;
	}

	return true;
}

- (void)start
{
	OFURL *URL = [_request URL];
	OFTCPSocket *socket;

	/* Can we reuse the last socket? */
	if (_client->_socket != nil &&
	    [[_client->_lastURL scheme] isEqual: [URL scheme]] &&
	    [[_client->_lastURL host] isEqual: [URL host]] &&
	    [_client->_lastURL port] == [URL port]) {
		/*
		 * Set _socket to nil, so that in case of an error it won't be
		 * reused. If everything is successful, we set _socket again
		 * at the end.
		 */
		socket = [_client->_socket autorelease];
		_client->_socket = nil;

		[_client->_lastURL release];
		_client->_lastURL = nil;

		if (!_client->_lastWasHEAD) {
			/* Throw away content that has not been read yet */
			char *buffer = [self allocMemoryWithSize: 512];

			[_client->_lastResponse
			    asyncReadIntoBuffer: buffer
					 length: 512
					 target: self
				       selector: @selector(throwAwayContent:
						     buffer:length:context:
						     exception:)
					context: socket];
		} else {
			[_client->_lastResponse release];
			_client->_lastResponse = nil;

			[self performSelector: @selector(handleSocket:)
				   withObject: socket
				   afterDelay: 0];
		}
	} else
		[self closeAndReconnect];
}
@end

@implementation OFHTTPClientResponse
@synthesize of_keepAlive = _keepAlive;

- initWithSocket: (OFTCPSocket *)socket
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

- (void)setHeaders: (OFDictionary *)headers
{
	OFString *contentLength;

	[super setHeaders: headers];

	_chunked = [[headers objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];

	contentLength = [headers objectForKey: @"Content-Length"];
	if (contentLength != nil) {
		_hasContentLength = true;

		@try {
			intmax_t toRead = [contentLength decimalValue];

			if (toRead < 0)
				@throw [OFInvalidServerReplyException
				    exception];

			if (sizeof(intmax_t) > sizeof(size_t) &&
			    toRead > (intmax_t)SIZE_MAX)
				@throw [OFOutOfRangeException exception];

			_toRead = (size_t)toRead;
		} @catch (OFInvalidFormatException *e) {
			@throw [OFInvalidServerReplyException exception];
		}
	}
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	if (_socket == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

	if (!_hasContentLength && !_chunked)
		return [_socket readIntoBuffer: buffer
					length: length];

	/* Content-Length */
	if (!_chunked) {
		size_t ret;

		if (_toRead == 0) {
			_atEndOfStream = true;

			if (!_keepAlive) {
				[_socket release];
				_socket = nil;
			}

			return 0;
		}

		if (_toRead < length)
			ret = [_socket readIntoBuffer: buffer
					       length: _toRead];
		else
			ret = [_socket readIntoBuffer: buffer
					       length: length];

		_toRead -= ret;

		return ret;
	}

	/* Chunked */
	if (_toRead > 0) {
		if (length > _toRead)
			length = _toRead;

		length = [_socket readIntoBuffer: buffer
					  length: length];

		_toRead -= length;

		if (_toRead == 0)
			if ([[_socket readLine] length] > 0)
				@throw [OFInvalidServerReplyException
				    exception];

		return length;
	} else {
		void *pool = objc_autoreleasePoolPush();
		OFString *line;
		of_range_t range;

		@try {
			line = [_socket readLine];
		} @catch (OFInvalidEncodingException *e) {
			@throw [OFInvalidServerReplyException exception];
		}

		range = [line rangeOfString: @";"];
		if (range.location != OF_NOT_FOUND)
			line = [line substringWithRange:
			    of_range(0, range.location)];

		@try {
			uintmax_t toRead = [line hexadecimalValue];

			if (toRead > SIZE_MAX)
				@throw [OFOutOfRangeException exception];

			_toRead = (size_t)toRead;
		} @catch (OFInvalidFormatException *e) {
			@throw [OFInvalidServerReplyException exception];
		}

		if (_toRead == 0) {
			_atEndOfStream = true;

			if (_keepAlive) {
				@try {
					line = [_socket readLine];
				} @catch (OFInvalidEncodingException *e) {
					@throw [OFInvalidServerReplyException
					    exception];
				}

				if ([line length] > 0)
					@throw [OFInvalidServerReplyException
					    exception];
			} else {
				[_socket release];
				_socket = nil;
			}
		}

		objc_autoreleasePoolPop(pool);

		return 0;
	}
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_atEndOfStream)
		return true;

	if (_socket == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!_hasContentLength && !_chunked)
		return [_socket isAtEndOfStream];

	return _atEndOfStream;
}

- (int)fileDescriptorForReading
{
	if (_socket == nil)
		return -1;

	return [_socket fileDescriptorForReading];
}

- (bool)hasDataInReadBuffer
{
	return ([super hasDataInReadBuffer] || [_socket hasDataInReadBuffer]);
}

- (void)close
{
	_atEndOfStream = false;

	[_socket release];
	_socket = nil;

	[super close];
}
@end

@implementation OFHTTPClient
@synthesize delegate = _delegate;
@synthesize insecureRedirectsAllowed = _insecureRedirectsAllowed;

+ (instancetype)client
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}

- (void)asyncPerformRequest: (OFHTTPRequest *)request
		    context: (id)context
{
	[self asyncPerformRequest: request
			redirects: 10
			  context: context];
}

- (void)asyncPerformRequest: (OFHTTPRequest *)request
		  redirects: (unsigned int)redirects
		    context: (id)context
{
	void *pool = objc_autoreleasePoolPush();
	OFURL *URL = [request URL];
	OFString *scheme = [URL scheme];

	if (![scheme isEqual: @"http"] && ![scheme isEqual: @"https"])
		@throw [OFUnsupportedProtocolException exceptionWithURL: URL];

	if (_inProgress)
		/* TODO: Find a better exception */
		@throw [OFAlreadyConnectedException exception];

	_inProgress = true;

	[[[[OFHTTPClientRequestHandler alloc]
	    initWithClient: self
		   request: request
		 redirects: redirects
		   context: context] autorelease] start];

	objc_autoreleasePoolPop(pool);
}

- (void)close
{
	[_socket release];
	_socket = nil;

	[_lastURL release];
	_lastURL = nil;

	[_lastResponse release];
	_lastResponse = nil;
}
@end
