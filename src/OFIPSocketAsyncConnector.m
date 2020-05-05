/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

#import "OFIPSocketAsyncConnector.h"
#import "OFData.h"
#ifdef OF_HAVE_SCTP
# import "OFSCTPSocket.h"
#endif
#import "OFTCPSocket.h"
#import "OFThread.h"
#import "OFTimer.h"

#import "OFConnectionFailedException.h"
#import "OFInvalidFormatException.h"

@implementation OFIPSocketAsyncConnector
- (instancetype)initWithSocket: (id)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id)delegate
			 block: (id)block
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_host = [host copy];
		_port = port;
		_delegate = [delegate retain];
		_block = [block copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_socket release];
	[_host release];
	[_delegate release];
	[_block release];
	[_exception release];
	[_socketAddresses release];

	[super dealloc];
}

- (void)didConnect
{
	if (_exception == nil)
		[_socket setBlocking: true];

#ifdef OF_HAVE_BLOCKS
	if (_block != NULL) {
		if ([_socket isKindOfClass: [OFTCPSocket class]])
			((of_tcp_socket_async_connect_block_t)_block)(
			    _exception);
# ifdef OF_HAVE_SCTP
		else if ([_socket isKindOfClass: [OFSCTPSocket class]])
			((of_sctp_socket_async_connect_block_t)_block)(
			    _exception);
# endif
		else
			OF_ENSURE(0);
	} else {
#endif
		if ([_delegate respondsToSelector:
		    @selector(socket:didConnectToHost:port:exception:)])
			[_delegate    socket: _socket
			    didConnectToHost: _host
					port: _port
				   exception: _exception];
#ifdef OF_HAVE_BLOCKS
	}
#endif
}

- (void)of_socketDidConnect: (id)sock
		  exception: (id)exception
{
	if (exception != nil) {
		/*
		 * self might be retained only by the pending async requests,
		 * which we're about to cancel.
		 */
		[[self retain] autorelease];

		[sock cancelAsyncRequests];
		[sock of_closeSocket];

		if (_socketAddressesIndex >= _socketAddresses.count) {
			_exception = [exception retain];
			[self didConnect];
		} else {
			/*
			 * We must not call it before returning, as otherwise
			 * the new socket would be removed from the queue upon
			 * return.
			 */
			OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
			SEL selector =
			    @selector(tryNextAddressWithRunLoopMode:);
			OFTimer *timer = [OFTimer
			    timerWithTimeInterval: 0
					   target: self
					 selector: selector
					   object: runLoop.currentMode
					  repeats: false];
			[runLoop addTimer: timer
				  forMode: runLoop.currentMode];
		}

		return;
	}

	[self didConnect];
}

- (id)of_connectionFailedExceptionForErrNo: (int)errNo
{
	return [OFConnectionFailedException exceptionWithHost: _host
							 port: _port
						       socket: _socket
							errNo: errNo];
}

- (void)tryNextAddressWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
{
	of_socket_address_t address = *(const of_socket_address_t *)
	    [_socketAddresses itemAtIndex: _socketAddressesIndex++];
	int errNo;

	of_socket_address_set_port(&address, _port);

	if (![_socket of_createSocketForAddress: &address
					  errNo: &errNo]) {
		if (_socketAddressesIndex >= _socketAddresses.count) {
			_exception = [[OFConnectionFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: _socket
				   errNo: errNo];
			[self didConnect];
			return;
		}

		[self tryNextAddressWithRunLoopMode: runLoopMode];
		return;
	}

#if defined(OF_NINTENDO_3DS) || defined(OF_WII)
	/*
	 * On Wii and 3DS, connect() fails if non-blocking is enabled.
	 *
	 * Additionally, on Wii, there is no getsockopt(), so it would not be
	 * possible to get the error (or success) after connecting anyway.
	 *
	 * So for now, connecting is blocking on Wii and 3DS.
	 *
	 * FIXME: Use a different thread as a work around.
	 */
	[_socket setBlocking: true];
#else
	[_socket setBlocking: false];
#endif

	if (![_socket of_connectSocketToAddress: &address
					  errNo: &errNo]) {
#if !defined(OF_NINTENDO_3DS) && !defined(OF_WII)
		if (errNo == EINPROGRESS) {
			[OFRunLoop of_addAsyncConnectForSocket: _socket
							  mode: runLoopMode
						      delegate: self];
			return;
		} else {
#endif
			[_socket of_closeSocket];

			if (_socketAddressesIndex >= _socketAddresses.count) {
				_exception = [[OFConnectionFailedException
				    alloc] initWithHost: _host
						   port: _port
						 socket: _socket
						  errNo: errNo];
				[self didConnect];
				return;
			}

			[self tryNextAddressWithRunLoopMode: runLoopMode];
			return;
#if !defined(OF_NINTENDO_3DS) && !defined(OF_WII)
		}
#endif
	}

#if defined(OF_NINTENDO_3DS) || defined(OF_WII)
	[_socket setBlocking: false];
#endif

	[self didConnect];
}

- (void)resolver: (OFDNSResolver *)resolver
  didResolveHost: (OFString *)host
       addresses: (OFData *)addresses
       exception: (id)exception
{
	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return;
	}

	_socketAddresses = [addresses copy];

	[self tryNextAddressWithRunLoopMode:
	    [OFRunLoop currentRunLoop].currentMode];
}

- (void)startWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
{
	@try {
		of_socket_address_t address =
		    of_socket_address_parse_ip(_host, _port);

		_socketAddresses = [[OFData alloc]
		    initWithItems: &address
			 itemSize: sizeof(address)
			    count: 1];

		[self tryNextAddressWithRunLoopMode: runLoopMode];
		return;
	} @catch (OFInvalidFormatException *e) {
	}

	[[OFThread DNSResolver]
	    asyncResolveAddressesForHost: _host
			   addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY
			     runLoopMode: runLoopMode
				delegate: self];
}
@end
