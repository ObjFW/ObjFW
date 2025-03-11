/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#define OF_HTTP_SERVER_M

#include "config.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#import "OFHTTPServer.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFIRI.h"
#import "OFIRI+Private.h"
#import "OFNumber.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"
#import "OFString.h"
#import "OFString+Private.h"
#import "OFTCPSocket.h"
#import "OFTLSStream.h"
#import "OFThread.h"
#import "OFTimer.h"
#import "OFX509Certificate.h"

#import "OFAlreadyOpenException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFWriteFailedException.h"

/*
 * FIXME: Key normalization replaces headers like "DNT" with "Dnt".
 * FIXME: Errors are not reported to the user.
 */

@interface OFHTTPServer () <OFTCPSocketDelegate, OFTLSStreamDelegate>
@end

OF_DIRECT_MEMBERS
@interface OFHTTPServerResponse: OFHTTPResponse <OFReadyForWritingObserving>
{
	OFStream <OFReadyForWritingObserving> *_stream;
	OFHTTPServer *_server;
	OFHTTPRequest *_request;
	bool _chunked, _headersSent;
}

- (instancetype)initWithStream: (OFStream <OFReadyForWritingObserving> *)stream
			server: (OFHTTPServer *)server
		       request: (OFHTTPRequest *)request;
@end

OF_DIRECT_MEMBERS
@interface OFHTTPServerConnection: OFObject <OFTCPSocketDelegate>
{
@public
	OFStream <OFReadyForReadingObserving, OFReadyForWritingObserving>
	    *_stream;
	OFHTTPServer *_server;
	OFTimer *_timer;
	enum {
		stateAwaitingProlog,
		stateParsingHeaders,
		stateSendResponse
	} _state;
	uint8_t _HTTPMinorVersion;
	OFHTTPRequestMethod _method;
	OFString *_host, *_path;
	uint16_t _port;
	OFMutableDictionary *_headers;
	size_t _contentLength;
	OFStream *_requestBody;
}

- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				    OFReadyForWritingObserving> *)stream
			server: (OFHTTPServer *)server;
- (bool)parseProlog: (OFString *)line;
- (bool)parseHeaders: (OFString *)line;
- (bool)sendErrorAndClose: (short)statusCode;
- (void)createResponse;
@end

OF_DIRECT_MEMBERS
@interface OFHTTPServerRequestBodyStream: OFStream <OFReadyForReadingObserving>
{
	OFStream <OFReadyForReadingObserving> *_stream;
	bool _chunked;
	long long _toRead;
	bool _atEndOfStream, _setAtEndOfStream;
}

- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving> *)stream
		       chunked: (bool)chunked
		 contentLength: (unsigned long long)contentLength;
@end

#ifdef OF_HAVE_THREADS
OF_DIRECT_MEMBERS
@interface OFHTTPServerThread: OFThread
- (void)stop;
@end
#endif

static OFString *
normalizedKey(OFString *key)
{
	char *cString = _OFStrDup(key.UTF8String);
	unsigned char *tmp = (unsigned char *)cString;
	bool firstLetter = true;
	OFString *ret;

	while (*tmp != '\0') {
		if (!OFASCIIIsAlpha(*tmp)) {
			firstLetter = true;
			tmp++;
			continue;
		}

		*tmp = (firstLetter
		    ? OFASCIIToUpper(*tmp) : OFASCIIToLower(*tmp));

		firstLetter = false;
		tmp++;
	}

	@try {
		ret = [OFString stringWithUTF8StringNoCopy: cString
					      freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(cString);
		@throw e;
	}

	return ret;
}

@implementation OFHTTPServerResponse
- (instancetype)initWithStream: (OFStream <OFReadyForWritingObserving> *)stream
			server: (OFHTTPServer *)server
		       request: (OFHTTPRequest *)request
{
	self = [super init];

	_statusCode = 500;
	_stream = [stream retain];
	_server = [server retain];
	_request = [request retain];

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

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

	[_stream writeFormat: @"HTTP/%@ %hd %@\r\n",
			      self.protocolVersionString, _statusCode,
			      OFHTTPStatusCodeString(_statusCode)];

	headers = [[_headers mutableCopy] autorelease];

	if ([headers objectForKey: @"Date"] == nil) {
		OFString *date = [[OFDate date]
		    dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"];
		[headers setObject: date forKey: @"Date"];
	}

	if ([headers objectForKey: @"Server"] == nil) {
		OFString *name = _server.name;

		if (name != nil)
			[headers setObject: name forKey: @"Server"];
	}

	keyEnumerator = [headers keyEnumerator];
	valueEnumerator = [headers objectEnumerator];
	while ((key = [keyEnumerator nextObject]) != nil &&
	    (value = [valueEnumerator nextObject]) != nil)
		[_stream writeFormat: @"%@: %@\r\n", key, value];

	[_stream writeString: @"\r\n"];

	_headersSent = true;
	_chunked = [[headers objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];

	objc_autoreleasePoolPop(pool);
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	/* TODO: Use non-blocking writes */

	void *pool;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!_headersSent)
		[self of_sendHeaders];

	if (!_chunked) {
		@try {
			[_stream writeBuffer: buffer length: length];
		} @catch (OFWriteFailedException *e) {
			if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
				return e.bytesWritten;

			@throw e;
		}

		return length;
	}

	pool = objc_autoreleasePoolPush();
	[_stream writeString: [OFString stringWithFormat: @"%zX\r\n", length]];
	objc_autoreleasePoolPop(pool);

	[_stream writeBuffer: buffer length: length];
	[_stream writeString: @"\r\n"];

	return length;
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	@try {
		if (!_headersSent)
			[self of_sendHeaders];

		if (_chunked)
			[_stream writeString: @"0\r\n\r\n"];
	} @catch (OFWriteFailedException *e) {
		id <OFHTTPServerDelegate> delegate = _server.delegate;

#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wdeprecated"
#endif
		if ([delegate respondsToSelector:
		    @selector(server:didEncounterException:request:response:)])
			[delegate	   server: _server
			    didEncounterException: e
					  request: _request
					 response: self];
		else if ([delegate respondsToSelector: @selector(server:
		  didReceiveExceptionForResponse:request:exception:)])
			[delegate		    server: _server
			    didReceiveExceptionForResponse: self
						   request: _request
						 exception: e];
#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic pop
#endif
	}

	[_stream release];
	_stream = nil;

	[super close];
}

- (int)fileDescriptorForWriting
{
	if (_stream == nil)
		return -1;

	return _stream.fileDescriptorForWriting;
}
@end

@implementation OFHTTPServerConnection
- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				    OFReadyForWritingObserving> *)stream
			server: (OFHTTPServer *)server
{
	self = [super init];

	@try {
		_stream = [stream retain];
		_server = [server retain];
		_timer = [[OFTimer
		    scheduledTimerWithTimeInterval: 10
					    target: _stream
					  selector: @selector(
							cancelAsyncRequests)
					   repeats: false] retain];
		_state = stateAwaitingProlog;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_stream release];
	[_server release];

	[_timer invalidate];
	[_timer release];

	[_host release];
	[_path release];
	[_headers release];
	[_requestBody release];

	[super dealloc];
}

- (bool)stream: (OFStream *)stream
   didReadLine: (OFString *)line
     exception: (id)exception
{
	if (line == nil || exception != nil)
		return false;

	@try {
		switch (_state) {
		case stateAwaitingProlog:
			return [self parseProlog: line];
		case stateParsingHeaders:
			return [self parseHeaders: line];
		default:
			return false;
		}
	} @catch (OFWriteFailedException *e) {
		return false;
	}

	OFEnsure(0);
}

- (bool)parseProlog: (OFString *)line
{
	OFString *method;
	OFMutableString *path;
	size_t pos;

	@try {
		OFString *version = [line
		    substringWithRange: OFMakeRange(line.length - 9, 9)];
		OFUnichar tmp;

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
	if (pos == OFNotFound)
		return [self sendErrorAndClose: 400];

	method = [line substringToIndex: pos];
	@try {
		_method = OFHTTPRequestMethodParseString(method);
	} @catch (OFInvalidArgumentException *e) {
		return [self sendErrorAndClose: 405];
	}

	@try {
		OFRange range = OFMakeRange(pos + 1, line.length - pos - 10);

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
	_state = stateParsingHeaders;

	return true;
}

- (bool)parseHeaders: (OFString *)line
{
	OFString *key, *value, *old;
	size_t pos;

	if (line.length == 0) {
		bool chunked = [[_headers objectForKey: @"Transfer-Encoding"]
		    isEqual: @"chunked"];
		OFString *contentLengthString =
		    [_headers objectForKey: @"Content-Length"];
		unsigned long long contentLength = 0;

		if (contentLengthString != nil) {
			if (chunked || contentLengthString.length == 0)
				return [self sendErrorAndClose: 400];

			@try {
				contentLength =
				    contentLengthString.unsignedLongLongValue;
			} @catch (OFInvalidFormatException *e) {
				return [self sendErrorAndClose: 400];
			}
		}

		if (chunked || contentLengthString != nil) {
			[_requestBody release];
			_requestBody = nil;
			_requestBody = [[OFHTTPServerRequestBodyStream alloc]
			    initWithStream: _stream
				   chunked: chunked
			     contentLength: contentLength];

			[_timer invalidate];
			[_timer release];
			_timer = nil;
		}

		_state = stateSendResponse;
		[self createResponse];

		return false;
	}

	pos = [line rangeOfString: @":"].location;
	if (pos == OFNotFound)
		return [self sendErrorAndClose: 400];

	key = [line substringToIndex: pos];
	value = [line substringFromIndex: pos + 1];

	key = normalizedKey(key.stringByDeletingTrailingWhitespaces);
	value = value.stringByDeletingLeadingWhitespaces;

	old = [_headers objectForKey: key];
	if (old != nil)
		value = [old stringByAppendingFormat: @",%@", value];

	[_headers setObject: value forKey: key];

	if ([key isEqual: @"Host"]) {
		pos = [value rangeOfString: @":"
				   options: OFStringSearchBackwards].location;

		if (pos != OFNotFound) {
			OFString *host = [value substringToIndex: pos];

			if ([host hasPrefix: @"["] && [host hasSuffix: @"]"]) {
				OFString *IPv6 = [host substringWithRange:
				    OFMakeRange(1, host.length - 2)];

				if (_OFIRIIsIPv6Host(IPv6))
					host = IPv6;

			}

			[_host release];
			_host = [host retain];

			@try {
				unsigned short portTmp =
				    [value substringFromIndex: pos + 1]
				    .unsignedShortValue;

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
	[_stream writeFormat: @"HTTP/1.1 %hd %@\r\n"
			      @"Date: %@\r\n"
			      @"Server: %@\r\n"
			      @"\r\n",
			      statusCode, OFHTTPStatusCodeString(statusCode),
			      date, _server.name];
	return false;
}

- (void)createResponse
{
	void *pool = objc_autoreleasePoolPush();
	bool usesTLS = [_stream isKindOfClass: [OFTLSStream class]];
	OFMutableIRI *IRI;
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

	IRI = [OFMutableIRI IRIWithScheme: (usesTLS ? @"https" : @"http")];
	IRI.host = _host;
	if (_port != 80)
		IRI.port = [OFNumber numberWithUnsignedShort: _port];

	@try {
		if ((pos = [_path rangeOfString: @"?"].location) !=
		    OFNotFound) {
			OFString *path, *query;

			path = [_path substringToIndex: pos];
			query = [_path substringFromIndex: pos + 1];

			IRI.percentEncodedPath = path;
			IRI.percentEncodedQuery = query;
		} else
			IRI.percentEncodedPath = _path;
	} @catch (OFInvalidFormatException *e) {
		objc_autoreleasePoolPop(pool);
		[self sendErrorAndClose: 400];
		return;
	}

	[IRI makeImmutable];

	request = [OFHTTPRequest requestWithIRI: IRI];
	request.method = _method;
	request.protocolVersion =
	    (OFHTTPRequestProtocolVersion){ 1, _HTTPMinorVersion };
	request.headers = _headers;

	if (usesTLS) {
		OFTCPSocket *sock =
		    (OFTCPSocket *)((OFTLSStream *)_stream).underlyingStream;
		request.remoteAddress = sock.remoteAddress;
	} else
		request.remoteAddress = ((OFTCPSocket *)_stream).remoteAddress;

	response = [[[OFHTTPServerResponse alloc]
	    initWithStream: _stream
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
- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving> *)stream
		       chunked: (bool)chunked
		 contentLength: (unsigned long long)contentLength
{
	self = [super init];

	@try {
		if (contentLength > LLONG_MAX)
			@throw [OFOutOfRangeException exception];

		_stream = [stream retain];
		_chunked = chunked;
		_toRead = (long long)contentLength;

		if (_chunked && _toRead > 0)
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

	if (_stream.atEndOfStream)
		@throw [OFTruncatedDataException exception];

	/* Content-Length */
	if (!_chunked) {
		size_t ret;

		if (length > (unsigned long long)_toRead)
			length = (size_t)_toRead;

		ret = [_stream readIntoBuffer: buffer length: length];

		_toRead -= ret;

		if (_toRead == 0)
			_atEndOfStream = true;

		return ret;
	}

	/* Chunked */
	if (_toRead == -2) {
		char tmp[2];

		switch ([_stream readIntoBuffer: tmp length: 2]) {
		case 2:
			_toRead++;
			if (tmp[1] != '\n')
				@throw [OFInvalidFormatException exception];
		case 1:
			_toRead++;
			if (tmp[0] != '\r')
				@throw [OFInvalidFormatException exception];
		}

		if (_setAtEndOfStream && _toRead == 0)
			_atEndOfStream = true;

		return 0;
	} else if (_toRead == -1) {
		char tmp;

		if ([_stream readIntoBuffer: &tmp length: 1] == 1) {
			_toRead++;
			if (tmp != '\n')
				@throw [OFInvalidFormatException exception];
		}

		if (_setAtEndOfStream && _toRead == 0)
			_atEndOfStream = true;

		return 0;
	} else if (_toRead > 0) {
		if (length > (unsigned long long)_toRead)
			length = (size_t)_toRead;

		length = [_stream readIntoBuffer: buffer length: length];

		_toRead -= length;
		if (_toRead == 0)
			_toRead = -2;

		return length;
	} else {
		void *pool = objc_autoreleasePoolPush();
		OFString *line;
		size_t pos;
		unsigned long long toRead;

		@try {
			line = [_stream tryReadLine];
		} @catch (OFInvalidEncodingException *e) {
			@throw [OFInvalidFormatException exception];
		}

		if (line == nil)
			return 0;

		pos = [line rangeOfString: @";"].location;
		if (pos != OFNotFound)
			line = [line substringToIndex: pos];

		if (line.length < 1) {
			/*
			 * We have read the empty string because the socket is
			 * at end of stream.
			 */
			if (_stream.atEndOfStream && pos == OFNotFound)
				@throw [OFTruncatedDataException exception];
			else
				@throw [OFInvalidFormatException exception];
		}

		toRead = [line unsignedLongLongValueWithBase: 16];
		if (toRead > LLONG_MAX)
			@throw [OFOutOfRangeException exception];
		_toRead = (long long)toRead;

		if (_toRead == 0) {
			_setAtEndOfStream = true;
			_toRead = -2;
		}

		objc_autoreleasePoolPop(pool);

		return 0;
	}
}

- (bool)lowlevelHasDataInReadBuffer
{
	return _stream.hasDataInReadBuffer;
}

- (int)fileDescriptorForReading
{
	return _stream.fileDescriptorForReading;
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	[_stream release];
	_stream = nil;

	[super close];
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
@synthesize delegate = _delegate, usesTLS = _usesTLS;
@synthesize certificateChain = _certificateChain, name = _name;

+ (instancetype)server
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	_name = @"OFHTTPServer (ObjFW's HTTP server class "
	    @"<https://objfw.nil.im/>)";
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
		@throw [OFAlreadyOpenException exceptionWithObject: self];

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
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	_port = port;
}

- (uint16_t)port
{
	return _port;
}

#ifdef OF_HAVE_THREADS
- (void)setNumberOfThreads: (size_t)numberOfThreads
{
	if (numberOfThreads == 0)
		@throw [OFInvalidArgumentException exception];

	if (_listeningSocket != nil)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

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
	OFSocketAddress address;

	if (_host == nil)
		@throw [OFInvalidArgumentException exception];

	if (_listeningSocket != nil)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	_listeningSocket = [[OFTCPSocket alloc] init];
	_listeningSocket.allowsMPTCP = true;
	address = [_listeningSocket bindToHost: _host port: _port];
	_port = OFSocketAddressIPPort(&address);
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

- (void)of_startTLSWithSocket: (OFStreamSocket *)sock
{
	OFTLSStream *TLSStream = [OFTLSStream streamWithStream: sock];
	TLSStream.certificateChain = _certificateChain;
	TLSStream.delegate = self;
	[TLSStream asyncPerformServerHandshake];
}

- (void)of_handleStream: (OFStream <OFReadyForReadingObserving,
			     OFReadyForWritingObserving> *)stream
{
	OFHTTPServerConnection *connection =
	    [[[OFHTTPServerConnection alloc] initWithStream: stream
						     server: self] autorelease];

	stream.delegate = connection;
	[stream asyncReadLine];
}

-    (bool)socket: (OFStreamSocket *)sock
  didAcceptSocket: (OFStreamSocket *)acceptedSocket
	exception: (id)exception
{
	SEL selector = (_usesTLS
	    ? @selector(of_startTLSWithSocket:) : @selector(of_handleStream:));

	if (exception != nil) {
		if ([_delegate respondsToSelector: @selector(
		    server:didEncounterException:request:response:)]) {
			[_delegate	   server: self
			    didEncounterException: exception
					  request: nil
					 response: nil];
			return false;
		}

#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wdeprecated"
#endif
		if ([_delegate respondsToSelector:
		    @selector(server:didReceiveExceptionOnListeningSocket:)])
			return [_delegate		  server: self
			    didReceiveExceptionOnListeningSocket: exception];
#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic pop
#endif

		return false;
	}

#ifdef OF_HAVE_THREADS
	if (_numberOfThreads > 1) {
		OFHTTPServerThread *thread =
		    [_threadPool objectAtIndex: _nextThreadIndex];

		if (++_nextThreadIndex >= _numberOfThreads - 1)
			_nextThreadIndex = 0;

		[self performSelector: selector
			     onThread: thread
			   withObject: acceptedSocket
			waitUntilDone: false];
	} else
#endif
		[self performSelector: selector withObject: acceptedSocket];

	return true;
}

- (void)streamDidPerformServerHandshake: (OFTLSStream *)stream
			      exception: (id)exception
{
	if (exception != nil) {
		if ([_delegate respondsToSelector:
		    @selector(server:didEncounterException:request:response:)])
			[_delegate	   server: self
			    didEncounterException: exception
					  request: nil
					 response: nil];

		return;
	}

	[self performSelector: @selector(of_handleStream:)
		   withObject: stream
		   afterDelay: 0];
}
@end
