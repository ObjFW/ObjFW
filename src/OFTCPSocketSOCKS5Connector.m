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

#include "config.h"

#include <errno.h>

#import "OFTCPSocketSOCKS5Connector.h"
#import "OFData.h"
#import "OFRunLoop.h"
#import "OFString.h"

#import "OFConnectIPSocketFailedException.h"

enum {
	stateSendAuthentication = 1,
	stateReadVersion,
	stateSendRequest,
	stateReadResponse,
	stateReadAddress,
	stateReadAddressLength,
};

@implementation OFTCPSocketSOCKS5Connector
- (instancetype)initWithSocket: (OFTCPSocket *)sock
			  host: (OFString *)host
			  port: (uint16_t)port
		      delegate: (id <OFTCPSocketDelegate>)delegate
#ifdef OF_HAVE_BLOCKS
		       handler: (OFTCPSocketConnectedHandler)handler
#endif
{
	self = [super init];

	@try {
		_socket = objc_retain(sock);
		_host = [host copy];
		_port = port;
		_delegate = objc_retain(delegate);
#ifdef OF_HAVE_BLOCKS
		_handler = [handler copy];
#endif

		_socket.delegate = self;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_socket.delegate == self)
		_socket.delegate = _delegate;

	objc_release(_socket);
	objc_release(_host);
	objc_release(_delegate);
#ifdef OF_HAVE_BLOCKS
	objc_release(_handler);
#endif
	objc_release(_exception);
	objc_release(_request);

	[super dealloc];
}

- (void)didConnect
{
	_socket.delegate = _delegate;

#ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		_handler(_socket, _host, _port, _exception);
	else {
#endif
		if ([_delegate respondsToSelector:
		    @selector(socket:didConnectToHost:port:exception:)])
			[_delegate socket: _socket
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
		_exception = objc_retain(exception);
		[self didConnect];
		return;
	}

	data = [OFData dataWithItems: "\x05\x01\x00" count: 3];

	_SOCKS5State = stateSendAuthentication;
	[_socket asyncWriteData: data
		    runLoopMode: [OFRunLoop currentRunLoop].currentMode];
}

-      (bool)stream: (OFStream *)sock
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	OFRunLoopMode runLoopMode;
	unsigned char *SOCKSVersion;
	uint8_t hostLength;
	unsigned char port[2];
	unsigned char *response, *addressLength;

	if (exception != nil) {
		_exception = objc_retain(exception);
		[self didConnect];
		return false;
	}

	runLoopMode = [OFRunLoop currentRunLoop].currentMode;

	switch (_SOCKS5State) {
	case stateReadVersion:
		SOCKSVersion = buffer;

		if (SOCKSVersion[0] != 5 || SOCKSVersion[1] != 0) {
			_exception = [[OFConnectIPSocketFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: self
				   errNo: EPROTONOSUPPORT];
			[self didConnect];
			return false;
		}

		objc_release(_request);
		_request = [[OFMutableData alloc] init];

		[_request addItems: "\x05\x01\x00\x03" count: 4];

		hostLength = (uint8_t)_host.UTF8StringLength;
		[_request addItem: &hostLength];
		[_request addItems: _host.UTF8String count: hostLength];

		port[0] = _port >> 8;
		port[1] = _port & 0xFF;
		[_request addItems: port count: 2];

		_SOCKS5State = stateSendRequest;
		[_socket asyncWriteData: _request runLoopMode: runLoopMode];
		return false;
	case stateReadResponse:
		response = buffer;

		if (response[0] != 5 || response[2] != 0) {
			_exception = [[OFConnectIPSocketFailedException alloc]
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

			_exception = [[OFConnectIPSocketFailedException alloc]
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
			_SOCKS5State = stateReadAddress;
			[_socket asyncReadIntoBuffer: _buffer
					 exactLength: 4 + 2
					 runLoopMode: runLoopMode];
			return false;
		case 3: /* Domain name */
			_SOCKS5State = stateReadAddressLength;
			[_socket asyncReadIntoBuffer: _buffer
					 exactLength: 1
					 runLoopMode: runLoopMode];
			return false;
		case 4: /* IPv6 */
			_SOCKS5State = stateReadAddress;
			[_socket asyncReadIntoBuffer: _buffer
					 exactLength: 16 + 2
					 runLoopMode: runLoopMode];
			return false;
		default:
			_exception = [[OFConnectIPSocketFailedException alloc]
			    initWithHost: _host
				    port: _port
				  socket: self
				   errNo: EPROTONOSUPPORT];
			[self didConnect];
			return false;
		}

		return false;
	case stateReadAddress:
		[self didConnect];
		return false;
	case stateReadAddressLength:
		addressLength = buffer;

		_SOCKS5State = stateReadAddress;
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: addressLength[0] + 2
				 runLoopMode: runLoopMode];
		return false;
	default:
		OFAssert(0);
		return false;
	}
}

- (OFData *)stream: (OFStream *)sock
      didWriteData: (OFData *)data
      bytesWritten: (size_t)bytesWritten
	 exception: (id)exception
{
	OFRunLoopMode runLoopMode;

	if (exception != nil) {
		_exception = objc_retain(exception);
		[self didConnect];
		return nil;
	}

	runLoopMode = [OFRunLoop currentRunLoop].currentMode;

	switch (_SOCKS5State) {
	case stateSendAuthentication:
		_SOCKS5State = stateReadVersion;
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: 2
				 runLoopMode: runLoopMode];
		return nil;
	case stateSendRequest:
		objc_release(_request);
		_request = nil;

		_SOCKS5State = stateReadResponse;
		[_socket asyncReadIntoBuffer: _buffer
				 exactLength: 4
				 runLoopMode: runLoopMode];
		return nil;
	default:
		OFAssert(0);
		return nil;
	}
}
@end
