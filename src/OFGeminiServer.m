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

#define OF_GEMINI_SERVER_M

#include "config.h"

#include <errno.h>

#import "OFGeminiServer.h"
#import "OFArray.h"
#import "OFGeminiRequest.h"
#import "OFGeminiResponse.h"
#import "OFIRI.h"
#import "OFTCPSocket.h"
#import "OFTLSStream.h"
#import "OFThread.h"
#import "OFTimer.h"

#import "OFAlreadyOpenException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFWriteFailedException.h"

@interface OFGeminiServer () <OFTCPSocketDelegate, OFTLSStreamDelegate>
@end

OF_DIRECT_MEMBERS
@interface OFGeminiServerResponse: OFGeminiResponse <OFReadyForWritingObserving>
{
	OFStream <OFReadyForWritingObserving> *_stream;
	OFGeminiServer *_server;
	OFGeminiRequest *_request;
	bool _headerSent;
}

- (instancetype)
    of_initWithStream: (OFStream <OFReadyForWritingObserving> *)stream
	       server: (OFGeminiServer *)server
	      request: (OFGeminiRequest *)request;
- (void)of_sendHeaders;
@end

#ifdef OF_HAVE_THREADS
OF_DIRECT_MEMBERS
@interface OFGeminiServerThread: OFThread
- (void)stop;
@end
#endif

static void *cancelTimerKey = &cancelTimerKey;

@implementation OFGeminiServerResponse
- (instancetype)
    of_initWithStream: (OFStream <OFReadyForWritingObserving> *)stream
	       server: (OFGeminiServer *)server
	      request: (OFGeminiRequest *)request
{
	self = [super init];

	_statusCode = 42;
	_metadata = @"Internal error";
	_stream = objc_retain(stream);
	_server = objc_retain(server);
	_request = objc_retain(request);

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	objc_release(_server);
	objc_release(_request);

	[super dealloc];
}

- (void)of_sendHeaders
{
	/* TODO: Use non-blocking writes */

	if (_metadata != nil)
		[_stream writeFormat: @"%u %@\r\n", _statusCode, _metadata];
	else
		[_stream writeFormat: @"%u\r\n", _statusCode];

	_headerSent = true;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (!_headerSent)
		[self of_sendHeaders];

	@try {
		[_stream writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return e.bytesWritten;

		@throw e;
	}

	return length;
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	@try {
		if (!_headerSent)
			[self of_sendHeaders];
	} @catch (OFWriteFailedException *e) {
		id <OFGeminiServerDelegate> delegate = _server.delegate;

		if ([delegate respondsToSelector:
		    @selector(server:didEncounterException:request:response:)])
			[delegate	   server: _server
			    didEncounterException: e
					  request: _request
					 response: self];
	}

	objc_release(_stream);
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

#ifdef OF_HAVE_THREADS
@implementation OFGeminiServerThread
- (void)stop
{
	[[OFRunLoop currentRunLoop] stop];
	[self join];
}
@end
#endif

@implementation OFGeminiServer
@synthesize delegate = _delegate, requestTimeout = _requestTimeout;
@synthesize certificateChain = _certificateChain;

+ (instancetype)server
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

- (instancetype)init
{
	self = [super init];

	_requestTimeout = 3.0;
#ifdef OF_HAVE_THREADS
	_numberOfThreads = 1;
#endif

	return self;
}

- (void)dealloc
{
	[self stop];

	objc_release(_host);
	objc_release(_listeningSocket);

	[super dealloc];
}

- (void)setHost: (OFString *)host
{
	OFString *old;

	if (_listeningSocket != nil)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	old = _host;
	_host = [host copy];
	objc_release(old);
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

	if (_host == nil || _certificateChain == nil)
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
			OFGeminiServerThread *thread =
			    [OFGeminiServerThread thread];
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
	objc_release(_listeningSocket);
	_listeningSocket = nil;

#ifdef OF_HAVE_THREADS
	for (OFGeminiServerThread *thread in _threadPool)
		[thread stop];

	objc_release(_threadPool);
	_threadPool = nil;
#endif
}

- (void)of_startTLSWithSocket: (OFStreamSocket *)sock
{
	OFTLSStream *TLSStream;
	OFTimer *cancelTimer;

	TLSStream = [OFTLSStream streamWithStream: sock];
	TLSStream.certificateChain = _certificateChain;
	TLSStream.delegate = self;
	[TLSStream asyncPerformServerHandshake];

	cancelTimer = [OFTimer
	    scheduledTimerWithTimeInterval: _requestTimeout
				    target: TLSStream
				  selector: @selector(cancelAsyncRequests)
				   repeats: 0];
	objc_setAssociatedObject(TLSStream, cancelTimerKey, cancelTimer,
	    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)of_handleStream: (OFStream *)stream
{
	stream.delegate = self;
	/* 1024 hardcoded, as the spec demands */
	[stream setMaxStringReadLength: 1024];
	[stream asyncReadLine];
}

-    (bool)socket: (OFStreamSocket *)sock
  didAcceptSocket: (OFStreamSocket *)acceptedSocket
	exception: (id)exception
{
	if (exception != nil) {
		if ([_delegate respondsToSelector:
		    @selector(server:didEncounterException:request:response:)])
			[_delegate	   server: self
			    didEncounterException: exception
					  request: nil
					 response: nil];
		return true;
	}

#ifdef OF_HAVE_THREADS
	if (_numberOfThreads > 1) {
		OFGeminiServerThread *thread =
		    [_threadPool objectAtIndex: _nextThreadIndex];

		if (++_nextThreadIndex >= _numberOfThreads - 1)
			_nextThreadIndex = 0;

		[self performSelector: @selector(of_startTLSWithSocket:)
			     onThread: thread
			   withObject: acceptedSocket
			waitUntilDone: false];
	} else
#endif
		[self of_startTLSWithSocket: acceptedSocket];

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

	/*
	 * Since the TLS stream and the underlying socket share the underlying
	 * file descriptor, we need to make sure the file descriptor gets
	 * removed for the underlying socket first before being added for the
	 * TLS stream.
	 */
	[self performSelector: @selector(of_handleStream:)
		   withObject: stream
		   afterDelay: 0];
}

- (bool)stream: (OFStream *)stream
   didReadLine: (OFString *)line
     exception: (id)exception
{
	OFTimer *cancelTimer = objc_getAssociatedObject(stream, cancelTimerKey);
	OFIRI *IRI;
	OFGeminiRequest *request;
	OFGeminiResponse *response;
	OFStream *underlyingStream;

	[cancelTimer invalidate];

	if (line == nil || exception != nil) {
		if ([_delegate respondsToSelector:
		    @selector(server:didEncounterException:request:response:)])
			[_delegate	   server: self
			    didEncounterException: exception
					  request: nil
					 response: nil];

		return false;
	}

	@try {
		IRI = [OFIRI IRIWithString: line];
	} @catch (OFInvalidFormatException *e) {
		[stream asyncWriteString: @"59 Invalid IRI\r\n"];
		return false;
	}

	request = [OFGeminiRequest requestWithIRI: IRI];
	underlyingStream = ((OFTLSStream *)stream).underlyingStream;
	request.remoteAddress =
	    ((OFStreamSocket *)underlyingStream).remoteAddress;

	response = objc_autorelease([[OFGeminiServerResponse alloc]
	    of_initWithStream: (OFStream <OFReadyForWritingObserving> *)stream
		       server: self
		      request: request]);

	[_delegate performSelector: @selector(server:didReceiveRequest:
					response:)
			withObject: self
			withObject: request
			withObject: response
			afterDelay: 0];

	return false;
}
@end
