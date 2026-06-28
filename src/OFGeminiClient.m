/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#define OF_GEMINI_CLIENT_M

#include "config.h"

#import "OFGeminiClient.h"
#import "OFCharacterSet.h"
#import "OFDate.h"
#import "OFGeminiResponse.h"
#import "OFIRI.h"
#import "OFNumber.h"
#import "OFRunLoop.h"
#import "OFTCPSocket.h"
#import "OFTLSStream.h"
#import "OFTimer.h"

#import "OFAlreadyOpenException.h"
#import "OFGeminiRequestFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerResponseException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedProtocolException.h"

static const OFRunLoopMode geminiClientRunLoopMode =
    @"OFGeminiClientRunLoopMode";
static const unsigned int defaultRedirects = 10;
static OFCharacterSet *whitespaceCS, *nonWhitespaceCS;

@interface OFGeminiClientRequestHandler: OFObject <OFTCPSocketDelegate,
    OFTLSStreamDelegate>
{
@public
	OFGeminiClient *_client;
	OFIRI *_IRI;
	unsigned int _redirects;
	unsigned char _statusCode;
	OFString *_metadata;
}

- (instancetype)initWithClient: (OFGeminiClient *)client
			   IRI: (OFIRI *)IRI
		     redirects: (unsigned int)redirects OF_DIRECT;
- (void)raiseException: (id)exception OF_DIRECT;
- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode;
- (void)handleStream: (OFStream *)stream;
@end

OF_DIRECT_MEMBERS
@interface OFGeminiClientResponse: OFGeminiResponse <OFReadyForReadingObserving>
{
	OFStream *_stream;
}

- (instancetype)initWithStream: (OFStream *)stream;
@end

OF_DIRECT_MEMBERS
@interface OFGeminiClientPerformDelegate: OFObject <OFGeminiClientDelegate>
{
@public
	bool _done;
	OFObject <OFGeminiClientDelegate> *_delegate;
	OFGeminiResponse *_response;
	id _exception;
}

- (instancetype)initWithDelegate: (OFObject <OFGeminiClientDelegate> *)delegate;
@end

static bool
defaultShouldFollow(OFIRI *fromIRI, OFIRI *toIRI)
{
	return [toIRI.scheme isEqual: @"gemini"];
}

@implementation OFGeminiClientRequestHandler
- (instancetype)initWithClient: (OFGeminiClient *)client
			   IRI: (OFIRI *)IRI
		     redirects: (unsigned int)redirects
{
	self = [super init];

	@try {
		_client = objc_retain(client);
		_IRI = [IRI copy];
		_redirects = redirects;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_client);
	objc_release(_IRI);
	objc_release(_metadata);

	[super dealloc];
}

- (void)raiseException: (id)exception
{
	[_client cancelAsyncRequests];
	_client->_inProgress = false;

	[_client->_delegate  client: _client
	    didPerformRequestForIRI: _IRI
			   response: nil
			  exception: exception];
}

- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	@try {
		OFTCPSocket *sock;
		uint16_t port = 1965;
		OFNumber *IRIPort;

		objc_release(_client->_streamToCancel);
		_client->_streamToCancel = nil;

		sock = [OFTCPSocket socket];
		sock.allowsMPTCP = true;

		IRIPort = _IRI.port;
		if (IRIPort != nil)
			port = IRIPort.unsignedShortValue;

		sock.delegate = self;
		[sock asyncConnectToHost: _IRI.host
				    port: port
			     runLoopMode: runLoopMode];
		_client->_streamToCancel = objc_retain(sock);
	} @catch (id e) {
		[self raiseException: e];
	}
}

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
	OFTLSStream *TLSStream;
	OFString *TLSHost;

	objc_release(_client->_streamToCancel);
	_client->_streamToCancel = nil;

	if (exception != nil) {
		[self raiseException: exception];
		return;
	}

	if ([_client->_delegate respondsToSelector:
	    @selector(client:didCreateTCPSocket:IRI:)])
		[_client->_delegate client: _client
			didCreateTCPSocket: sock
				       IRI: _IRI];

	@try {
		TLSStream = [OFTLSStream streamWithStream: sock];
	} @catch (OFNotImplementedException *e) {
		[self raiseException:
		    [OFUnsupportedProtocolException exceptionWithIRI: _IRI]];
		return;
	}

	if ([_client->_delegate respondsToSelector:
	    @selector(client:didCreateTLSStream:IRI:)])
		[_client->_delegate client: _client
			didCreateTLSStream: TLSStream
				       IRI: _IRI];

	TLSStream.delegate = self;

	TLSHost = _IRI.IRIByAddingPercentEncodingForUnicodeCharacters.host;
	[TLSStream
	    asyncPerformClientHandshakeWithHost: TLSHost
				    runLoopMode: runLoop.currentMode];
	_client->_streamToCancel = objc_retain(TLSStream);
}

-		       (void)stream: (OFTLSStream *)stream
  didPerformClientHandshakeWithHost: (OFString *)host
			  exception: (id)exception
{
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
	OFTimer *timer;

	if (exception != nil) {
		[self raiseException: exception];
		return;
	}

	timer = [OFTimer
	    timerWithTimeInterval: 0
			   target: self
			 selector: @selector(handleStream:)
			   object: stream
			  repeats: false];
	[runLoop addTimer: timer forMode: runLoop.currentMode];
}

- (void)handleStream: (OFStream *)stream
{
	@try {
		OFString *request =
		    [OFString stringWithFormat: @"%@\r\n", _IRI.string];
		OFRunLoopMode runLoopMode =
		    [OFRunLoop currentRunLoop].currentMode;

		[stream setMaxStringReadLength: 1024];
		[stream asyncWriteString: request
				encoding: OFStringEncodingUTF8
			     runLoopMode: runLoopMode];
	} @catch (id e) {
		[self raiseException: e];
		return;
	}
}

- (OFString *)stream: (OFStream *)stream
      didWriteString: (OFString *)string
	    encoding: (OFStringEncoding)encoding
	bytesWritten: (size_t)bytesWritten
	   exception: (id)exception
{
	OFRunLoopMode runLoopMode = [OFRunLoop currentRunLoop].currentMode;

	if (exception != nil) {
		[self raiseException: exception];
		return nil;
	}

	[stream asyncReadLineWithEncoding: OFStringEncodingUTF8
			      runLoopMode: runLoopMode];
	return nil;
}

- (bool)stream: (OFStream *)stream
   didReadLine: (OFString *)line
     exception: (id)exception
{
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
	OFRange range;
	unsigned char statusCode;
	OFString *metadata = nil, *statusCodeString;
	OFGeminiClientResponse *response;
	OFTimer *timer;

	if (exception != nil) {
		[self raiseException: exception];
		return false;
	}

	range = [line rangeOfCharacterFromSet: whitespaceCS];
	if (range.location != OFNotFound) {
		size_t firstSpacePos = range.location;
		OFRange range2;

		range.length = line.length - range.location;

		range2 = [line rangeOfCharacterFromSet: nonWhitespaceCS
					       options: 0
						 range: range];
		if (range2.location != OFNotFound) {
			range.location = range2.location;
			range.length = line.length - range.location;
		}

		statusCodeString = [line substringToIndex: firstSpacePos];
		metadata = [line substringWithRange: range];
	} else
		statusCodeString = line;

	@try {
		statusCode = statusCodeString.unsignedCharValue;
	} @catch (OFInvalidFormatException *e) {
		[self raiseException:
		    [OFInvalidServerResponseException exception]];
		return false;
	} @catch (OFOutOfRangeException *e) {
		[self raiseException:
		    [OFInvalidServerResponseException exception]];
		return false;
	}

	if (statusCode < 10 || statusCode > 69) {
		[self raiseException:
		    [OFInvalidServerResponseException exception]];
		return false;
	}

	response = objc_autorelease([[OFGeminiClientResponse alloc]
	    initWithStream: stream]);
	response.statusCode = statusCode;
	response.metadata = metadata;

	switch (statusCode / 10) {
	case 2:
		exception = nil;
		break;
	case 3:
		if (_redirects > 0) {
			OFIRI *toIRI;
			bool follow;

			@try {
				toIRI = [OFIRI IRIWithString: metadata
					       relativeToIRI: _IRI];
			} @catch (OFInvalidFormatException *e) {
				[self raiseException: e];
				return false;
			}

			if ([_client->_delegate respondsToSelector:
			    @selector(client:shouldFollowRedirectToIRI:fromIRI:
			    statusCode:)])
				follow = [_client->_delegate
						       client: _client
				    shouldFollowRedirectToIRI: toIRI
						      fromIRI: _IRI
						   statusCode: statusCode];
			else
				follow = defaultShouldFollow(_IRI, toIRI);

			if (follow) {
				SEL selector = @selector(startWithRunLoopMode:);

				_redirects--;

				objc_release(_IRI);
				_IRI = objc_retain(toIRI);

				timer = [OFTimer
				    timerWithTimeInterval: 0
						   target: self
						 selector: selector
						   object: runLoop.currentMode
						  repeats: false];
				[runLoop addTimer: timer
					  forMode: runLoop.currentMode];
				return false;
			}
		}
	default:
		exception = [OFGeminiRequestFailedException
		    exceptionWithIRI: _IRI
			    response: response];
	}

	_client->_inProgress = false;

	timer = [OFTimer
	    timerWithTimeInterval: 0
			   target: _client->_delegate
			 selector: @selector(client:didPerformRequestForIRI:
						 response:exception:)
			   object: _client
			   object: _IRI
			   object: response
			   object: exception
			  repeats: false];
	[runLoop addTimer: timer forMode: runLoop.currentMode];
	return false;
}
@end

@implementation OFGeminiClientResponse
- (instancetype)initWithStream: (OFStream *)stream
{
	self = [super init];

	_stream = objc_retain(stream);

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[_stream close];

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return [_stream readIntoBuffer: buffer length: length];
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _stream.atEndOfStream;
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

	objc_retain(_stream);
	_stream = nil;

	[super close];
}
@end

@implementation OFGeminiClientPerformDelegate
- (instancetype)initWithDelegate: (OFObject <OFGeminiClientDelegate> *)delegate
{
	self = [super init];

	_delegate = delegate;

	return self;
}

- (void)dealloc
{
	objc_release(_response);
	objc_release(_exception);

	[super dealloc];
}

-	     (void)client: (OFGeminiClient *)client
  didPerformRequestForIRI: (OFIRI *)IRI
		 response: (OFGeminiResponse *)response
		exception: (id)exception
{
	[_delegate	     client: client
	    didPerformRequestForIRI: IRI
			   response: response
			  exception: exception];

	_done = true;
	_response = objc_retain(response);
	_exception = objc_retain(exception);
}

-	(void)client: (OFGeminiClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
		 IRI: (OFIRI *)IRI

{
	if ([_delegate respondsToSelector:
	    @selector(client:didCreateTCPSocket:IRI:)])
		[_delegate	client: client
		    didCreateTCPSocket: TCPSocket
				   IRI: IRI];
}

-	(void)client: (OFGeminiClient *)client
  didCreateTLSStream: (OFTLSStream *)TLSStream
		 IRI: (OFIRI *)IRI
{
	if ([_delegate respondsToSelector:
	    @selector(client:didCreateTLSStream:IRI:)])
		[_delegate	client: client
		    didCreateTLSStream: TLSStream
				   IRI: IRI];
}

-	       (bool)client: (OFGeminiClient *)client
  shouldFollowRedirectToIRI: (OFIRI *)toIRI
		    fromIRI: (OFIRI *)fromIRI
		 statusCode: (unsigned char)statusCode

{
	if ([_delegate respondsToSelector:
	    @selector(client:shouldFollowRedirectToIRI:fromIRI:statusCode:)])
		return [_delegate      client: client
		    shouldFollowRedirectToIRI: toIRI
				      fromIRI: fromIRI
				   statusCode: statusCode];
	else
		return defaultShouldFollow(fromIRI, toIRI);
}
@end

@implementation OFGeminiClient
@synthesize delegate = _delegate;

+ (void)initialize
{
	if (self != [OFGeminiClient class])
		return;

	void *pool = objc_autoreleasePoolPush();
	whitespaceCS = [[OFCharacterSet alloc]
	    initWithCharactersInString: @" \t"];
	nonWhitespaceCS = objc_retain(whitespaceCS.invertedSet);
	objc_autoreleasePoolPop(pool);
}

+ (instancetype)client
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

- (void)dealloc
{
	objc_release(_streamToCancel);

	[super dealloc];
}

- (OFGeminiResponse *)performRequestForIRI: (OFIRI *)IRI
{
	return [self performRequestForIRI: IRI redirects: defaultRedirects];
}

- (OFGeminiResponse *)performRequestForIRI: (OFIRI *)IRI
				 redirects: (unsigned int)redirects
{
	void *pool = objc_autoreleasePoolPush();
	OFGeminiClientPerformDelegate *performDelegate = objc_autorelease(
	    [[OFGeminiClientPerformDelegate alloc]
	    initWithDelegate: _delegate]);
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
	OFGeminiResponse *response;

	_delegate = performDelegate;
	[self asyncPerformRequestForIRI: IRI
			      redirects: redirects
			    runLoopMode: geminiClientRunLoopMode];

	while (!performDelegate->_done)
		[runLoop runMode: geminiClientRunLoopMode beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: geminiClientRunLoopMode beforeDate: [OFDate date]];

	_delegate = performDelegate->_delegate;

	if (performDelegate->_exception != nil)
		@throw performDelegate->_exception;

	response = objc_retain(performDelegate->_response);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(response);
}

- (void)asyncPerformRequestForIRI: (OFIRI *)IRI
{
	[self asyncPerformRequestForIRI: IRI
			      redirects: defaultRedirects
			    runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncPerformRequestForIRI: (OFIRI *)IRI
			redirects: (unsigned int)redirects
{
	[self asyncPerformRequestForIRI: IRI
			      redirects: redirects
			    runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncPerformRequestForIRI: (OFIRI *)IRI
			redirects: (unsigned int)redirects
		      runLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();

	if (![IRI.scheme isEqual: @"gemini"])
		@throw [OFUnsupportedProtocolException exceptionWithIRI: IRI];

	if (IRI.user != nil || IRI.password != nil)
		@throw [OFInvalidArgumentException exception];

	if (_inProgress)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	_inProgress = true;

	[[[[OFGeminiClientRequestHandler alloc]
	    initWithClient: self
		       IRI: IRI
		 redirects: redirects] autorelease]
	    startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

- (void)cancelAsyncRequests
{
	[_streamToCancel cancelAsyncRequests];
	objc_release(_streamToCancel);
	_streamToCancel = nil;
}
@end
