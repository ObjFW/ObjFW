/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
# import "OFStreamSocket.h"
#endif

OF_ASSUME_NONNULL_BEGIN

#ifdef OF_HAVE_SOCKETS
@protocol OFRunLoopConnectDelegate <OFObject>
- (void)of_socketDidConnect: (id)socket
		  exception: (nullable id)exception;
- (id)of_connectionFailedExceptionForErrNo: (int)errNo;
@end
#endif

OF_DIRECT_MEMBERS
@interface OFRunLoop ()
+ (void)of_setMainRunLoop: (OFRunLoop *)runLoop;
#ifdef OF_HAVE_SOCKETS
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
			  length: (size_t)length
			    mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			   block: (nullable OFStreamAsyncReadBlock)block
# endif
			delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
		     exactLength: (size_t)length
			    mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			   block: (nullable OFStreamAsyncReadBlock)block
# endif
			delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncReadLineForStream: (OFStream <OFReadyForReadingObserving> *)
					  stream
			    encoding: (OFStringEncoding)encoding
				mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			       block: (nullable OFStreamAsyncReadLineBlock)block
# endif
			    delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			     data: (OFData *)data
			     mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			    block: (nullable OFStreamAsyncWriteDataBlock)block
# endif
			 delegate: (nullable id <OFStreamDelegate>)delegate;
+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			   string: (OFString *)string
			 encoding: (OFStringEncoding)encoding
			     mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			    block: (nullable OFStreamAsyncWriteStringBlock)block
# endif
			 delegate: (nullable id <OFStreamDelegate>)delegate;
# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
+ (void)of_addAsyncConnectForSocket: (id)socket
			       mode: (OFRunLoopMode)mode
			   delegate: (id <OFRunLoopConnectDelegate>)delegate;
# endif
+ (void)of_addAsyncAcceptForSocket: (id)socket
			      mode: (OFRunLoopMode)mode
			     block: (nullable id)block
			  delegate: (nullable id)delegate;
+ (void)of_addAsyncReceiveForDatagramSocket: (OFDatagramSocket *)socket
    buffer: (void *)buffer
    length: (size_t)length
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable OFDatagramSocketAsyncReceiveBlock)block
# endif
  delegate: (nullable id <OFDatagramSocketDelegate>) delegate;
+ (void)of_addAsyncSendForDatagramSocket: (OFDatagramSocket *)socket
      data: (OFData *)data
  receiver: (const OFSocketAddress *)receiver
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable OFDatagramSocketAsyncSendDataBlock)block
# endif
  delegate: (nullable id <OFDatagramSocketDelegate>)delegate;
+ (void)of_addAsyncReceiveForSequencedPacketSocket:
					       (OFSequencedPacketSocket *)socket
    buffer: (void *)buffer
    length: (size_t)length
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable OFSequencedPacketSocketAsyncReceiveBlock)block
# endif
  delegate: (nullable id <OFSequencedPacketSocketDelegate>) delegate;
+ (void)of_addAsyncSendForSequencedPacketSocket:
					       (OFSequencedPacketSocket *)socket
      data: (OFData *)data
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
     block: (nullable OFSequencedPacketSocketAsyncSendDataBlock)block
# endif
  delegate: (nullable id <OFSequencedPacketSocketDelegate>)delegate;
+ (void)of_cancelAsyncRequestsForObject: (id)object mode: (OFRunLoopMode)mode;
#endif
- (void)of_removeTimer: (OFTimer *)timer forMode: (OFRunLoopMode)mode;
@end

OF_ASSUME_NONNULL_END
