/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#define OF_HTTP_CLIENT_M

#include "config.h"

#include <errno.h>
#include <string.h>

#import "OFHTTPClient.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFIRI.h"
#import "OFKernelEventObserver.h"
#import "OFNumber.h"
#import "OFRunLoop.h"
#import "OFString.h"
#import "OFTCPSocket.h"
#import "OFTLSStream.h"

#import "OFAlreadyOpenException.h"
#import "OFHTTPRequestFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerResponseException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFUnsupportedVersionException.h"
#import "OFWriteFailedException.h"

static const unsigned int defaultRedirects = 10;

OF_DIRECT_MEMBERS
@interface OFHTTPClientRequestHandler: OFObject <OFTCPSocketDelegate,
    OFTLSStreamDelegate>
{
@public
	OFHTTPClient *_client;
	OFHTTPRequest *_request;
	unsigned int _redirects;
	bool _firstLine;
	OFString *_version;
	short _status;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *_serverHeaders;
}

- (instancetype)initWithClient: (OFHTTPClient *)client
		       request: (OFHTTPRequest *)request
		     redirects: (unsigned int)redirects;
- (void)start;
- (void)closeAndReconnect;
@end

OF_DIRECT_MEMBERS
@interface OFHTTPClientRequestBodyStream: OFStream <OFReadyForWritingObserving>
{
	OFHTTPClientRequestHandler *_handler;
	OFStream *_stream;
	bool _chunked;
	unsigned long long _toWrite;
	bool _atEndOfStream;
}

- (instancetype)initWithHandler: (OFHTTPClientRequestHandler *)handler
			 stream: (OFStream *)stream;
@end

OF_DIRECT_MEMBERS
@interface OFHTTPClientResponse: OFHTTPResponse <OFReadyForReadingObserving>
{
	OFStream *_stream;
	bool _hasContentLength, _chunked, _keepAlive;
	bool _atEndOfStream, _setAtEndOfStream;
	long long _toRead;
}

@property (nonatomic, setter=of_setKeepAlive:) bool of_keepAlive;

- (instancetype)initWithStream: (OFStream *)stream;
@end

OF_DIRECT_MEMBERS
@interface OFHTTPClientSyncPerformer: OFObject <OFHTTPClientDelegate>
{
	OFHTTPClient *_client;
	OFObject <OFHTTPClientDelegate> *_delegate;
	OFHTTPResponse *_response;
}

- (instancetype)initWithClient: (OFHTTPClient *)client;
- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request
			 redirects: (unsigned int)redirects;
@end

static OFString *
constructRequestString(OFHTTPRequest *request)
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPRequestMethod method = request.method;
	OFIRI *IRI = request.IRI.IRIByAddingPercentEncodingForUnicodeCharacters;
	OFString *path;
	OFString *user = IRI.user, *password = IRI.password;
	OFMutableString *requestString;
	OFMutableDictionary OF_GENERIC(OFString *, OFString *) *headers;
	bool hasContentLength, chunked;
	OFEnumerator OF_GENERIC(OFString *) *keyEnumerator, *objectEnumerator;
	OFString *key, *object;

	if (IRI.path.length > 0)
		path = IRI.percentEncodedPath;
	else
		path = @"/";

	requestString = [OFMutableString stringWithFormat:
	    @"%@ %@", OFHTTPRequestMethodString(method), path];

	if (IRI.query != nil) {
		[requestString appendString: @"?"];
		[requestString appendString: IRI.percentEncodedQuery];
	}

	[requestString appendString: @" HTTP/"];
	[requestString appendString: request.protocolVersionString];
	[requestString appendString: @"\r\n"];

	headers = [[request.headers mutableCopy] autorelease];
	if (headers == nil)
		headers = [OFMutableDictionary dictionary];

	if ([headers objectForKey: @"Host"] == nil) {
		OFNumber *port = IRI.port;

		if (port != nil) {
			OFString *host = [OFString stringWithFormat:
			    @"%@:%@", IRI.percentEncodedHost, port];

			[headers setObject: host forKey: @"Host"];
		} else
			[headers setObject: IRI.percentEncodedHost
				    forKey: @"Host"];
	}

	if ((user.length > 0 || password.length > 0) &&
	    [headers objectForKey: @"Authorization"] == nil) {
		OFMutableData *authorizationData = [OFMutableData data];
		OFString *authorization;

		[authorizationData addItems: user.UTF8String
				      count: user.UTF8StringLength];
		[authorizationData addItem: ":"];
		[authorizationData addItems: password.UTF8String
				      count: password.UTF8StringLength];

		authorization = [OFString stringWithFormat:
		    @"Basic %@", authorizationData.stringByBase64Encoding];

		[headers setObject: authorization forKey: @"Authorization"];
	}

	if ([headers objectForKey: @"User-Agent"] == nil)
		[headers setObject: @"OFHTTPClient (ObjFW's HTTP client class "
				    @"<https://objfw.nil.im/>)"
			    forKey: @"User-Agent"];

	if (request.protocolVersion.major == 1 &&
	    request.protocolVersion.minor == 0 &&
	    [headers objectForKey: @"Connection"] == nil)
		[headers setObject: @"keep-alive" forKey: @"Connection"];

	hasContentLength = ([headers objectForKey: @"Content-Length"] != nil);
	chunked = [[headers objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];

	if ((hasContentLength || chunked) &&
	    [headers objectForKey: @"Content-Type"] == nil)
		[headers setObject: @"application/x-www-form-"
				    @"urlencoded; charset=UTF-8"
			    forKey: @"Content-Type"];

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
		if (!OFASCIIIsAlpha(*str)) {
			firstLetter = true;
			str++;
			continue;
		}

		*str = (firstLetter
		    ? OFASCIIToUpper(*str) : OFASCIIToLower(*str));

		firstLetter = false;
		str++;
	}
}

static bool
defaultShouldFollow(OFHTTPRequestMethod method, short statusCode)
{
	bool follow;

	/*
	 * 301, 302 and 307 should only redirect with user confirmation if the
	 * request method is not GET or HEAD. Asking the delegate and getting
	 * true returned is considered user confirmation.
	 */
	if (method == OFHTTPRequestMethodGet ||
	    method == OFHTTPRequestMethodHead)
		follow = true;
	/* 303 should always be redirected and converted to a GET request. */
	else if (statusCode == 303)
		follow = true;
	else
		follow = false;

	return follow;
}

@implementation OFHTTPClientRequestHandler
- (instancetype)initWithClient: (OFHTTPClient *)client
		       request: (OFHTTPRequest *)request
		     redirects: (unsigned int)redirects
{
	self = [super init];

	@try {
		_client = [client retain];
		_request = [request retain];
		_redirects = redirects;
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
	[_version release];
	[_serverHeaders release];

	[super dealloc];
}

- (void)raiseException: (id)exception
{
	[_client close];
	_client->_inProgress = false;

	[_client->_delegate client: _client
		 didPerformRequest: _request
			  response: nil
			 exception: exception];
}

- (void)createResponseWithStreamOrThrow: (OFStream *)stream
{
	OFIRI *IRI = _request.IRI;
	OFHTTPClientResponse *response;
	OFString *connectionHeader;
	bool keepAlive;
	OFString *location;
	id exception;

	response = [[[OFHTTPClientResponse alloc] initWithStream: stream]
	    autorelease];
	response.protocolVersionString = _version;
	response.statusCode = _status;
	response.headers = _serverHeaders;

	connectionHeader = [_serverHeaders objectForKey: @"Connection"];
	if ([_version isEqual: @"1.1"]) {
		if (connectionHeader != nil)
			keepAlive = [connectionHeader isEqual: @"close"];
		else
			keepAlive = true;
	} else {
		if (connectionHeader != nil)
			keepAlive = ([connectionHeader caseInsensitiveCompare:
			    @"keep-alive"] == OFOrderedSame);
		else
			keepAlive = false;
	}

	if (keepAlive) {
		response.of_keepAlive = true;

		_client->_stream = [stream retain];
		_client->_lastIRI = [IRI copy];
		_client->_lastWasHEAD =
		    (_request.method == OFHTTPRequestMethodHead);
		_client->_lastResponse = [response retain];
	}

	if (_redirects > 0 && (_status == 301 || _status == 302 ||
	    _status == 303 || _status == 307) &&
	    (location = [_serverHeaders objectForKey: @"Location"]) != nil) {
		bool follow = true;
		OFIRI *newIRI;
		OFString *newIRIScheme;

		newIRI = [OFIRI IRIWithString: location relativeToIRI: IRI];
		newIRIScheme = newIRI.scheme;

		if ([newIRIScheme caseInsensitiveCompare: @"http"] !=
		    OFOrderedSame &&
		    [newIRIScheme caseInsensitiveCompare: @"https"] !=
		    OFOrderedSame)
			follow = false;

		if (!_client->_allowsInsecureRedirects &&
		    [IRI.scheme caseInsensitiveCompare: @"https"] ==
		    OFOrderedSame &&
		    [newIRIScheme caseInsensitiveCompare: @"http"] ==
		    OFOrderedSame)
			follow = false;

		if (follow && [_client->_delegate respondsToSelector:
		    @selector(client:shouldFollowRedirectToIRI:statusCode:
		    request:response:)])
			follow = [_client->_delegate client: _client
				  shouldFollowRedirectToIRI: newIRI
						 statusCode: _status
						    request: _request
						   response: response];
		else if (follow)
			follow = defaultShouldFollow(_request.method, _status);

		if (follow) {
			OFDictionary OF_GENERIC(OFString *, OFString *)
			    *headers = _request.headers;
			OFHTTPRequest *newRequest =
			    [[_request copy] autorelease];
			OFMutableDictionary *newHeaders =
			    [[headers mutableCopy] autorelease];

			if (![newIRI.host isEqual: IRI.host])
				[newHeaders removeObjectForKey: @"Host"];

			/*
			 * 303 means the request should be converted to a GET
			 * request before redirection. This also means stripping
			 * the entity of the request.
			 */
			if (_status == 303) {
				for (OFString *key in headers)
					if ([key hasPrefix: @"Content-"] ||
					    [key hasPrefix: @"Transfer-"])
						[newHeaders
						    removeObjectForKey: key];

				newRequest.method = OFHTTPRequestMethodGet;
			}

			newRequest.IRI = newIRI;
			newRequest.headers = newHeaders;

			_client->_inProgress = false;

			[_client asyncPerformRequest: newRequest
					   redirects: _redirects - 1];
			return;
		}
	}

	_client->_inProgress = false;

	if (_status / 100 != 2)
		exception = [OFHTTPRequestFailedException
		    exceptionWithRequest: _request
				response: response];
	else
		exception = nil;

	[_client->_delegate performSelector: @selector(client:didPerformRequest:
						 response:exception:)
				 withObject: _client
				 withObject: _request
				 withObject: response
				 withObject: exception
				 afterDelay: 0];
}

- (void)createResponseWithStream: (OFStream *)stream
{
	@try {
		[self createResponseWithStreamOrThrow: stream];
	} @catch (id e) {
		[self raiseException: e];
	}
}

- (bool)handleFirstLine: (OFString *)line
{
	long long status;

	/*
	 * It's possible that the write succeeds on a connection that is
	 * keep-alive, but the connection has already been closed by the remote
	 * end due to a timeout. In this case, we need to reconnect.
	 */
	if (line == nil) {
		[self closeAndReconnect];
		return false;
	}

	if (![line hasPrefix: @"HTTP/"] || line.length < 9 ||
	    [line characterAtIndex: 8] != ' ')
		@throw [OFInvalidServerResponseException exception];

	_version = [[line substringWithRange: OFMakeRange(5, 3)] copy];
	if (![_version isEqual: @"1.0"] && ![_version isEqual: @"1.1"])
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: _version];

	status = [line substringWithRange: OFMakeRange(9, 3)].longLongValue;

	if (status < 0 || status > 599)
		@throw [OFInvalidServerResponseException exception];

	_status = (short)status;

	return true;
}

- (bool)handleServerHeader: (OFString *)line stream: (OFStream *)stream
{
	OFString *key, *value, *old;
	const char *lineC, *tmp;
	char *keyC;

	if (line == nil)
		@throw [OFInvalidServerResponseException exception];

	if (line.length == 0) {
		[_serverHeaders makeImmutable];

		if ([_client->_delegate respondsToSelector: @selector(client:
		    didReceiveHeaders:statusCode:request:)])
			[_client->_delegate client: _client
				 didReceiveHeaders: _serverHeaders
					statusCode: _status
					   request: _request];

		stream.delegate = nil;

		[self performSelector: @selector(createResponseWithStream:)
			   withObject: stream
			   afterDelay: 0];

		return false;
	}

	lineC = line.UTF8String;

	if ((tmp = strchr(lineC, ':')) == NULL)
		@throw [OFInvalidServerResponseException exception];

	keyC = OFAllocMemory(tmp - lineC + 1, 1);
	memcpy(keyC, lineC, tmp - lineC);
	keyC[tmp - lineC] = '\0';
	normalizeKey(keyC);

	@try {
		key = [OFString stringWithUTF8StringNoCopy: keyC
					      freeWhenDone: true];
	} @catch (id e) {
		OFFreeMemory(keyC);
		@throw e;
	}

	do {
		tmp++;
	} while (*tmp == ' ');

	value = [OFString stringWithUTF8String: tmp];

	old = [_serverHeaders objectForKey: key];
	if (old != nil)
		value = [old stringByAppendingFormat: @",%@", value];

	[_serverHeaders setObject: value forKey: key];

	return true;
}

- (bool)stream: (OFStream *)stream
   didReadLine: (OFString *)line
     exception: (id)exception
{
	bool ret;

	if (exception != nil) {
		if ([exception isKindOfClass:
		    [OFInvalidEncodingException class]])
			exception =
			    [OFInvalidServerResponseException exception];

		[self raiseException: exception];
		return false;
	}

	@try {
		if (_firstLine) {
			_firstLine = false;
			ret = [self handleFirstLine: line];
		} else
			ret = [self handleServerHeader: line stream: stream];
	} @catch (id e) {
		[self raiseException: e];
		ret = false;
	}

	return ret;
}

- (OFString *)stream: (OFStream *)stream
      didWriteString: (OFString *)string
	    encoding: (OFStringEncoding)encoding
	bytesWritten: (size_t)bytesWritten
	   exception: (id)exception
{
	OFDictionary OF_GENERIC(OFString *, OFString *) *headers;
	bool chunked;

	if (exception != nil) {
		if ([exception isKindOfClass: [OFWriteFailedException class]] &&
		    ([exception errNo] == ECONNRESET ||
		    [exception errNo] == EPIPE)) {
			/* In case a keep-alive connection timed out */
			[self closeAndReconnect];
			return nil;
		}

		[self raiseException: exception];
		return nil;
	}

	_firstLine = true;

	headers = _request.headers;
	chunked = [[headers objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];

	if (chunked || [headers objectForKey: @"Content-Length"] != nil) {
		stream.delegate = nil;

		OFStream *requestBody = [[[OFHTTPClientRequestBodyStream alloc]
		    initWithHandler: self stream: stream] autorelease];

		if ([_client->_delegate respondsToSelector:
		    @selector(client:wantsRequestBody:request:)])
			[_client->_delegate client: _client
				  wantsRequestBody: requestBody
					   request: _request];
	} else
		[stream asyncReadLine];

	return nil;
}

- (void)handleStream: (OFStream *)stream
{
	/*
	 * As a work around for a bug with split packets in lighttpd when using
	 * HTTPS, we construct the complete request in a buffer string and then
	 * send it all at once.
	 *
	 * We do not use the streams's write buffer in case we need to resend
	 * the entire request (e.g. in case a keep-alive connection timed out).
	 */

	@try {
		[stream asyncWriteString: constructRequestString(_request)];
	} @catch (id e) {
		[self raiseException: e];
		return;
	}
}

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	if (exception != nil) {
		[self raiseException: exception];
		return;
	}

	if ([_client->_delegate respondsToSelector:
	    @selector(client:didCreateTCPSocket:request:)])
		[_client->_delegate client: _client
			didCreateTCPSocket: sock
				   request: _request];

	if ([_request.IRI.scheme caseInsensitiveCompare: @"https"] ==
	    OFOrderedSame) {
		OFTLSStream *stream;
		@try {
			stream = [OFTLSStream streamWithStream: sock];
		} @catch (OFNotImplementedException *e) {
			[self raiseException:
			    [OFUnsupportedProtocolException
			    exceptionWithIRI: _request.IRI]];
			return;
		}

		if ([_client->_delegate respondsToSelector:
		    @selector(client:didCreateTLSStream:request:)])
			[_client->_delegate client: _client
				didCreateTLSStream: stream
					   request: _request];

		stream.delegate = self;
		[stream asyncPerformClientHandshakeWithHost: _request.IRI
		    .IRIByAddingPercentEncodingForUnicodeCharacters.host];
	} else {
		sock.delegate = self;
		[self performSelector: @selector(handleStream:)
			   withObject: sock
			   afterDelay: 0];
	}
}

-		       (void)stream: (OFTLSStream *)stream
  didPerformClientHandshakeWithHost: (OFString *)host
			  exception: (id)exception
{
	if (exception != nil) {
		[self raiseException: exception];
		return;
	}

	[self performSelector: @selector(handleStream:)
		   withObject: stream
		   afterDelay: 0];
}

- (void)start
{
	OFIRI *IRI = _request.IRI;
	OFStream *stream;

	/* Can we reuse the last socket? */
	if (_client->_stream != nil && !_client->_stream.atEndOfStream &&
	    [_client->_lastIRI.scheme isEqual: IRI.scheme] &&
	    [_client->_lastIRI.host isEqual: IRI.host] &&
	    (_client->_lastIRI.port == IRI.port ||
	    [_client->_lastIRI.port isEqual: IRI.port]) &&
	    (_client->_lastWasHEAD || _client->_lastResponse.atEndOfStream)) {
		/*
		 * Set _stream to nil, so that in case of an error it won't be
		 * reused. If everything is successful, we set _stream again
		 * at the end.
		 */
		stream = [_client->_stream autorelease];
		_client->_stream = nil;

		[_client->_lastIRI release];
		_client->_lastIRI = nil;

		[_client->_lastResponse release];
		_client->_lastResponse = nil;

		stream.delegate = self;

		[self performSelector: @selector(handleStream:)
			   withObject: stream
			   afterDelay: 0];
	} else
		[self closeAndReconnect];
}

- (void)closeAndReconnect
{
	@try {
		OFIRI *IRI =
		    _request.IRI.IRIByAddingPercentEncodingForUnicodeCharacters;
		OFTCPSocket *sock;
		uint16_t port;
		OFNumber *IRIPort;

		[_client close];

		sock = [OFTCPSocket socket];
		sock.usesMPTCP = true;

		if ([IRI.scheme caseInsensitiveCompare: @"https"] ==
		    OFOrderedSame)
			port = 443;
		else
			port = 80;

		IRIPort = IRI.port;
		if (IRIPort != nil)
			port = IRIPort.unsignedShortValue;

		sock.delegate = self;
		[sock asyncConnectToHost: IRI.host port: port];
	} @catch (id e) {
		[self raiseException: e];
	}
}
@end

@implementation OFHTTPClientRequestBodyStream
- (instancetype)initWithHandler: (OFHTTPClientRequestHandler *)handler
			 stream: (OFStream *)stream
{
	self = [super init];

	@try {
		OFDictionary OF_GENERIC(OFString *, OFString *) *headers;
		OFString *transferEncoding, *contentLengthString;

		_handler = [handler retain];
		_stream = [stream retain];

		headers = _handler->_request.headers;

		transferEncoding = [headers objectForKey: @"Transfer-Encoding"];
		_chunked = [transferEncoding isEqual: @"chunked"];

		contentLengthString = [headers objectForKey: @"Content-Length"];
		if (contentLengthString != nil) {
			if (_chunked || contentLengthString.length == 0)
				@throw [OFInvalidArgumentException
				    exception];

			_toWrite = contentLengthString.unsignedLongLongValue;
		} else if (!_chunked)
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

	[_handler release];

	[super dealloc];
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	/* TODO: Use non-blocking writes */

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	/*
	 * We must not send a chunk of size 0, as that would end the body. We
	 * always ignore writing 0 bytes to still allow writing 0 bytes after
	 * the end of stream.
	 */
	if (length == 0)
		return 0;

	if (_atEndOfStream)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: ENOTCONN];

	if (_chunked)
		[_stream writeFormat: @"%zX\r\n", length];
	else if (length > _toWrite)
		@throw [OFOutOfRangeException exception];

	[_stream writeBuffer: buffer length: length];
	if (_chunked)
		[_stream writeString: @"\r\n"];

	if (!_chunked) {
		_toWrite -= length;

		if (_toWrite == 0)
			_atEndOfStream = true;
	}

	return length;
}

- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_chunked)
		[_stream writeString: @"0\r\n\r\n"];
	else if (_toWrite > 0)
		@throw [OFTruncatedDataException exception];

	_stream.delegate = _handler;
	[_stream asyncReadLine];

	[_stream release];
	_stream = nil;

	[super close];
}

- (int)fileDescriptorForWriting
{
	return ((OFStream <OFReadyForWritingObserving> *)_stream)
	    .fileDescriptorForWriting;
}
@end

@implementation OFHTTPClientResponse
@synthesize of_keepAlive = _keepAlive;

- (instancetype)initWithStream: (OFStream *)stream
{
	self = [super init];

	_stream = [stream retain];

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	[super dealloc];
}

- (void)setHeaders: (OFDictionary *)headers
{
	OFString *contentLength;

	super.headers = headers;

	_chunked = [[headers objectForKey: @"Transfer-Encoding"]
	    isEqual: @"chunked"];

	contentLength = [headers objectForKey: @"Content-Length"];
	if (contentLength != nil) {
		if (_chunked || contentLength.length == 0)
			@throw [OFInvalidServerResponseException exception];

		_hasContentLength = true;

		@try {
			unsigned long long toRead =
			    contentLength.unsignedLongLongValue;

			if (toRead > LLONG_MAX)
				@throw [OFOutOfRangeException exception];

			_toRead = (long long)toRead;
		} @catch (OFInvalidFormatException *e) {
			@throw [OFInvalidServerResponseException exception];
		}
	}
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!_hasContentLength && !_chunked)
		return [_stream readIntoBuffer: buffer length: length];

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
		if (ret > length)
			@throw [OFOutOfRangeException exception];

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
				@throw [OFInvalidServerResponseException
				    exception];
		case 1:
			_toRead++;
			if (tmp[0] != '\r')
				@throw [OFInvalidServerResponseException
				    exception];
		}

		if (_setAtEndOfStream && _toRead == 0)
			_atEndOfStream = true;

		return 0;
	} else if (_toRead == -1) {
		char tmp;

		if ([_stream readIntoBuffer: &tmp length: 1] == 1) {
			_toRead++;
			if (tmp != '\n')
				@throw [OFInvalidServerResponseException
				    exception];
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

		@try {
			line = [_stream tryReadLine];
		} @catch (OFInvalidEncodingException *e) {
			@throw [OFInvalidServerResponseException exception];
		}

		if (line == nil)
			return 0;

		pos = [line rangeOfString: @";"].location;
		if (pos != OFNotFound)
			line = [line substringToIndex: pos];

		if (line.length < 1) {
			/*
			 * We have read the empty string because the stream is
			 * at end of stream.
			 */
			if (_stream.atEndOfStream && pos == OFNotFound)
				@throw [OFTruncatedDataException exception];
			else
				@throw [OFInvalidServerResponseException
				    exception];
		}

		@try {
			unsigned long long toRead =
			    [line unsignedLongLongValueWithBase: 16];

			if (toRead > LLONG_MAX)
				@throw [OFOutOfRangeException exception];

			_toRead = (long long)toRead;
		} @catch (OFInvalidFormatException *e) {
			@throw [OFInvalidServerResponseException exception];
		}

		if (_toRead == 0) {
			_setAtEndOfStream = true;
			_toRead = -2;
		}

		objc_autoreleasePoolPop(pool);

		return 0;
	}
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!_hasContentLength && !_chunked)
		return _stream.atEndOfStream;

	return _atEndOfStream;
}

- (int)fileDescriptorForReading
{
	if (_stream == nil)
		return -1;

	return ((OFStream <OFReadyForReadingObserving> *)_stream)
	    .fileDescriptorForReading;
}

- (bool)lowlevelHasDataInReadBuffer
{
	return _stream.hasDataInReadBuffer;
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	_atEndOfStream = false;

	[_stream release];
	_stream = nil;

	[super close];
}
@end

@implementation OFHTTPClientSyncPerformer
- (instancetype)initWithClient: (OFHTTPClient *)client
{
	self = [super init];

	@try {
		_client = [client retain];
		_delegate = client.delegate;

		_client.delegate = self;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	_client.delegate = _delegate;
	[_client release];

	[super dealloc];
}

- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request
			 redirects: (unsigned int)redirects
{
	[_client asyncPerformRequest: request redirects: redirects];
	[[OFRunLoop currentRunLoop] run];
	return _response;
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response
	  exception: (id)exception
{
	if (exception != nil) {
		/*
		 * Restore the delegate - we're giving up, but not reaching the
		 * release of the autorelease pool that contains us, so
		 * resetting it via -[dealloc] might be too late.
		 */
		_client.delegate = _delegate;

		@throw exception;
	}

	[[OFRunLoop currentRunLoop] stop];

	[_response release];
	_response = [response retain];

	[_delegate     client: client
	    didPerformRequest: request
		     response: response
		    exception: nil];
}

-	(void)client: (OFHTTPClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
	     request: (OFHTTPRequest *)request
{
	if ([_delegate respondsToSelector:
	    @selector(client:didCreateTCPSocket:request:)])
		[_delegate	client: client
		    didCreateTCPSocket: TCPSocket
			       request: request];
}

-	(void)client: (OFHTTPClient *)client
  didCreateTLSStream: (OFTLSStream *)TLSStream
	     request: (OFHTTPRequest *)request
{
	if ([_delegate respondsToSelector:
	    @selector(client:didCreateTLSStream:request:)])
		[_delegate	client: client
		    didCreateTLSStream: TLSStream
			       request: request];
}

-     (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)body
	   request: (OFHTTPRequest *)request
{
	if ([_delegate respondsToSelector:
	    @selector(client:wantsRequestBody:request:)])
		[_delegate    client: client
		    wantsRequestBody: body
			     request: request];
}

-      (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary OF_GENERIC(OFString *, OFString *) *)headers
	 statusCode: (short)statusCode
	    request: (OFHTTPRequest *)request
{
	if ([_delegate respondsToSelector:
	    @selector(client:didReceiveHeaders:statusCode:request:)])
		[_delegate     client: client
		    didReceiveHeaders: headers
			   statusCode: statusCode
			      request: request];
}

-	       (bool)client: (OFHTTPClient *)client
  shouldFollowRedirectToIRI: (OFIRI *)IRI
		 statusCode: (short)statusCode
		    request: (OFHTTPRequest *)request
		   response: (OFHTTPResponse *)response
{
	if ([_delegate respondsToSelector: @selector(
	    client:shouldFollowRedirectToIRI:statusCode:request:response:)])
		return [_delegate      client: client
		    shouldFollowRedirectToIRI: IRI
				   statusCode: statusCode
				      request: request
				     response: response];
	else
		return defaultShouldFollow(request.method, statusCode);
}
@end

@implementation OFHTTPClient
@synthesize delegate = _delegate;
@synthesize allowsInsecureRedirects = _allowsInsecureRedirects;

+ (instancetype)client
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	[self close];

	[super dealloc];
}

- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request
{
	return [self performRequest: request redirects: defaultRedirects];
}

- (OFHTTPResponse *)performRequest: (OFHTTPRequest *)request
			 redirects: (unsigned int)redirects
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPClientSyncPerformer *syncPerformer =
	    [[[OFHTTPClientSyncPerformer alloc] initWithClient: self]
	    autorelease];
	OFHTTPResponse *response = [syncPerformer performRequest: request
						       redirects: redirects];

	[response retain];

	objc_autoreleasePoolPop(pool);

	return [response autorelease];
}

- (void)asyncPerformRequest: (OFHTTPRequest *)request
{
	[self asyncPerformRequest: request redirects: defaultRedirects];
}

- (void)asyncPerformRequest: (OFHTTPRequest *)request
		  redirects: (unsigned int)redirects
{
	void *pool = objc_autoreleasePoolPush();
	OFIRI *IRI = request.IRI;
	OFString *scheme = IRI.scheme;

	if ([scheme caseInsensitiveCompare: @"http"] != OFOrderedSame &&
	    [scheme caseInsensitiveCompare: @"https"] != OFOrderedSame)
		@throw [OFUnsupportedProtocolException exceptionWithIRI: IRI];

	if (_inProgress)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	_inProgress = true;

	[[[[OFHTTPClientRequestHandler alloc]
	    initWithClient: self
		   request: request
		 redirects: redirects] autorelease] start];

	objc_autoreleasePoolPop(pool);
}

- (void)close
{
	[_stream release];
	_stream = nil;

	[_lastIRI release];
	_lastIRI = nil;

	[_lastResponse release];
	_lastResponse = nil;
}
@end
