/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
#include <string.h>

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif

#import "OFUDPSocket.h"
#import "OFUDPSocket+Private.h"
#import "OFDNSResolver.h"
#import "OFData.h"
#import "OFRunLoop+Private.h"
#import "OFRunLoop.h"
#import "OFThread.h"

#import "OFAlreadyConnectedException.h"
#import "OFBindFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFSetOptionFailedException.h"
#import "OFWriteFailedException.h"

#import "socket.h"
#import "socket_helpers.h"

@implementation OFUDPSocket
@synthesize delegate = _delegate;

+ (void)initialize
{
	if (self != [OFUDPSocket class])
		return;

	if (!of_socket_init())
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (instancetype)socket
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	_socket = INVALID_SOCKET;
	_blocking = true;

	return self;
}

- (void)dealloc
{
	if (_socket != INVALID_SOCKET)
		[self close];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (bool)isBlocking
{
	return _blocking;
}

- (void)setBlocking: (bool)enable
{
#if defined(HAVE_FCNTL)
	int flags = fcntl(_socket, F_GETFL, 0);

	if (flags == -1)
		@throw [OFSetOptionFailedException exceptionWithObject: self
								 errNo: errno];

	if (enable)
		flags &= ~O_NONBLOCK;
	else
		flags |= O_NONBLOCK;

	if (fcntl(_socket, F_SETFL, flags) == -1)
		@throw [OFSetOptionFailedException exceptionWithObject: self
								 errNo: errno];

	_blocking = enable;
#elif defined(OF_WINDOWS)
	u_long v = enable;

	if (ioctlsocket(_socket, FIONBIO, &v) == SOCKET_ERROR)
		@throw [OFSetOptionFailedException
		    exceptionWithObject: self
				  errNo: of_socket_errno()];

	_blocking = enable;
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (uint16_t)of_bindToAddress: (of_socket_address_t *)address
		   extraType: (int)extraType
{
	void *pool = objc_autoreleasePoolPush();
	OFString *host;
	uint16_t port;
#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	int flags;
#endif

	if ((_socket = socket(address->sockaddr.sockaddr.sa_family,
	    SOCK_DGRAM | SOCK_CLOEXEC | extraType, 0)) == INVALID_SOCKET) {
		host = of_socket_address_ip_string(address, &port);
		@throw [OFBindFailedException
		    exceptionWithHost: host
				 port: port
			       socket: self
				errNo: of_socket_errno()];
	}

	_blocking = true;

#if SOCK_CLOEXEC == 0 && defined(HAVE_FCNTL) && defined(FD_CLOEXEC)
	if ((flags = fcntl(_socket, F_GETFD, 0)) != -1)
		fcntl(_socket, F_SETFD, flags | FD_CLOEXEC);
#endif

#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	if (of_socket_address_get_port(address) != 0) {
#endif
		if (bind(_socket, &address->sockaddr.sockaddr,
		    address->length) != 0) {
			int errNo = of_socket_errno();

			closesocket(_socket);
			_socket = INVALID_SOCKET;

			host = of_socket_address_ip_string(address, &port);
			@throw [OFBindFailedException exceptionWithHost: host
								   port: port
								 socket: self
								  errNo: errNo];
		}
#if defined(OF_WII) || defined(OF_NINTENDO_3DS)
	} else {
		for (;;) {
			uint16_t rnd = 0;
			int ret;

			while (rnd < 1024)
				rnd = (uint16_t)rand();

			of_socket_address_set_port(address, rnd);

			if ((ret = bind(_socket, &address->sockaddr.sockaddr,
			    address->length)) == 0) {
				port = rnd;
				break;
			}

			if (of_socket_errno() != EADDRINUSE) {
				int errNo = of_socket_errno();

				closesocket(_socket);
				_socket = INVALID_SOCKET;

				host = of_socket_address_ip_string(
				    address, &port);
				@throw [OFBindFailedException
				    exceptionWithHost: host
						 port: port
					       socket: self
						errNo: errNo];
			}
		}
	}
#endif

	objc_autoreleasePoolPop(pool);

	if ((port = of_socket_address_get_port(address)) > 0)
		return port;

#if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
	memset(address, 0, sizeof(*address));

	address->length = (socklen_t)sizeof(address->sockaddr);
	if (of_getsockname(_socket, &address->sockaddr.sockaddr,
	    &address->length) != 0) {
		int errNo = of_socket_errno();

		closesocket(_socket);
		_socket = INVALID_SOCKET;

		host = of_socket_address_ip_string(address, &port);
		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: errNo];
	}

	if (address->sockaddr.sockaddr.sa_family == AF_INET)
		return OF_BSWAP16_IF_LE(address->sockaddr.in.sin_port);
# ifdef OF_HAVE_IPV6
	else if (address->sockaddr.sockaddr.sa_family == AF_INET6)
		return OF_BSWAP16_IF_LE(address->sockaddr.in6.sin6_port);
# endif
	else {
		closesocket(_socket);
		_socket = INVALID_SOCKET;

		host = of_socket_address_ip_string(address, &port);
		@throw [OFBindFailedException exceptionWithHost: host
							   port: port
							 socket: self
							  errNo: EAFNOSUPPORT];
	}
#else
	closesocket(_socket);
	_socket = INVALID_SOCKET;

	host = of_socket_address_ip_string(address, &port);
	@throw [OFBindFailedException exceptionWithHost: host
						   port: port
						 socket: self
						  errNo: EADDRNOTAVAIL];
#endif
}

- (uint16_t)bindToHost: (OFString *)host
		  port: (uint16_t)port
{
	void *pool = objc_autoreleasePoolPush();
	OFData *socketAddresses;
	of_socket_address_t address;

	if (_socket != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithSocket: self];

	socketAddresses = [[OFThread DNSResolver]
	    resolveSocketAddressesForHost: host
			    addressFamily: OF_SOCKET_ADDRESS_FAMILY_ANY];

	address = *(of_socket_address_t *)[socketAddresses itemAtIndex: 0];
	of_socket_address_set_port(&address, port);

	port = [self of_bindToAddress: &address
			    extraType: 0];

	objc_autoreleasePoolPop(pool);

	return port;
}

- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (of_socket_address_t *)sender
{
	ssize_t ret;

	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	sender->length = (socklen_t)sizeof(sender->sockaddr);

#ifndef OF_WINDOWS
	if ((ret = recvfrom(_socket, buffer, length, 0,
	    &sender->sockaddr.sockaddr, &sender->length)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#else
	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((ret = recvfrom(_socket, buffer, (int)length, 0,
	    &sender->sockaddr.sockaddr, &sender->length)) < 0)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: length
				  errNo: of_socket_errno()];
#endif

	switch (sender->sockaddr.sockaddr.sa_family) {
	case AF_INET:
		sender->family = OF_SOCKET_ADDRESS_FAMILY_IPV4;
		break;
#ifdef OF_HAVE_IPV6
	case AF_INET6:
		sender->family = OF_SOCKET_ADDRESS_FAMILY_IPV6;
		break;
#endif
	default:
		sender->family = OF_SOCKET_ADDRESS_FAMILY_UNKNOWN;
		break;
	}

	return ret;
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
{
	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: of_run_loop_mode_default];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	[OFRunLoop of_addAsyncReceiveForUDPSocket: self
					   buffer: buffer
					   length: length
					     mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					    block: NULL
# endif
					 delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			 block: (of_udp_socket_async_receive_block_t)block
{
	[self asyncReceiveIntoBuffer: buffer
			      length: length
			 runLoopMode: of_run_loop_mode_default
			       block: block];
}

- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (of_run_loop_mode_t)runLoopMode
			 block: (of_udp_socket_async_receive_block_t)block
{
	[OFRunLoop of_addAsyncReceiveForUDPSocket: self
					   buffer: buffer
					   length: length
					     mode: runLoopMode
					    block: block
					 delegate: nil];
}
#endif

- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const of_socket_address_t *)receiver
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

#ifndef OF_WINDOWS
	ssize_t bytesWritten;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = sendto(_socket, (void *)buffer, length, 0,
	    (struct sockaddr *)&receiver->sockaddr.sockaddr,
	    receiver->length)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: of_socket_errno()];
#else
	int bytesWritten;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	if ((bytesWritten = sendto(_socket, buffer, (int)length, 0,
	    &receiver->sockaddr.sockaddr, receiver->length)) < 0)
		@throw [OFWriteFailedException
		    exceptionWithObject: self
			requestedLength: length
			   bytesWritten: 0
				  errNo: of_socket_errno()];
#endif

	if ((size_t)bytesWritten != length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: 0];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver
{
	[self asyncSendData: data
		   receiver: receiver
		runLoopMode: of_run_loop_mode_default];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver
	  runLoopMode: (of_run_loop_mode_t)runLoopMode
{
	[OFRunLoop of_addAsyncSendForUDPSocket: self
					  data: data
				      receiver: receiver
					  mode: runLoopMode
# ifdef OF_HAVE_BLOCKS
					 block: NULL
# endif
				      delegate: _delegate];
}

#ifdef OF_HAVE_BLOCKS
- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver
		block: (of_udp_socket_async_send_data_block_t)block
{
	[self asyncSendData: data
		   receiver: receiver
		runLoopMode: of_run_loop_mode_default
		      block: block];
}

- (void)asyncSendData: (OFData *)data
	     receiver: (const of_socket_address_t *)receiver
	  runLoopMode: (of_run_loop_mode_t)runLoopMode
		block: (of_udp_socket_async_send_data_block_t)block
{
	[OFRunLoop of_addAsyncSendForUDPSocket: self
					  data: data
				      receiver: receiver
					  mode: runLoopMode
					 block: block
				      delegate: nil];
}
#endif

- (void)cancelAsyncRequests
{
	[OFRunLoop of_cancelAsyncRequestsForObject: self
					      mode: of_run_loop_mode_default];
}

- (int)fileDescriptorForReading
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (int)fileDescriptorForWriting
{
#ifndef OF_WINDOWS
	return _socket;
#else
	if (_socket == INVALID_SOCKET)
		return -1;

	if (_socket > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)_socket;
#endif
}

- (void)close
{
	if (_socket == INVALID_SOCKET)
		@throw [OFNotOpenException exceptionWithObject: self];

	closesocket(_socket);
	_socket = INVALID_SOCKET;
}
@end
