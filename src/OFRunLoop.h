/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFObject.h"
#import "OFStream.h"
#import "OFStreamObserver.h"
#import "OFTCPSocket.h"

@class OFSortedList;
@class OFMutex;
@class OFTimer;
@class OFMutableDictionary;

/*!
 * @brief A class providing a run loop for the application and its processes.
 */
@interface OFRunLoop: OFObject
{
	OFSortedList *timersQueue;
	OFMutex *timersQueueLock;
	OFStreamObserver *streamObserver;
	OFMutableDictionary *readQueues;
}

/*!
 * @brief Returns the main run loop.
 *
 * @return The main run loop
 */
+ (OFRunLoop*)mainRunLoop;

/*!
 * @brief Returns the run loop for the current thread.
 *
 * @return The run loop for the current thread
 */
+ (OFRunLoop*)currentRunLoop;

+ (void)OF_setMainRunLoop;
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
#ifdef OF_HAVE_BLOCKS
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
				block: (of_tcpsocket_async_accept_block_t)block;
#endif

/*!
 * @brief Adds an OFTimer to the run loop.
 *
 * @param timer The timer to add
 */
- (void)addTimer: (OFTimer*)timer;

/*!
 * @brief Starts the run loop.
 */
- (void)run;
@end
