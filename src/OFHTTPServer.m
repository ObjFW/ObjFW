/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFNumber.h"
#import "OFTCPSocket.h"
#import "OFTLSSocket.h"
#import "OFThread.h"
#import "OFTimer.h"
#import "OFURL.h"

#import "OFAlreadyConnectedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFWriteFailedException.h"

#import "socket_helpers.h"

#define BUFFER_SIZE 1024

/*
 * FIXME: Key normalization replaces headers like "DNT" with "Dnt".
 * FIXME: Errors are not reported to the user.
 */

@interface OFHTTPServer () <OFTCPSocketDelegate>
@end

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

@interface OFHTTPServerConnection: OFObject <OFTCPSocketDelegate>
{
@public
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
	OFStream *_requestBody;
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
			server: (OFHTTPServer *)server;
- (bool)parseProlog: (OFString *)line;
- (bool)parseHeaders: (OFString *)line;
- (bool)sendErrorAndClose: (short)statusCode;
- (void)createResponse;
@end

@interface OFHTTPServerRequestBodyStream: OFStream <OFReadyForReadingObserving>
{
	OFTCPSocket *_socket;
	uintmax_t _toRead;
	bool _atEndOfStream;
}

- (instancetype)initWithSocket: (OFTCPSocket *)sock
		 contentLength: (uintmax_t)contentLength;
@end

#ifdef OF_HAVE_THREADS
@interface OFHTTPServerThread: OFThread
- (void)stop;
@end
#endif

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
	char *cString = of_strdup(key.UTF8String);
	unsigned char *tmp = (unsigned char *)cString;
	bool firstLetter = true;

	if (cString == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: strlen(key.UTF8String)];

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
			      self.protocolVersionString, _statusCode,
			      statusCodeToString(_statusCode)];

	headers = [[_headers mutableCopy] autorelease];

	if ([headers objectForKey: @"Date"] == nil) {
		OFString *date = [[OFDate date]
		    dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"];

		[headers setObject: date
			    forKey: @"Date"];
	}

	if ([headers objectForKey: @"Server"] == nil) {
		OFString *name = _server.name;

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
		id <OFHTTPServerDelegate> delegate = _server.delegate;

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

	return _socket.fileDescriptorForWriting;
}
@end

@implementation OFHTTPServerConnection
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
	[_requestBody release];

	[super dealloc];
}

- (bool)stream: (OFStream *)sock
   didReadLine: (OFString *)line
     exception: (id)exception
{
	if (line == nil || exception != nil)
		return false;

	@try {
		switch (_state) {
		case AWAITING_PROLOG:
			return [self parseProlog: line];
		case PARSING_HEADERS:
			return [self parseHeaders: line];
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
		    substringWithRange: of_range(line.length - 9, 9)];
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
		_method = of_http_request_method_from_string(method.UTF8String);
	} @catch (OFInvalidFormatException *e) {
		return [self sendErrorAndClose: 405];
	}

	@try {
		of_range_t range = of_range(pos + 1, line.length - pos - 10);

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

	if (line.length == 0) {
		OFString *contentLengthString;

		if ((contentLengthString =
		    [_headers objectForKey: @"Content-Length"]) != nil) {
			intmax_t contentLength;

			@try {
				contentLength =
				    contentLengthString.decimalValue;

			} @catch (OFInvalidFormatException *e) {
				return [self sendErrorAndClose: 400];
			}

			if (contentLength < 0)
				return [self sendErrorAndClose: 400];

			[_requestBody release];
			_requestBody = nil;
			_requestBody = [[OFHTTPServerRequestBodyStream alloc]
			    initWithSocket: _socket
			     contentLength: contentLength];

			[_timer invalidate];
			[_timer release];
			_timer = nil;
		}

		_state = SEND_RESPONSE;
		[self createResponse];

		return false;
	}

	pos = [line rangeOfString: @":"].location;
	if (pos == OF_NOT_FOUND)
		return [self sendErrorAndClose: 400];

	key = [line substringWithRange: of_range(0, pos)];
	value = [line substringWithRange:
	    of_range(pos + 1, line.length - pos - 1)];

	key = normalizedKey(key.stringByDeletingTrailingWhitespaces);
	value = value.stringByDeletingLeadingWhitespaces;

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
				    of_range(pos + 1, value.length - pos - 1);
				intmax_t portTmp = [value
				    substringWithRange: range].decimalValue;

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

- (bool)sendErrorAndClose: (short)statusCode
{
	OFString *date = [[OFDate date]
	    dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"];

	[_socket writeFormat: @"HTTP/1.1 %d %s\r\n"
			      @"Date: %@\r\n"
			      @"Server: %@\r\n"
			      @"\r\n",
			      statusCode, statusCodeToString(statusCode),
			      date, _server.name];

	return false;
}

- (void)createResponse
{
	void *pool = objc_autoreleasePoolPush();
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
		_host = [_server.host copy];
		_port = [_server port];
	}

	URL = [OFMutableURL URL];
	URL.scheme = @"http";
	URL.host = _host;
	if (_port != 80)
		URL.port = [OFNumber numberWithUInt16: _port];

	if ((pos = [_path rangeOfString: @"?"].location) != OF_NOT_FOUND) {
		OFString *path, *query;

		path = [_path substringWithRange: of_range(0, pos)];
		query = [_path substringWithRange:
		    of_range(pos + 1, _path.length - pos - 1)];

		URL.URLEncodedPath = path;
		URL.URLEncodedQuery = query;
	} else
		URL.URLEncodedPath = _path;

	[URL makeImmutable];

	request = [OFHTTPRequest requestWithURL: URL];
	request.method = _method;
	request.protocolVersion =
	    (of_http_request_protocol_version_t){ 1, _HTTPMinorVersion };
	request.headers = _headers;
	request.remoteAddress = _socket.remoteAddress;

	response = [[[OFHTTPServerResponse alloc]
	    initWithSocket: _socket
		    server: _server
		   request: request] autorelease];

	[_server.delegate server: _server
	       didReceiveRequest: request
		     requestBody: _requestBody
			response: response];

	objc_autoreleasePoolPop(pool);
}
@end

@implementation OFHTTPServerRequestBodyStream
- (instancetype)initWithSocket: (OFTCPSocket *)sock
		 contentLength: (uintmax_t)contentLength
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_toRead = contentLength;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	size_t ret;

	if (_toRead == 0) {
		_atEndOfStream = true;
		return 0;
	}

	if (length > _toRead)
		length = (size_t)_toRead;

	ret = [_socket readIntoBuffer: buffer
			       length: length];

	_toRead -= ret;

	return ret;
}

- (bool)hasDataInReadBuffer
{
	return (super.hasDataInReadBuffer || _socket.hasDataInReadBuffer);
}

- (int)fileDescriptorForReading
{
	return _socket.fileDescriptorForReading;
}

- (void)close
{
	[_socket release];
	_socket = nil;
}
@end

#ifdef OF_HAVE_THREADS
@implementation OFHTTPServerThread
- (void)stop
{
	[[OFRunLoop currentRunLoop] stop];
	[self join];
}
@end
#endif

@implementation OFHTTPServer
@synthesize delegate = _delegate, name = _name;

+ (instancetype)server
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	_name = @"OFHTTPServer (ObjFW's HTTP server class "
	    @"<https://heap.zone/objfw/>)";
#ifdef OF_HAVE_THREADS
	_numberOfThreads = 1;
#endif

	return self;
}

- (void)dealloc
{
	[self stop];

	[_host release];
	[_listeningSocket release];
	[_name release];

	[super dealloc];
}

- (void)setHost: (OFString *)host
{
	OFString *old;

	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	old = _host;
	_host = [host copy];
	[old release];
}

- (OFString *)host
{
	return _host;
}

- (void)setPort: (uint16_t)port
{
	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	_port = port;
}

- (uint16_t)port
{
	return _port;
}

- (void)setUsesTLS: (bool)usesTLS
{
	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	_usesTLS = usesTLS;
}

- (bool)usesTLS
{
	return _usesTLS;
}

- (void)setCertificateFile: (OFString *)certificateFile
{
	OFString *old;

	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	old = _certificateFile;
	_certificateFile = [certificateFile copy];
	[old release];
}

- (OFString *)certificateFile
{
	return _certificateFile;
}

- (void)setPrivateKeyFile: (OFString *)privateKeyFile
{
	OFString *old;

	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	old = _privateKeyFile;
	_privateKeyFile = [privateKeyFile copy];
	[old release];
}

- (OFString *)privateKeyFile
{
	return _privateKeyFile;
}

- (void)setPrivateKeyPassphrase: (const char *)privateKeyPassphrase
{
	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	_privateKeyPassphrase = privateKeyPassphrase;
}

- (const char *)privateKeyPassphrase
{
	return _privateKeyPassphrase;
}

#ifdef OF_HAVE_THREADS
- (void)setNumberOfThreads: (size_t)numberOfThreads
{
	if (numberOfThreads == 0)
		@throw [OFInvalidArgumentException exception];

	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	_numberOfThreads = numberOfThreads;
}

- (size_t)numberOfThreads
{
	return _numberOfThreads;
}
#endif

- (void)start
{
	void *pool = objc_autoreleasePoolPush();

	if (_host == nil)
		@throw [OFInvalidArgumentException exception];

	if (_listeningSocket != nil)
		@throw [OFAlreadyConnectedException exception];

	if (_usesTLS) {
		OFTCPSocket <OFTLSSocket> *TLSSocket;

		if (of_tls_socket_class == Nil)
			@throw [OFUnsupportedProtocolException exception];

		TLSSocket = [[of_tls_socket_class alloc] init];
		_listeningSocket = TLSSocket;

		TLSSocket.certificateFile = _certificateFile;
		TLSSocket.privateKeyFile = _privateKeyFile;
		TLSSocket.privateKeyPassphrase = _privateKeyPassphrase;
	} else
		_listeningSocket = [[OFTCPSocket alloc] init];

	_port = [_listeningSocket bindToHost: _host
					port: _port];
	[_listeningSocket listen];

#ifdef OF_HAVE_THREADS
	if (_numberOfThreads > 1) {
		OFMutableArray *threads =
		    [OFMutableArray arrayWithCapacity: _numberOfThreads - 1];

		for (size_t i = 1; i < _numberOfThreads; i++) {
			OFHTTPServerThread *thread =
			    [OFHTTPServerThread thread];
			thread.supportsSockets = true;

			[thread start];
			[threads addObject: thread];
		}

		[threads makeImmutable];
		_threadPool = [threads copy];
	}
#endif

	_listeningSocket.delegate = self;
	[_listeningSocket asyncAccept];

	objc_autoreleasePoolPop(pool);
}

- (void)stop
{
	[_listeningSocket cancelAsyncRequests];
	[_listeningSocket release];
	_listeningSocket = nil;

#ifdef OF_HAVE_THREADS
	for (OFHTTPServerThread *thread in _threadPool)
		[thread stop];

	[_threadPool release];
	_threadPool = nil;
#endif
}

- (void)of_handleAcceptedSocket: (OFTCPSocket *)acceptedSocket
{
	OFHTTPServerConnection *connection = [[[OFHTTPServerConnection alloc]
	    initWithSocket: acceptedSocket
		    server: self] autorelease];

	acceptedSocket.delegate = connection;
	[acceptedSocket asyncReadLine];
}

-    (bool)socket: (OFTCPSocket *)sock
  didAcceptSocket: (OFTCPSocket *)acceptedSocket
	exception: (id)exception
{
	if (exception != nil) {
		if (![_delegate respondsToSelector:
		    @selector(server:didReceiveExceptionOnListeningSocket:)])
			return false;

		return [_delegate		  server: self
		    didReceiveExceptionOnListeningSocket: exception];
	}

#ifdef OF_HAVE_THREADS
	if (_numberOfThreads > 1) {
		OFHTTPServerThread *thread =
		    [_threadPool objectAtIndex: _nextThreadIndex];

		if (++_nextThreadIndex >= _numberOfThreads - 1)
			_nextThreadIndex = 0;

		[self performSelector: @selector(of_handleAcceptedSocket:)
			     onThread: thread
			   withObject: acceptedSocket
			waitUntilDone: false];
	} else
#endif
		[self of_handleAcceptedSocket: acceptedSocket];

	return true;
}
@end
