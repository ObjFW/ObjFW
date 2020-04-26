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

#import "OFRunLoop.h"
#import "OFStream.h"
#ifdef OF_HAVE_SOCKETS
# import "OFDatagramSocket.h"
# import "OFSequencedPacketSocket.h"
# import "OFTCPSocket.h"
#endif

OF_ASSUME_NONNULL_BEGIN

#ifdef OF_HAVE_SOCKETS
@protocol OFTCPSocketDelegate_Private <OFObject>
- (void)of_socketDidConnect: (OFTCPSocket *)socket
		  exception: (nullable id)exception;
@end
#endif

@interface OFRunLoop ()
+ (void)of_setMainRunLoop: (OFRunLoop *)runLoop;
#ifdef OF_HAVE_SOCKETS
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
			  length: (size_t)length
			    mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			   block: (nullable of_stream_async_read_block_t)block
# endif
			delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
		     exactLength: (size_t)length
			    mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			   block: (nullable of_stream_async_read_block_t)block
# endif
			delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncReadLineForStream: (OFStream <OFReadyForReadingObserving> *)
					  stream
			    encoding: (of_string_encoding_t)encoding
				mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			       block: (nullable
					  of_stream_async_read_line_block_t)
					  block
# endif
			    delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			     data: (OFData *)data
			     mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			    block: (nullable of_stream_async_write_data_block_t)
				       block
# endif
			 delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			   string: (OFString *)string
			 encoding: (of_string_encoding_t)encoding
			     mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			    block: (nullable
				       of_stream_async_write_string_block_t)
				       block
# endif
			 delegate: (nullable id <OFStreamDelegate>)delegate;
# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
+ (void)of_addAsyncConnectForTCPSocket: (OFTCPSocket *)socket
				  mode: (of_run_loop_mode_t)mode
			      delegate: (id <OFTCPSocketDelegate_Private>)
					    delegate;
# endif
+ (void)of_addAsyncAcceptForSocket: (id)socket
			      mode: (of_run_loop_mode_t)mode
			     block: (nullable id)block
			  delegate: (nullable id)delegate;
+ (void)of_addAsyncReceiveForDatagramSocket: (OFDatagramSocket *)socket
    buffer: (void *)buffer
    length: (size_t)length
      mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable of_datagram_socket_async_receive_block_t)block
# endif
  delegate: (nullable id <OFDatagramSocketDelegate>) delegate;
+ (void)of_addAsyncSendForDatagramSocket: (OFDatagramSocket *)socket
      data: (OFData *)data
  receiver: (const of_socket_address_t *)receiver
      mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable of_datagram_socket_async_send_data_block_t)block
# endif
  delegate: (nullable id <OFDatagramSocketDelegate>)delegate;
+ (void)of_addAsyncReceiveForSequencedPacketSocket:
					       (OFSequencedPacketSocket *)socket
    buffer: (void *)buffer
    length: (size_t)length
      mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable of_sequenced_packet_socket_async_receive_block_t)block
# endif
  delegate: (nullable id <OFSequencedPacketSocketDelegate>) delegate;
+ (void)of_addAsyncSendForSequencedPacketSocket:
					       (OFSequencedPacketSocket *)socket
      data: (OFData *)data
      mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable of_sequenced_packet_socket_async_send_data_block_t)block
# endif
  delegate: (nullable id <OFSequencedPacketSocketDelegate>)delegate;
+ (void)of_cancelAsyncRequestsForObject: (id)object
				   mode: (of_run_loop_mode_t)mode;
#endif
- (void)of_removeTimer: (OFTimer *)timer
	       forMode: (of_run_loop_mode_t)mode;
@end

OF_ASSUME_NONNULL_END
