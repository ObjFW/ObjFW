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

#include <errno.h>

#import "OFSPXStreamSocket.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFSocket.h"
#import "OFSocket+Private.h"

#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"
#import "OFConnectionFailedException.h"
#import "OFNotOpenException.h"

#ifndef NSPROTO_SPX
# define NSPROTO_SPX 0
#endif

#define SPX_PACKET_TYPE 5

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
	unsigned char _node[IPX_NODE_LEN];
	uint32_t _network;
	uint16_t _port;
#ifdef OF_HAVE_BLOCKS
	OFSPXStreamSocketAsyncConnectBlock _block;
#endif
}

- (instancetype)initWithSocket: (OFSPXStreamSocket *)socket
			  node: (unsigned char [IPX_NODE_LEN])node
		       network: (uint32_t)network
			  port: (uint16_t)port
#ifdef OF_HAVE_BLOCKS
			 block: (OFSPXStreamSocketAsyncConnectBlock)block
#endif
;
- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode;
@end

@implementation OFSPXStreamSocketAsyncConnectDelegate
- (instancetype)initWithSocket: (OFSPXStreamSocket *)sock
			  node: (unsigned char [IPX_NODE_LEN])node
		       network: (uint32_t)network
			  port: (uint16_t)port
#ifdef OF_HAVE_BLOCKS
			 block: (OFSPXStreamSocketAsyncConnectBlock)block
#endif
{
	self = [super init];

	@try {
		_socket = [sock retain];
		memcpy(_node, node, IPX_NODE_LEN);
		_network = network;
		_port = port;
#ifdef OF_HAVE_BLOCKS
		_block = [block copy];
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_socket release];
#ifdef OF_HAVE_BLOCKS
	[_block release];
#endif

	[super dealloc];
}

- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	OFSocketAddress address =
	    OFSocketAddressMakeIPX(_node, _network, _port);
	id exception = nil;
	int errNo;

	if (![_socket of_createSocketForAddress: &address errNo: &errNo]) {
		exception = [self of_connectionFailedExceptionForErrNo: errNo];
		goto inform_delegate;
	}

	_socket.canBlock = false;

	if (![_socket of_connectSocketToAddress: &address errNo: &errNo]) {
		if (errNo == EINPROGRESS) {
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
	if (_block != NULL)
		_block(exception);
	else {
#endif
		if ([delegate respondsToSelector:
		    @selector(socket:didConnectToNode:network:port:exception:)])
			[delegate     socket: _socket
			    didConnectToNode: _node
				     network: _network
					port: _port
				   exception: exception];
#ifdef OF_HAVE_BLOCKS
	}
#endif
}

- (id)of_connectionFailedExceptionForErrNo: (int)errNo
{
	return [OFConnectionFailedException exceptionWithNode: _node
						      network: _network
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
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	if ((_socket = socket(address->sockaddr.ipx.sipx_family,
	    SOCK_SEQPACKET | SOCK_CLOEXEC, NSPROTO_SPX)) ==
	    OFInvalidSocketHandle) {
		*errNo = OFSocketErrNo();
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

	if (connect(_socket, &address->sockaddr.sockaddr,
	    address->length) != 0) {
		*errNo = OFSocketErrNo();
		return false;
	}

	return true;
}

- (void)of_closeSocket
{
	closesocket(_socket);
	_socket = OFInvalidSocketHandle;
}

- (void)connectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
	      network: (uint32_t)network
		 port: (uint16_t)port
{
	OFSocketAddress address = OFSocketAddressMakeIPX(node, network, port);
	int errNo;

	if (![self of_createSocketForAddress: &address errNo: &errNo])
		@throw [OFConnectionFailedException
		    exceptionWithNode: node
			      network: network
				 port: port
			       socket: self
				errNo: errNo];

	if (![self of_connectSocketToAddress: &address errNo: &errNo]) {
		[self of_closeSocket];

		@throw [OFConnectionFailedException
		    exceptionWithNode: node
			      network: network
				 port: port
			       socket: self
				errNo: errNo];
	}
}

- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port
{
	[self asyncConnectToNode: node
			 network: network
			    port: port
		     runLoopMode: OFDefaultRunLoopMode];
}

- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFSPXStreamSocketAsyncConnectDelegate alloc]
	    initWithSocket: self
		      node: node
		   network: network
		      port: port
#ifdef OF_HAVE_BLOCKS
		     block: NULL
#endif
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port
		     block: (OFSPXStreamSocketAsyncConnectBlock)block
{
	[self asyncConnectToNode: node
			 network: network
			    port: port
		     runLoopMode: OFDefaultRunLoopMode
			   block: block];
}

- (void)asyncConnectToNode: (unsigned char [_Nonnull IPX_NODE_LEN])node
		   network: (uint32_t)network
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFSPXStreamSocketAsyncConnectBlock)block
{
	void *pool = objc_autoreleasePoolPush();

	[[[[OFSPXStreamSocketAsyncConnectDelegate alloc]
	    initWithSocket: self
		      node: node
		   network: network
		      port: port
		     block: block
	    ] autorelease] startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}
#endif

- (OFSocketAddress)bindToPort: (uint16_t)port
{
	const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
	OFSocketAddress address;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	int flags;
#endif

	if (_socket != OFInvalidSocketHandle)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	address = OFSocketAddressMakeIPX(zeroNode, 0, port);

	if ((_socket = socket(address.sockaddr.sockaddr.sa_family,
	    SOCK_STREAM | SOCK_CLOEXEC, NSPROTO_SPX)) == OFInvalidSocketHandle)
		@throw [OFBindFailedException
		    exceptionWithPort: port
			   packetType: SPX_PACKET_TYPE
			       socket: self
				errNo: OFSocketErrNo()];

	_canBlock = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL_H) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

	if (bind(_socket, &address.sockaddr.sockaddr, address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindFailedException exceptionWithPort: port
						     packetType: SPX_PACKET_TYPE
							 socket: self
							  errNo: errNo];
	}

	memset(&address, 0, sizeof(address));
	address.family = OFSocketAddressFamilyIPX;
	address.length = (socklen_t)sizeof(address.sockaddr);

	if (OFGetSockName(_socket, &address.sockaddr.sockaddr,
	    &address.length) != 0) {
		int errNo = OFSocketErrNo();

		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindFailedException exceptionWithPort: port
						     packetType: SPX_PACKET_TYPE
							 socket: self
							  errNo: errNo];
	}

	if (address.sockaddr.sockaddr.sa_family != AF_IPX) {
		closesocket(_socket);
		_socket = OFInvalidSocketHandle;

		@throw [OFBindFailedException exceptionWithPort: port
						     packetType: SPX_PACKET_TYPE
							 socket: self
							  errNo: EAFNOSUPPORT];
	}

	return address;
}
@end
