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

#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFData.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_SOCKETS
# import "OFKernelEventObserver.h"
# import "OFTCPSocket.h"
# import "OFTCPSocket+Private.h"
#endif
#import "OFThread.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
# import "OFCondition.h"
#endif
#import "OFSortedList.h"
#import "OFTimer.h"
#import "OFTimer+Private.h"
#import "OFDate.h"

#import "OFObserveFailedException.h"
#ifdef OF_HAVE_SOCKETS
# import "OFConnectionFailedException.h"
#endif

of_run_loop_mode_t of_run_loop_mode_default = @"of_run_loop_mode_default";
static OFRunLoop *mainRunLoop = nil;

@interface OFRunLoopState: OFObject
#ifdef OF_HAVE_SOCKETS
    <OFKernelEventObserverDelegate>
#endif
{
@public
	OFSortedList OF_GENERIC(OFTimer *) *_timersQueue;
#ifdef OF_HAVE_THREADS
	OFMutex *_timersQueueMutex;
#endif
#if defined(OF_HAVE_SOCKETS)
	OFKernelEventObserver *_kernelEventObserver;
	OFMutableDictionary *_readQueues, *_writeQueues;
#elif defined(OF_HAVE_THREADS)
	OFCondition *_condition;
#endif
}
@end

@interface OFRunLoop ()
- (OFRunLoopState *)of_stateForMode: (of_run_loop_mode_t)mode
			     create: (bool)create;
@end

#ifdef OF_HAVE_SOCKETS
@interface OFRunLoopQueueItem: OFObject
{
@public
	id _delegate;
}

- (bool)handleObject: (id)object;
@end

@interface OFRunLoopReadQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_read_block_t _block;
# endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoopExactReadQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_read_block_t _block;
# endif
	void *_buffer;
	size_t _exactLength, _readLength;
}
@end

@interface OFRunLoopReadLineQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_read_line_block_t _block;
# endif
	of_string_encoding_t _encoding;
}
@end

@interface OFRunLoopWriteDataQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_write_data_block_t _block;
# endif
	OFData *_data;
	size_t _writtenLength;
}
@end

@interface OFRunLoopWriteStringQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_write_string_block_t _block;
# endif
	OFString *_string;
	of_string_encoding_t _encoding;
	size_t _writtenLength;
}
@end

# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
@interface OFRunLoopConnectQueueItem: OFRunLoopQueueItem
@end
# endif

@interface OFRunLoopAcceptQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_tcp_socket_async_accept_block_t _block;
# endif
}
@end

@interface OFRunLoopUDPReceiveQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_udp_socket_async_receive_block_t _block;
# endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoopUDPSendQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_udp_socket_async_send_data_block_t _block;
# endif
	OFData *_data;
	of_socket_address_t _receiver;
}
@end
#endif

@implementation OFRunLoopState
- (instancetype)init
{
	self = [super init];

	@try {
		_timersQueue = [[OFSortedList alloc] init];

#if defined(OF_HAVE_SOCKETS)
		_kernelEventObserver = [[OFKernelEventObserver alloc] init];
		_kernelEventObserver.delegate = self;

		_readQueues = [[OFMutableDictionary alloc] init];
		_writeQueues = [[OFMutableDictionary alloc] init];
#elif defined(OF_HAVE_THREADS)
		_condition = [[OFCondition alloc] init];
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_timersQueue release];
#if defined(OF_HAVE_SOCKETS)
	[_kernelEventObserver release];
	[_readQueues release];
	[_writeQueues release];
#elif defined(OF_HAVE_THREADS)
	[_condition release];
#endif

	[super dealloc];
}

#ifdef OF_HAVE_SOCKETS
- (void)objectIsReadyForReading: (id)object
{
	/*
	 * Retain the queue so that it doesn't disappear from us because the
	 * handler called -[cancelAsyncRequests].
	 */
	OFList OF_GENERIC(OF_KINDOF(OFRunLoopReadQueueItem *)) *queue =
	    [[_readQueues objectForKey: object] retain];

	assert(queue != nil);

	@try {
		if (![queue.firstObject handleObject: object]) {
			of_list_object_t *listObject = queue.firstListObject;

			/*
			 * The handler might have called -[cancelAsyncRequests]
			 * so that our queue is now empty, in which case we
			 * should do nothing.
			 */
			if (listObject != NULL) {
				/*
				 * Make sure we keep the target until after we
				 * are done removing the object. The reason for
				 * this is that the target might call
				 * -[cancelAsyncRequests] in its dealloc.
				 */
				[[listObject->object retain] autorelease];

				[queue removeListObject: listObject];

				if (queue.count == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
		}
	} @finally {
		[queue release];
	}
}

- (void)objectIsReadyForWriting: (id)object
{
	/*
	 * Retain the queue so that it doesn't disappear from us because the
	 * handler called -[cancelAsyncRequests].
	 */
	OFList *queue = [[_writeQueues objectForKey: object] retain];

	assert(queue != nil);

	@try {
		if (![queue.firstObject handleObject: object]) {
			of_list_object_t *listObject = queue.firstListObject;

			/*
			 * The handler might have called -[cancelAsyncRequests]
			 * so that our queue is now empty, in which case we
			 * should do nothing.
			 */
			if (listObject != NULL) {
				/*
				 * Make sure we keep the target until after we
				 * are done removing the object. The reason for
				 * this is that the target might call
				 * -[cancelAsyncRequests] in its dealloc.
				 */
				[[listObject->object retain] autorelease];

				[queue removeListObject: listObject];

				if (queue.count == 0) {
					[_kernelEventObserver
					    removeObjectForWriting: object];
					[_writeQueues
					    removeObjectForKey: object];
				}
			}
		}
	} @finally {
		[queue release];
	}
}
#endif
@end

#ifdef OF_HAVE_SOCKETS
@implementation OFRunLoopQueueItem
- (bool)handleObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)dealloc
{
	[_delegate release];

	[super dealloc];
}
@end

@implementation OFRunLoopReadQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;

	@try {
		length = [object readIntoBuffer: _buffer
					 length: _length];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		return _block(object, _buffer, length, exception);
	else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didReadIntoBuffer:length:exception:)])
			return false;

		return [_delegate stream: object
		       didReadIntoBuffer: _buffer
				  length: length
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopExactReadQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;

	@try {
		length = [object readIntoBuffer: (char *)_buffer + _readLength
					 length: _exactLength - _readLength];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

	_readLength += length;

	if (_readLength != _exactLength && ![object isAtEndOfStream] &&
	    exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL) {
		if (!_block(object, _buffer, _readLength, exception))
			return false;

		_readLength = 0;
		return true;
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didReadIntoBuffer:length:exception:)])
			return false;

		if (![_delegate stream: object
		     didReadIntoBuffer: _buffer
				length: _readLength
			     exception: exception])
			return false;

		_readLength = 0;
		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopReadLineQueueItem
- (bool)handleObject: (id)object
{
	OFString *line;
	id exception = nil;

	@try {
		line = [object tryReadLineWithEncoding: _encoding];
	} @catch (id e) {
		line = nil;
		exception = e;
	}

	if (line == nil && ![object isAtEndOfStream] && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		return _block(object, line, exception);
	else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didReadLine:exception:)])
			return false;

		return [_delegate stream: object
			     didReadLine: line
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopWriteDataQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;
	size_t dataLength = _data.count * _data.itemSize;
	OFData *newData, *oldData;

	@try {
		const char *dataItems = _data.items;

		length = [object writeBuffer: dataItems + _writtenLength
				      length: dataLength - _writtenLength];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

	_writtenLength += length;

	if (_writtenLength != dataLength && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL) {
		newData = _block(object, _data, _writtenLength, exception);

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		[oldData release];

		_writtenLength = 0;
		return true;
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didWriteData:bytesWritten:exception:)])
			return false;

		newData = [_delegate stream: object
			       didWriteData: _data
			       bytesWritten: _writtenLength
				  exception: exception];

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		[oldData release];

		_writtenLength = 0;
		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (void)dealloc
{
	[_data release];
# ifdef OF_HAVE_BLOCKS
	[_block release];
# endif

	[super dealloc];
}
@end

@implementation OFRunLoopWriteStringQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;
	size_t cStringLength = [_string cStringLengthWithEncoding: _encoding];
	OFString *newString, *oldString;

	@try {
		const char *cString = [_string cStringWithEncoding: _encoding];

		length = [object writeBuffer: cString + _writtenLength
				      length: cStringLength - _writtenLength];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

	_writtenLength += length;

	if (_writtenLength != cStringLength && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL) {
		newString = _block(object, _string, _encoding, _writtenLength,
		    exception);

		if (newString == nil)
			return false;

		oldString = _string;
		_string = [newString copy];
		[oldString release];

		_writtenLength = 0;
		return true;
	} else {
# endif
		if (![_delegate respondsToSelector: @selector(stream:
		    didWriteString:encoding:bytesWritten:exception:)])
			return false;

		newString = [_delegate stream: object
			       didWriteString: _string
				     encoding: _encoding
				 bytesWritten: _writtenLength
				    exception: exception];

		if (newString == nil)
			return false;

		oldString = _string;
		_string = [newString copy];
		[oldString release];

		_writtenLength = 0;
		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (void)dealloc
{
	[_string release];
# ifdef OF_HAVE_BLOCKS
	[_block release];
# endif

	[super dealloc];
}
@end

# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
@implementation OFRunLoopConnectQueueItem
- (bool)handleObject: (id)object
{
	id exception = nil;
	int errNo;

	if ((errNo = [object of_socketError]) != 0)
		exception = [OFConnectionFailedException
		    exceptionWithHost: nil
				 port: 0
			       socket: object
				errNo: errNo];

	if ([_delegate respondsToSelector:
	    @selector(of_socketDidConnect:exception:)])
		[_delegate of_socketDidConnect: object
				     exception: exception];

	return false;
}
@end
# endif

@implementation OFRunLoopAcceptQueueItem
- (bool)handleObject: (id)object
{
	OFTCPSocket *acceptedSocket;
	id exception = nil;

	@try {
		acceptedSocket = [object accept];
	} @catch (id e) {
		acceptedSocket = nil;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		return _block(object, acceptedSocket, exception);
	else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(socket:didAcceptSocket:exception:)])
			return false;

		return [_delegate socket: object
			 didAcceptSocket: acceptedSocket
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopUDPReceiveQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	of_socket_address_t address;
	id exception = nil;

	@try {
		length = [object receiveIntoBuffer: _buffer
					    length: _length
					    sender: &address];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		return _block(object, _buffer, length, &address, exception);
	else {
# endif
		if (![_delegate respondsToSelector: @selector(
		    socket:didReceiveIntoBuffer:length:sender:exception:)])
			return false;

		return [_delegate socket: object
		    didReceiveIntoBuffer: _buffer
				  length: length
				  sender: &address
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopUDPSendQueueItem
- (bool)handleObject: (id)object
{
	id exception = nil;
	OFData *newData, *oldData;

	@try {
		[object sendBuffer: _data.items
			    length: _data.count * _data.itemSize
			  receiver: &_receiver];
	} @catch (id e) {
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL) {
		newData = _block(object, _data, &_receiver, exception);

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		[oldData release];

		return true;
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(socket:didSendData:receiver:exception:)])
			return false;

		newData = [_delegate socket: object
				didSendData: _data
				   receiver: &_receiver
				  exception: exception];

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		[oldData release];

		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (void)dealloc
{
	[_data release];
# ifdef OF_HAVE_BLOCKS
	[_block release];
# endif

	[super dealloc];
}
@end
#endif

@implementation OFRunLoop
@synthesize currentMode = _currentMode;

+ (OFRunLoop *)mainRunLoop
{
	return mainRunLoop;
}

+ (OFRunLoop *)currentRunLoop
{
#ifdef OF_HAVE_THREADS
	return [OFThread currentThread].runLoop;
#else
	return [self mainRunLoop];
#endif
}

+ (void)of_setMainRunLoop: (OFRunLoop *)runLoop
{
	mainRunLoop = [runLoop retain];
}

#ifdef OF_HAVE_SOCKETS
# define NEW_READ(type, object, mode)					\
	void *pool = objc_autoreleasePoolPush();			\
	OFRunLoop *runLoop = [self currentRunLoop];			\
	OFRunLoopState *state = [runLoop of_stateForMode: mode		\
						  create: true];	\
	OFList *queue = [state->_readQueues objectForKey: object];	\
	type *queueItem;						\
									\
	if (queue == nil) {						\
		queue = [OFList list];					\
		[state->_readQueues setObject: queue			\
				       forKey: object];			\
	}								\
									\
	if (queue.count == 0)						\
		[state->_kernelEventObserver				\
		    addObjectForReading: object];			\
									\
	queueItem = [[[type alloc] init] autorelease];
# define NEW_WRITE(type, object, mode)					\
	void *pool = objc_autoreleasePoolPush();			\
	OFRunLoop *runLoop = [self currentRunLoop];			\
	OFRunLoopState *state = [runLoop of_stateForMode: mode		\
						  create: true];	\
	OFList *queue = [state->_writeQueues objectForKey: object];	\
	type *queueItem;						\
									\
	if (queue == nil) {						\
		queue = [OFList list];					\
		[state->_writeQueues setObject: queue			\
					  forKey: object];		\
	}								\
									\
	if (queue.count == 0)						\
		[state->_kernelEventObserver				\
		    addObjectForWriting: object];			\
									\
	queueItem = [[[type alloc] init] autorelease];
#define QUEUE_ITEM							\
	[queue appendObject: queueItem];				\
									\
	objc_autoreleasePoolPop(pool);

+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
			  length: (size_t)length
			    mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			   block: (of_stream_async_read_block_t)block
# endif
			delegate: (id <OFStreamDelegate>)delegate
{
	NEW_READ(OFRunLoopReadQueueItem, stream, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif
	queueItem->_buffer = buffer;
	queueItem->_length = length;

	QUEUE_ITEM
}

+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
		     exactLength: (size_t)exactLength
			    mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			   block: (of_stream_async_read_block_t)block
# endif
			delegate: (id <OFStreamDelegate>)delegate
{
	NEW_READ(OFRunLoopExactReadQueueItem, stream, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif
	queueItem->_buffer = buffer;
	queueItem->_exactLength = exactLength;

	QUEUE_ITEM
}

+ (void)of_addAsyncReadLineForStream: (OFStream <OFReadyForReadingObserving> *)
					  stream
			    encoding: (of_string_encoding_t)encoding
				mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			       block: (of_stream_async_read_line_block_t)block
# endif
			    delegate: (id <OFStreamDelegate>)delegate
{
	NEW_READ(OFRunLoopReadLineQueueItem, stream, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif
	queueItem->_encoding = encoding;

	QUEUE_ITEM
}

+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			     data: (OFData *)data
			     mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			    block: (of_stream_async_write_data_block_t)block
# endif
			 delegate: (id <OFStreamDelegate>)delegate
{
	NEW_WRITE(OFRunLoopWriteDataQueueItem, stream, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif
	queueItem->_data = [data copy];

	QUEUE_ITEM
}

+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			   string: (OFString *)string
			 encoding: (of_string_encoding_t)encoding
			     mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			    block: (of_stream_async_write_string_block_t)block
# endif
			 delegate: (id <OFStreamDelegate>)delegate
{
	NEW_WRITE(OFRunLoopWriteStringQueueItem, stream, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif
	queueItem->_string = [string copy];
	queueItem->_encoding = encoding;

	QUEUE_ITEM
}

# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
+ (void)of_addAsyncConnectForTCPSocket: (OFTCPSocket *)stream
				  mode: (of_run_loop_mode_t)mode
			      delegate: (id <OFTCPSocketDelegate_Private>)
					    delegate
{
	NEW_WRITE(OFRunLoopConnectQueueItem, stream, mode)

	queueItem->_delegate = [delegate retain];

	QUEUE_ITEM
}
# endif

+ (void)of_addAsyncAcceptForTCPSocket: (OFTCPSocket *)stream
				 mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
				block: (of_tcp_socket_async_accept_block_t)block
# endif
			     delegate: (id <OFTCPSocketDelegate>)delegate
{
	NEW_READ(OFRunLoopAcceptQueueItem, stream, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif

	QUEUE_ITEM
}

+ (void)of_addAsyncReceiveForUDPSocket: (OFUDPSocket *)sock
				buffer: (void *)buffer
				length: (size_t)length
				  mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
				 block: (of_udp_socket_async_receive_block_t)
					    block
# endif
			      delegate: (id <OFUDPSocketDelegate>)delegate
{
	NEW_READ(OFRunLoopUDPReceiveQueueItem, sock, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif
	queueItem->_buffer = buffer;
	queueItem->_length = length;

	QUEUE_ITEM
}

+ (void)of_addAsyncSendForUDPSocket: (OFUDPSocket *)sock
			       data: (OFData *)data
			   receiver: (const of_socket_address_t *)receiver
			       mode: (of_run_loop_mode_t)mode
# ifdef OF_HAVE_BLOCKS
			      block: (of_udp_socket_async_send_data_block_t)
					 block
# endif
			   delegate: (id <OFUDPSocketDelegate>)delegate
{
	NEW_WRITE(OFRunLoopUDPSendQueueItem, sock, mode)

	queueItem->_delegate = [delegate retain];
# ifdef OF_HAVE_BLOCKS
	queueItem->_block = [block copy];
# endif
	queueItem->_data = [data copy];
	queueItem->_receiver = *receiver;

	QUEUE_ITEM
}
# undef NEW_READ
# undef NEW_WRITE
# undef QUEUE_ITEM

+ (void)of_cancelAsyncRequestsForObject: (id)object
				   mode: (of_run_loop_mode_t)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [self currentRunLoop];
	OFRunLoopState *state = [runLoop of_stateForMode: mode
						  create: false];
	OFList *queue;

	if (state == nil)
		return;

	if ((queue = [state->_writeQueues objectForKey: object]) != nil) {
		assert(queue.count > 0);

		/*
		 * Clear the queue now, in case this has been called from a
		 * handler, as otherwise, we'd do the cleanups below twice.
		 */
		[queue removeAllObjects];

		[state->_kernelEventObserver removeObjectForWriting: object];
		[state->_writeQueues removeObjectForKey: object];
	}

	if ((queue = [state->_readQueues objectForKey: object]) != nil) {
		assert(queue.count > 0);

		/*
		 * Clear the queue now, in case this has been called from a
		 * handler, as otherwise, we'd do the cleanups below twice.
		 */
		[queue removeAllObjects];

		[state->_kernelEventObserver removeObjectForReading: object];
		[state->_readQueues removeObjectForKey: object];
	}

	objc_autoreleasePoolPop(pool);
}
#endif

- (instancetype)init
{
	self = [super init];

	@try {
		OFRunLoopState *state;

		_states = [[OFMutableDictionary alloc] init];

		state = [[OFRunLoopState alloc] init];
		@try {
			[_states setObject: state
				    forKey: of_run_loop_mode_default];
		} @finally {
			[state release];
		}

#ifdef OF_HAVE_THREADS
		_statesMutex = [[OFMutex alloc] init];
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_states release];
#ifdef OF_HAVE_THREADS
	[_statesMutex release];
#endif

	[super dealloc];
}

- (OFRunLoopState *)of_stateForMode: (of_run_loop_mode_t)mode
			     create: (bool)create
{
	OFRunLoopState *state;

#ifdef OF_HAVE_THREADS
	[_statesMutex lock];
	@try {
#endif
		state = [_states objectForKey: mode];

		if (create && state == nil) {
			state = [[OFRunLoopState alloc] init];
			@try {
				[_states setObject: state
					    forKey: mode];
			} @finally {
				[state release];
			}
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		[_statesMutex unlock];
	}
#endif

	return state;
}

- (void)addTimer: (OFTimer *)timer
{
	[self addTimer: timer
	       forMode: of_run_loop_mode_default];
}

- (void)addTimer: (OFTimer *)timer
	 forMode: (of_run_loop_mode_t)mode
{
	OFRunLoopState *state = [self of_stateForMode: mode
					       create: true];

#ifdef OF_HAVE_THREADS
	[state->_timersQueueMutex lock];
	@try {
#endif
		[state->_timersQueue insertObject: timer];
#ifdef OF_HAVE_THREADS
	} @finally {
		[state->_timersQueueMutex unlock];
	}
#endif

	[timer of_setInRunLoop: self
			  mode: mode];

#if defined(OF_HAVE_SOCKETS)
	[state->_kernelEventObserver cancel];
#elif defined(OF_HAVE_THREADS)
	[state->_condition signal];
#endif
}

- (void)of_removeTimer: (OFTimer *)timer
	       forMode: (of_run_loop_mode_t)mode
{
	OFRunLoopState *state = [self of_stateForMode: mode
					       create: false];

	if (state == nil)
		return;

#ifdef OF_HAVE_THREADS
	[state->_timersQueueMutex lock];
	@try {
#endif
		of_list_object_t *iter;

		for (iter = state->_timersQueue.firstListObject; iter != NULL;
		    iter = iter->next) {
			if ([iter->object isEqual: timer]) {
				[state->_timersQueue removeListObject: iter];
				break;
			}
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		[state->_timersQueueMutex unlock];
	}
#endif
}

- (void)run
{
	[self runUntilDate: nil];
}

- (void)runUntilDate: (OFDate *)deadline
{
	_stop = false;

	while (!_stop &&
	    (deadline == nil || deadline.timeIntervalSinceNow >= 0))
		[self runMode: of_run_loop_mode_default
		   beforeDate: deadline];
}

- (void)runMode: (of_run_loop_mode_t)mode
     beforeDate: (OFDate *)deadline
{
	void *pool = objc_autoreleasePoolPush();
	of_run_loop_mode_t previousMode = _currentMode;
	OFRunLoopState *state = [self of_stateForMode: mode
					       create: false];

	if (state == nil)
		return;

	_currentMode = mode;
	@try {
		OFDate *nextTimer;

		for (;;) {
			OFTimer *timer;

#ifdef OF_HAVE_THREADS
			[state->_timersQueueMutex lock];
			@try {
#endif
				of_list_object_t *listObject =
				    state->_timersQueue.firstListObject;

				if (listObject != NULL && [listObject->object
				    fireDate].timeIntervalSinceNow <= 0) {
					timer = [[listObject->object
					    retain] autorelease];

					[state->_timersQueue
					    removeListObject: listObject];

					[timer of_setInRunLoop: nil
							  mode: nil];
				} else
					break;
#ifdef OF_HAVE_THREADS
			} @finally {
				[state->_timersQueueMutex unlock];
			}
#endif

			if (timer.valid) {
				[timer fire];
				return;
			}
		}

#ifdef OF_HAVE_THREADS
		[state->_timersQueueMutex lock];
		@try {
#endif
			nextTimer = [[state->_timersQueue
			    firstObject] fireDate];
#ifdef OF_HAVE_THREADS
		} @finally {
			[state->_timersQueueMutex unlock];
		}
#endif

		/* Watch for I/O events until the next timer is due */
		if (nextTimer != nil || deadline != nil) {
			of_time_interval_t timeout;

			if (nextTimer != nil && deadline == nil)
				timeout = nextTimer.timeIntervalSinceNow;
			else if (nextTimer == nil && deadline != nil)
				timeout = deadline.timeIntervalSinceNow;
			else
				timeout = [nextTimer earlierDate: deadline]
				    .timeIntervalSinceNow;

			if (timeout < 0)
				timeout = 0;

#if defined(OF_HAVE_SOCKETS)
			@try {
				[state->_kernelEventObserver
				    observeForTimeInterval: timeout];
			} @catch (OFObserveFailedException *e) {
				if (e.errNo != EINTR)
					@throw e;
			}
#elif defined(OF_HAVE_THREADS)
			[state->_condition lock];
			[state->_condition waitForTimeInterval: timeout];
			[state->_condition unlock];
#else
			[OFThread sleepForTimeInterval: timeout];
#endif
		} else {
			/*
			 * No more timers and no deadline: Just watch for I/O
			 * until we get an event. If a timer is added by
			 * another thread, it cancels the observe.
			 */
#if defined(OF_HAVE_SOCKETS)
			@try {
				[state->_kernelEventObserver observe];
			} @catch (OFObserveFailedException *e) {
				if (e.errNo != EINTR)
					@throw e;
			}
#elif defined(OF_HAVE_THREADS)
			[state->_condition lock];
			[state->_condition wait];
			[state->_condition unlock];
#else
			[OFThread sleepForTimeInterval: 86400];
#endif
		}

		objc_autoreleasePoolPop(pool);
	} @finally {
		_currentMode = previousMode;
	}
}

- (void)stop
{
	OFRunLoopState *state = [self of_stateForMode: of_run_loop_mode_default
					       create: false];

	_stop = true;

	if (state == nil)
		return;

#if defined(OF_HAVE_SOCKETS)
	[state->_kernelEventObserver cancel];
#elif defined(OF_HAVE_THREADS)
	[state->_condition signal];
#endif
}
@end
