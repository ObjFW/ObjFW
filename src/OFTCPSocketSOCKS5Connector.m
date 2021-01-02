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

#include <assert.h>
#include <errno.h>

#import "OFTCPSocketSOCKS5Connector.h"
#import "OFData.h"
#import "OFRunLoop.h"
#import "OFString.h"

#import "OFConnectionFailedException.h"

@implementation OFTCPSocketSOCKS5Connector
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id <OFTCPSocketDelegate>)delegate
#ifdef OF_HAVE_BLOCKS
			 block: (of_tcp_socket_async_connect_block_t)block
#endif
{
	self = [super init];

	@try {
		_socket = [sock retain];
		_host = [host copy];
		_port = port;
		_delegate = [delegate retain];
#ifdef OF_HAVE_BLOCKS
		_block = [block copy];
#endif

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
	[_host release];
	[_delegate release];
#ifdef OF_HAVE_BLOCKS
	[_block release];
#endif
	[_exception release];
	[_request release];

	[super dealloc];
}

- (void)didConnect
{
	_socket.delegate = _delegate;

#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block(_exception);
	else {
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

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	OFData *data;

	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return;
	}

	data = [OFData dataWithItems: "\x05\x01\x00"
			       count: 3];

	_SOCKS5State = OF_SOCKS5_STATE_SEND_AUTHENTICATION;
	[_socket asyncWriteData: data
		    runLoopMode: [OFRunLoop currentRunLoop].currentMode];
}

-      (bool)stream: (OFStream *)sock
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	of_run_loop_mode_t runLoopMode;
	unsigned char *SOCKSVersion;
	uint8_t hostLength;
	unsigned char port[2];
	unsigned char *response, *addressLength;

	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return false;
	}

	runLoopMode = [OFRunLoop currentRunLoop].currentMode;

	switch (_SOCKS5State) {
	case OF_SOCKS5_STATE_READ_VERSION:
		SOCKSVersion = buffer;

		if (SOCKSVersion[0] != 5 || SOCKSVersion[1] != 0) {
			_exception = [[OFConnectionFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: self
				   errNo: EPROTONOSUPPORT];
			[self didConnect];
			return false;
		}

		[_request release];
		_request = [[OFMutableData alloc] init];

		[_request addItems: "\x05\x01\x00\x03"
			     count: 4];

		hostLength = (uint8_t)_host.UTF8StringLength;
		[_request addItem: &hostLength];
		[_request addItems: _host.UTF8String
			     count: hostLength];

		port[0] = _port >> 8;
		port[1] = _port & 0xFF;
		[_request addItems: port
			     count: 2];

		_SOCKS5State = OF_SOCKS5_STATE_SEND_REQUEST;
		[_socket asyncWriteData: _request
			    runLoopMode: runLoopMode];
		return false;
	case OF_SOCKS5_STATE_READ_RESPONSE:
		response = buffer;

		if (response[0] != 5 || response[2] != 0) {
			_exception = [[OFConnectionFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: self
				   errNo: EPROTONOSUPPORT];
			[self didConnect];
			return false;
		}

		if (response[1] != 0) {
			int errNo;

			switch (response[1]) {
			case 0x02:
				errNo = EPERM;
				break;
			case 0x03:
				errNo = ENETUNREACH;
				break;
			case 0x04:
				errNo = EHOSTUNREACH;
				break;
			case 0x05:
				errNo = ECONNREFUSED;
				break;
			case 0x06:
				errNo = ETIMEDOUT;
				break;
			case 0x07:
				errNo = EOPNOTSUPP;
				break;
			case 0x08:
				errNo = EAFNOSUPPORT;
				break;
			default:
#ifdef EPROTO
				errNo = EPROTO;
#else
				errNo = 0;
#endif
				break;
			}

			_exception = [[OFConnectionFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: _socket
				   errNo: errNo];
			[self didConnect];
			return false;
		}

		/* Skip the rest of the response */
		switch (response[3]) {
		case 1: /* IPv4 */
			_SOCKS5State = OF_SOCKS5_STATE_READ_ADDRESS;
			[_socket asyncReadIntoBuffer: _buffer
					 exactLength: 4 + 2
					 runLoopMode: runLoopMode];
			return false;
		case 3: /* Domain name */
			_SOCKS5State = OF_SOCKS5_STATE_READ_ADDRESS_LENGTH;
			[_socket asyncReadIntoBuffer: _buffer
					 exactLength: 1
					 runLoopMode: runLoopMode];
			return false;
		case 4: /* IPv6 */
			_SOCKS5State = OF_SOCKS5_STATE_READ_ADDRESS;
			[_socket asyncReadIntoBuffer: _buffer
					 exactLength: 16 + 2
					 runLoopMode: runLoopMode];
			return false;
		default:
			_exception = [[OFConnectionFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: self
				   errNo: EPROTONOSUPPORT];
			[self didConnect];
			return false;
		}

		return false;
	case OF_SOCKS5_STATE_READ_ADDRESS:
		[self didConnect];
		return false;
	case OF_SOCKS5_STATE_READ_ADDRESS_LENGTH:
		addressLength = buffer;

		_SOCKS5State = OF_SOCKS5_STATE_READ_ADDRESS;
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: addressLength[0] + 2
				 runLoopMode: runLoopMode];
		return false;
	default:
		assert(0);
		return false;
	}
}

- (OFData *)stream: (OFStream *)sock
      didWriteData: (OFData *)data
      bytesWritten: (size_t)bytesWritten
	 exception: (id)exception
{
	of_run_loop_mode_t runLoopMode;

	if (exception != nil) {
		_exception = [exception retain];
		[self didConnect];
		return nil;
	}

	runLoopMode = [OFRunLoop currentRunLoop].currentMode;

	switch (_SOCKS5State) {
	case OF_SOCKS5_STATE_SEND_AUTHENTICATION:
		_SOCKS5State = OF_SOCKS5_STATE_READ_VERSION;
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: 2
				 runLoopMode: runLoopMode];
		return nil;
	case OF_SOCKS5_STATE_SEND_REQUEST:
		[_request release];
		_request = nil;

		_SOCKS5State = OF_SOCKS5_STATE_READ_RESPONSE;
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: 4
				 runLoopMode: runLoopMode];
		return nil;
	default:
		assert(0);
		return nil;
	}
}
@end
