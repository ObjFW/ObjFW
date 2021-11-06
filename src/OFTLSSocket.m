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

#import "OFTLSSocket.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"

Class OFTLSSocketImplementation = Nil;

@interface OFTLSSocketAsyncConnector: OFObject <OFTLSSocketDelegate>
{
	OFTLSSocket *_socket;
	OFString *_host;
	uint16_t _port;
	id <OFTLSSocketDelegate> _delegate;
}

- (instancetype)initWithSocket: (OFTLSSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id <OFTLSSocketDelegate>)delegate;
@end

@implementation OFTLSSocketAsyncConnector
- (instancetype)initWithSocket: (OFTLSSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id <OFTLSSocketDelegate>)delegate
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_host = [host copy];
		_port = port;
		_delegate = [delegate retain];

		_socket.delegate = self;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_socket.delegate == self)
		_socket.delegate = _delegate;

	[_socket release];
	[_delegate release];

	[super dealloc];
}

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	if (exception == nil) {
		@try {
			[(OFTLSSocket *)sock startTLSForHost: _host
							port: _port];
		} @catch (id e) {
			[self release];
			@throw e;
		}
	}

	_socket.delegate = _delegate;
	[_delegate    socket: sock
	    didConnectToHost: host
			port: port
		   exception: exception];
}
@end

@implementation OFTLSSocket
@dynamic delegate;
@synthesize verifiesCertificates = _verifiesCertificates;

+ (instancetype)alloc
{
	if (self == [OFTLSSocket class]) {
		if (OFTLSSocketImplementation == nil)
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		return [OFTLSSocketImplementation alloc];
	}

	return [super alloc];
}

- (instancetype)init
{
	self = [super init];

	_verifiesCertificates = true;

	return self;
}

- (instancetype)initWithSocket: (OFTCPSocket *)socket
{
	self = [super init];

	@try {
		if ([socket isKindOfClass: [OFTLSSocket class]])
			@throw [OFInvalidArgumentException exception];

		_socket = socket->_socket;
		socket->_socket = OFInvalidSocketHandle;

		_verifiesCertificates = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)startTLSForHost: (OFString *)host port: (uint16_t)port
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();

	[[[OFTLSSocketAsyncConnector alloc]
	    initWithSocket: self
		      host: host
		      port: port
		  delegate: _delegate] autorelease];
	[super asyncConnectToHost: host port: port runLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFTCPSocketAsyncConnectBlock)block
{
	[super asyncConnectToHost: host
			     port: port
		      runLoopMode: runLoopMode
			    block: ^ (id exception) {
		if (exception == nil) {
			@try {
				[self startTLSForHost: host port: port];
			} @catch (id e) {
				block(e);
				return;
			}
		}

		block(exception);
	}];
}
#endif

- (instancetype)accept
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)lowlevelIsAtEndOfStream
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)TCPAccept
{
	return [super accept];
}

- (size_t)lowlevelTCPReadIntoBuffer: (void *)buffer length: (size_t)length
{
	return [super lowlevelReadIntoBuffer: buffer length: length];
}

- (size_t)lowlevelTCPWriteBuffer: (const void *)buffer length: (size_t)length
{
	return [super lowlevelWriteBuffer: buffer length: length];
}

- (bool)lowlevelTCPIsAtEndOfStream
{
	return [super lowlevelIsAtEndOfStream];
}
@end
