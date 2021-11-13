/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFTLSStream.h"
#import "OFDate.h"
#ifdef HAVE_SECURE_TRANSPORT
# import "OFSecureTransportTLSStream.h"
#endif

#import "OFNotImplementedException.h"

@interface OFTLSStreamHandshakeDelegate: OFObject <OFTLSStreamDelegate>
{
@public
	bool _done;
	id _exception;
}
@end

Class OFTLSStreamImplementation = Nil;
static const OFRunLoopMode handshakeRunLoopMode =
    @"OFTLSStreamHandshakeRunLoopMode";

OFString *
OFTLSStreamErrorCodeDescription(OFTLSStreamErrorCode errorCode)
{
	switch (errorCode) {
	case OFTLSStreamErrorCodeInitializationFailed:
		return @"Initialization of TLS context failed";
	default:
		return @"Unknown error";
	}
}

@implementation OFTLSStreamHandshakeDelegate
- (void)dealloc
{
	[_exception release];

	[super dealloc];
}

-		       (void)stream: (OFTLSStream *)stream
  didPerformClientHandshakeWithHost: (OFString *)host
			  exception: (id)exception
{
	_done = true;
	_exception = [exception retain];
}
@end

@implementation OFTLSStream
@synthesize wrappedStream = _wrappedStream;
@dynamic delegate;
@synthesize verifiesCertificates = _verifiesCertificates;

+ (instancetype)alloc
{
	if (self == [OFTLSStream class]) {
		if (OFTLSStreamImplementation != Nil)
			return [OFTLSStreamImplementation alloc];

#ifdef HAVE_SECURE_TRANSPORT
		return [OFSecureTransportTLSStream alloc];
#else
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];
#endif
	}

	return [super alloc];
}

+ (instancetype)streamWithStream: (OFStream <OFReadyForReadingObserving,
				       OFReadyForWritingObserving> *)stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				     OFReadyForWritingObserving> *)stream
{
	self = [super init];

	@try {
		_wrappedStream = [stream retain];
		_verifiesCertificates = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_wrappedStream release];

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)hasDataInReadBuffer
{
	return (super.hasDataInReadBuffer ||
	    _wrappedStream.hasDataInReadBuffer);
}

- (bool)lowlevelIsAtEndOfStream
{
	return _wrappedStream.atEndOfStream;
}

- (int)fileDescriptorForReading
{
	return _wrappedStream.fileDescriptorForReading;
}

- (int)fileDescriptorForWriting
{
	return _wrappedStream.fileDescriptorForWriting;
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
{
	[self asyncPerformClientHandshakeWithHost: host
				      runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)performClientHandshakeWithHost: (OFString *)host
{
	void *pool = objc_autoreleasePoolPush();
	id <OFTLSStreamDelegate> delegate = _delegate;
	OFTLSStreamHandshakeDelegate *handshakeDelegate =
	    [[[OFTLSStreamHandshakeDelegate alloc] init] autorelease];
	OFRunLoop *runLoop = [OFRunLoop currentRunLoop];

	_delegate = handshakeDelegate;
	[self asyncPerformClientHandshakeWithHost: host
				      runLoopMode: handshakeRunLoopMode];

	while (!handshakeDelegate->_done)
		[runLoop runMode: handshakeRunLoopMode beforeDate: nil];

	/* Cleanup */
	[runLoop runMode: handshakeRunLoopMode beforeDate: [OFDate date]];

	_delegate = delegate;

	if (handshakeDelegate->_exception != nil)
		@throw handshakeDelegate->_exception;

	objc_autoreleasePoolPop(pool);
}
@end
