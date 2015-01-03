/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFRunLoop.h"
#import "OFStream.h"
#ifdef OF_HAVE_SOCKETS
# import "OFUDPSocket.h"
#endif

@interface OFRunLoop (OF_PRIVATE_CATEGORY)
+ (void)OF_setMainRunLoop: (OFRunLoop*)runLoop;
#ifdef OF_HAVE_SOCKETS
+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
			  length: (size_t)length
			  target: (id)target
			selector: (SEL)selector;
+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
		     exactLength: (size_t)length
			  target: (id)target
			selector: (SEL)selector;
+ (void)OF_addAsyncReadLineForStream: (OFStream*)stream
			    encoding: (of_string_encoding_t)encoding
			      target: (id)target
			    selector: (SEL)selector;
+ (void)OF_addAsyncAcceptForTCPSocket: (OFTCPSocket*)socket
			       target: (id)target
			     selector: (SEL)selector;
+ (void)OF_addAsyncReceiveForUDPSocket: (OFUDPSocket*)socket
				buffer: (void*)buffer
				length: (size_t)length
				target: (id)target
			      selector: (SEL)selector;
# ifdef OF_HAVE_BLOCKS
+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
			  length: (size_t)length
			   block: (of_stream_async_read_block_t)block;
+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
		     exactLength: (size_t)length
			   block: (of_stream_async_read_block_t)block;
+ (void)OF_addAsyncReadLineForStream: (OFStream*)stream
			    encoding: (of_string_encoding_t)encoding
			       block: (of_stream_async_read_line_block_t)block;
+ (void)OF_addAsyncAcceptForTCPSocket: (OFTCPSocket*)socket
				block: (of_tcp_socket_async_accept_block_t)
					   block;
+ (void)OF_addAsyncReceiveForUDPSocket: (OFUDPSocket*)socket
				buffer: (void*)buffer
				length: (size_t)length
				 block: (of_udp_socket_async_receive_block_t)
					    block;
# endif
+ (void)OF_cancelAsyncRequestsForObject: (id)object;
#endif
- (void)OF_removeTimer: (OFTimer*)timer;
@end
