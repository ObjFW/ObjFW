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

#include "config.h"

#include <errno.h>

#import "OFSPXStreamSocket.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAlreadyOpenException.h"
#import "OFBindIPXSocketFailedException.h"
#import "OFConnectSPXSocketFailedException.h"
#import "OFNotOpenException.h"

#ifndef NSPROTO_SPX
# define NSPROTO_SPX 0
#endif

static const uint8_t SPXPacketType = 5;

OF_DIRECT_MEMBERS
@interface OFSPXStreamSocket ()
- (int)of_createSocketForAddress: (const OFSocketAddress *)address
			   errNo: (int *)errNo;
- (bool)of_connectSocketToAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo;
- (void)of_closeSocket;
@end

OF_DIRECT_MEMBERS
@interface OFSPXStreamSocketAsyncConnectDelegate: OFObject
    <OFRunLoopConnectDelegate>
{
	OFSPXStreamSocket *_socket;
	uint32_t _network;
	unsigned char _node[IPX_NODE_LEN];
	uint16_t _port;
#ifdef OF_HAVE_BLOCKS
	OFSPXStreamSocketConnectedHandler _handler;
#endif
}

- (instancetype)initWithSocket: (OFSPXStreamSocket *)socket
		       network: (uint32_t)network
			  node: (const unsigned char [IPX_NODE_LEN])node
			  port: (uint16_t)port
#ifdef OF_HAVE_BLOCKS
		       handler: (OFSPXStreamSocketConnectedHandler)handler
#endif
;
- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode;
@end

@implementation OFSPXStreamSocketAsyncConnectDelegate
- (instancetype)initWithSocket: (OFSPXStreamSocket *)sock
		       network: (uint32_t)network
			  node: (const unsigned char [IPX_NODE_LEN])node
			  port: (uint16_t)port
#ifdef OF_HAVE_BLOCKS
		       handler: (OFSPXStreamSocketConnectedHandler)handler
#endif
{
	self = [super init];

	@try {
		_socket = objc_retain(sock);
		_network = network;
		memcpy(_node, node, IPX_NODE_LEN);
		_port = port;
#ifdef OF_HAVE_BLOCKS
		_handler = [handler copy];
#endif
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_socket);
#ifdef OF_HAVE_BLOCKS
	objc_release(_handler);
#endif

	[super dealloc];
}

- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	OFSocketAddress address =
	    OFSocketAddressMakeIPX(_network, _node, _port);
	id exception = nil;
	int errNo;

	if (![_socket of_createSocketForAddress: &address errNo: &errNo]) {
		exception = [self of_connectionFailedExceptionForErrNo: errNo];
		goto inform_delegate;
	}

	_socket.canBlock = false;

	if (![_socket of_connectSocketToAddress: &address errNo: &errNo]) {
#ifdef OF_WINDOWS
		if (errNo == EINPROGRESS || errNo == EWOULDBLOCK) {
#else
		if (errNo == EINPROGRESS) {
#endif
			[OFRunLoop of_addAsyncConnectForSocket: _socket
							  mode: runLoopMode
						      delegate: self];
			return;
		}

		[_socket of_closeSocket];

		exception = [self of_connectionFailedExceptionForErrNo: errNo];
	}

inform_delegate:
	[self performSelector: @selector(of_socketDidConnect:exception:)
		   withObject: _socket
		   withObject: exception
		   afterDelay: 0];
}

- (void)of_socketDidConnect: (id)sock exception: (id)exception
{
	id <OFSPXStreamSocketDelegate> delegate =
	    ((OFSPXStreamSocket *)sock).delegate;

	if (exception == nil)
		((OFSPXStreamSocket *)sock).canBlock = true;

#ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		_handler(_socket, _network, _node, _port, exception);
	else {
#endif
		if ([delegate respondsToSelector:
		    @selector(socket:didConnectToNetwork:node:port:exception:)])
			[delegate	 socket: _socket
			    didConnectToNetwork: _network
					   node: _node
					   port: _port
				      exception: exception];
#ifdef OF_HAVE_BLOCKS
	}
#endif
}

- (id)of_connectionFailedExceptionForErrNo: (int)errNo
{
	return [OFConnectSPXSocketFailedException exceptionWithNetwork: _network
								  node: _node
								  port: _port
								socket: _socket
								 errNo: errNo];
}
@end

@implementation OFSPXStreamSocket
@dynamic delegate;

- (int)of_createSocketForAddress: (const OFSocketAddress *)address
			   errNo: (int *)errNo
{
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if ((_socket = socket(address->sockaddr.ipx.sipx_family,
	    SOCK_STREAM | SOCK_CLOEXEC, NSPROTO_SPX)) ==
	    OFInvalidSocketHandle) {
		*errNo = _OFSocketErrNo();
		return false;
	}

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	return true;
}

- (bool)of_connectSocketToAddress: (const OFSocketAddress *)address
			    errNo: (int *)errNo
{
	if (_socket == OFInvalidSocketHandle)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (connect(_socket, (struct sockaddr *)&address->sockaddr,
	    address->length) != 0) {
		*errNo = _OFSocketErrNo();
		return false;
	}

	return true;
}

- (void)of_closeSocket
{
	closesocket(_socket);
	_socket = OFInvalidSocketHandle;
}

- (void)connectToNetwork: (uint32_t)network
		    node: (const unsigned char [IPX_NODE_LEN])node
		    port: (uint16_t)port
{
	OFSocketAddress address = OFSocketAddressMakeIPX(network, node, port);
	int errNo;

	if (![self of_createSocketForAddress: &address errNo: &errNo])
		@throw [OFConnectSPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
				  socket: self
				   errNo: errNo];

	if (![self of_connectSocketToAddress: &address errNo: &errNo]) {
		[self of_closeSocket];

		@throw [OFConnectSPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
				  socket: self
				   errNo: errNo];
	}
}

- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [IPX_NODE_LEN])node
			 port: (uint16_t)port
{
	[self asyncConnectToNetwork: network
			       node: node
			       port: port
			runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [IPX_NODE_LEN])node
			 port: (uint16_t)port
		  runLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFSPXStreamSocketAsyncConnectDelegate alloc]
	    initWithSocket: self
		   network: network
		      node: node
		      port: port
#ifdef OF_HAVE_BLOCKS
		   handler: NULL
#endif
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [IPX_NODE_LEN])node
			 port: (uint16_t)port
			block: (OFSPXStreamSocketAsyncConnectBlock)block
{
	OFSPXStreamSocketConnectedHandler handler = ^ (
	    OFSPXStreamSocket *socket, uint32_t network_,
	    const unsigned char node_[IPX_NODE_LEN], uint16_t port_,
	    id exception) {
		block(exception);
	};

	[self asyncConnectToNetwork: network
			       node: node
			       port: port
			runLoopMode: OFDefaultRunLoopMode
			    handler: handler];
}

- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [IPX_NODE_LEN])node
			 port: (uint16_t)port
		      handler: (OFSPXStreamSocketConnectedHandler)handler
{
	[self asyncConnectToNetwork: network
			       node: node
			       port: port
			runLoopMode: OFDefaultRunLoopMode
			    handler: handler];
}

- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [IPX_NODE_LEN])node
			 port: (uint16_t)port
		  runLoopMode: (OFRunLoopMode)runLoopMode
			block: (OFSPXStreamSocketAsyncConnectBlock)block
{
	OFSPXStreamSocketConnectedHandler handler = ^ (
	    OFSPXStreamSocket *socket, uint32_t network_,
	    const unsigned char node_[IPX_NODE_LEN], uint16_t port_,
	    id exception) {
		block(exception);
	};

	[self asyncConnectToNetwork: network
			       node: node
			       port: port
			runLoopMode: runLoopMode
			    handler: handler];
}

- (void)asyncConnectToNetwork: (uint32_t)network
			 node: (const unsigned char [IPX_NODE_LEN])node
			 port: (uint16_t)port
		  runLoopMode: (OFRunLoopMode)runLoopMode
		      handler: (OFSPXStreamSocketConnectedHandler)handler
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFSPXStreamSocketAsyncConnectDelegate alloc]
	    initWithSocket: self
		   network: network
		      node: node
		      port: port
		   handler: handler
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFSocketAddress)bindToNetwork: (uint32_t)network
			    node: (const unsigned char [IPX_NODE_LEN])node
			    port: (uint16_t)port
{
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	address = OFSocketAddressMakeIPX(network, node, port);

	if ((_socket = socket(address.sockaddr.ipx.sipx_family,
	    SOCK_STREAM | SOCK_CLOEXEC, NSPROTO_SPX)) == OFInvalidSocketHandle)
		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: SPXPacketType
				  socket: self
				   errNo: _OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (bind(_socket, (struct sockaddr *)&address.sockaddr,
	    address.length) != 0) {
		int errNo = _OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: SPXPacketType
				  socket: self
				   errNo: errNo];
	}

	memset(&address, 0, sizeof(address));
	address.family = OFSocketAddressFamilyIPX;
	address.length = (socklen_t)sizeof(address.sockaddr);

	if (_OFGetSockName(_socket, (struct sockaddr *)&address.sockaddr,
	    &address.length) != 0) {
		int errNo = _OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: SPXPacketType
				  socket: self
				   errNo: errNo];
	}

	if (address.sockaddr.ipx.sipx_family != AF_IPX) {
		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindIPXSocketFailedException
		    exceptionWithNetwork: network
				    node: node
				    port: port
			      packetType: SPXPacketType
				  socket: self
				   errNo: EAFNOSUPPORT];
	}

	return address;
}
@end
