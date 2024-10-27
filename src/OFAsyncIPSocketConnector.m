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

#include "config.h"

#include <errno.h>

#import "OFAsyncIPSocketConnector.h"
#import "OFData.h"
#ifdef OF_HAVE_SCTP
# import "OFSCTPSocket.h"
#endif
#import "OFTCPSocket.h"
#import "OFThread.h"
#import "OFTimer.h"

#import "OFConnectIPSocketFailedException.h"
#import "OFInvalidFormatException.h"

@implementation OFAsyncIPSocketConnector
- (instancetype)initWithSocket: (id)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id)delegate
		       handler: (id)handler
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_host = [host copy];
		_port = port;
		_delegate = [delegate retain];
		_handler = [handler copy];
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
	[_handler release];
	[_exception release];
	[_socketAddresses release];

	[super dealloc];
}

- (void)didConnect
{
	if (_exception == nil)
		[_socket setCanBlock: true];

#ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		if ([_socket isKindOfClass: [OFTCPSocket class]])
			((OFTCPSocketConnectedHandler)_handler)(_socket, _host,
			    _port, _exception);
# ifdef OF_HAVE_SCTP
		else if ([_socket isKindOfClass: [OFSCTPSocket class]])
			((OFSCTPSocketConnectedHandler)_handler)(_socket, _host,
			    _port, _exception);
# endif
		else
			OFEnsure(0);
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

- (void)of_socketDidConnect: (id)sock exception: (id)exception
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
			[runLoop addTimer: timer forMode: runLoop.currentMode];
		}

		return;
	}

	[self didConnect];
}

- (id)of_connectionFailedExceptionForErrNo: (int)errNo
{
	return [OFConnectIPSocketFailedException exceptionWithHost: _host
							      port: _port
							    socket: _socket
							     errNo: errNo];
}

- (void)tryNextAddressWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	OFSocketAddress address = *(const OFSocketAddress *)
	    [_socketAddresses itemAtIndex: _socketAddressesIndex++];
	int errNo;

	OFSocketAddressSetIPPort(&address, _port);

	if (![_socket of_createSocketForAddress: &address errNo: &errNo]) {
		if (_socketAddressesIndex >= _socketAddresses.count) {
			_exception = [[OFConnectIPSocketFailedException alloc]
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
	[_socket setCanBlock: true];
#else
	[_socket setCanBlock: false];
#endif

	if (![_socket of_connectSocketToAddress: &address errNo: &errNo]) {
#if !defined(OF_NINTENDO_3DS) && !defined(OF_WII)
# ifdef OF_WINDOWS
		if (errNo == EINPROGRESS || errNo == EWOULDBLOCK) {
# else
		if (errNo == EINPROGRESS) {
# endif
			[OFRunLoop of_addAsyncConnectForSocket: _socket
							  mode: runLoopMode
						      delegate: self];
			return;
		} else {
#endif
			[_socket of_closeSocket];

			if (_socketAddressesIndex >= _socketAddresses.count) {
				_exception = [[OFConnectIPSocketFailedException
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
	[_socket setCanBlock: false];
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

- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	@try {
		OFSocketAddress address = OFSocketAddressParseIP(_host, _port);

		_socketAddresses = [[OFData alloc]
		    initWithItems: &address
			    count: 1
			 itemSize: sizeof(address)];

		[self tryNextAddressWithRunLoopMode: runLoopMode];
		return;
	} @catch (OFInvalidFormatException *e) {
	}

	[[OFThread DNSResolver]
	    asyncResolveAddressesForHost: _host
			   addressFamily: OFSocketAddressFamilyAny
			     runLoopMode: runLoopMode
				delegate: self];
}
@end
