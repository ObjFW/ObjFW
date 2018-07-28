/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFRunLoop.h"
#import "OFStream.h"
#ifdef OF_HAVE_SOCKETS
# import "OFUDPSocket.h"
#endif

OF_ASSUME_NONNULL_BEGIN

@interface OFRunLoop ()
+ (void)of_setMainRunLoop: (OFRunLoop *)runLoop;
#ifdef OF_HAVE_SOCKETS
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
			  length: (size_t)length
			  target: (id)target
			selector: (SEL)selector
			 context: (nullable id)context;
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
		     exactLength: (size_t)length
			  target: (id)target
			selector: (SEL)selector
			 context: (nullable id)context;
+ (void)of_addAsyncReadLineForStream: (OFStream <OFReadyForReadingObserving> *)
					  stream
			    encoding: (of_string_encoding_t)encoding
			      target: (id)target
			    selector: (SEL)selector
			     context: (nullable id)context;
+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			   buffer: (const void *)buffer
			   length: (size_t)length
			   target: (id)target
			 selector: (SEL)selector
			  context: (nullable id)context;
+ (void)of_addAsyncAcceptForTCPSocket: (OFTCPSocket *)socket
			       target: (id)target
			     selector: (SEL)selector
			      context: (nullable id)context;
+ (void)of_addAsyncReceiveForUDPSocket: (OFUDPSocket *)socket
				buffer: (void *)buffer
				length: (size_t)length
				target: (id)target
			      selector: (SEL)selector
			       context: (nullable id)context;
+ (void)of_addAsyncSendForUDPSocket: (OFUDPSocket *)socket
			     buffer: (const void *)buffer
			     length: (size_t)length
			   receiver: (of_socket_address_t)receiver
			     target: (id)target
			   selector: (SEL)selector
			    context: (nullable id)context;
# ifdef OF_HAVE_BLOCKS
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
			  length: (size_t)length
			   block: (of_stream_async_read_block_t)block;
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
		     exactLength: (size_t)length
			   block: (of_stream_async_read_block_t)block;
+ (void)of_addAsyncReadLineForStream: (OFStream <OFReadyForReadingObserving> *)
					  stream
			    encoding: (of_string_encoding_t)encoding
			       block: (of_stream_async_read_line_block_t)block;
+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			   buffer: (const void *)buffer
			   length: (size_t)length
			    block: (of_stream_async_write_block_t)block;
+ (void)of_addAsyncAcceptForTCPSocket: (OFTCPSocket *)socket
				block: (of_tcp_socket_async_accept_block_t)
					   block;
+ (void)of_addAsyncReceiveForUDPSocket: (OFUDPSocket *)socket
				buffer: (void *)buffer
				length: (size_t)length
				 block: (of_udp_socket_async_receive_block_t)
					    block;
+ (void)of_addAsyncSendForUDPSocket: (OFUDPSocket *)socket
			     buffer: (const void *)buffer
			     length: (size_t)length
			   receiver: (of_socket_address_t)receiver
			      block: (of_udp_socket_async_send_block_t)block;
# endif
+ (void)of_cancelAsyncRequestsForObject: (id)object;
#endif
- (void)of_removeTimer: (OFTimer *)timer;
@end

OF_ASSUME_NONNULL_END
