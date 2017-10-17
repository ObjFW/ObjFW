/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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
#import "OFDictionary.h"
#ifdef OF_HAVE_SOCKETS
# import "OFKernelEventObserver.h"
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

static OFRunLoop *mainRunLoop = nil;

#ifdef OF_HAVE_SOCKETS
@interface OFRunLoop_QueueItem: OFObject
{
@public
	id _target;
	SEL _selector;
	id _context;
}

- (bool)handleObject: (id)object;
@end

@interface OFRunLoop_ReadQueueItem: OFRunLoop_QueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_read_block_t _block;
# endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoop_ExactReadQueueItem: OFRunLoop_QueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_read_block_t _block;
# endif
	void *_buffer;
	size_t _exactLength, _readLength;
}
@end

@interface OFRunLoop_ReadLineQueueItem: OFRunLoop_QueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_read_line_block_t _block;
# endif
	of_string_encoding_t _encoding;
}
@end

@interface OFRunLoop_WriteQueueItem: OFRunLoop_QueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_stream_async_write_block_t _block;
# endif
	const void *_buffer;
	size_t _length, _writtenLength;
}
@end

@interface OFRunLoop_AcceptQueueItem: OFRunLoop_QueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_tcp_socket_async_accept_block_t _block;
# endif
}
@end

@interface OFRunLoop_UDPReceiveQueueItem: OFRunLoop_QueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_udp_socket_async_receive_block_t _block;
# endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoop_UDPSendQueueItem: OFRunLoop_QueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	of_udp_socket_async_send_block_t _block;
# endif
	const void *_buffer;
	size_t _length;
	of_udp_socket_address_t _receiver;
}
@end

@implementation OFRunLoop_QueueItem
- (bool)handleObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)dealloc
{
	[_target release];
	[_context release];

	[super dealloc];
}
@end

@implementation OFRunLoop_ReadQueueItem
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
		bool (*func)(id, SEL, OFStream *, void *, size_t, id, id) =
		    (bool (*)(id, SEL, OFStream *, void *, size_t, id, id))
		    [_target methodForSelector: _selector];

		return func(_target, _selector, object, _buffer, length,
		    _context, exception);
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

@implementation OFRunLoop_ExactReadQueueItem
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
		bool (*func)(id, SEL, OFStream *, void *, size_t, id, id) =
		    (bool (*)(id, SEL, OFStream *, void *, size_t, id, id))
		    [_target methodForSelector: _selector];

		if (!func(_target, _selector, object, _buffer, _readLength,
		    _context, exception))
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

@implementation OFRunLoop_ReadLineQueueItem
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
		bool (*func)(id, SEL, OFStream *, OFString *, id, id) =
		    (bool (*)(id, SEL, OFStream *, OFString *, id, id))
		    [_target methodForSelector: _selector];

		return func(_target, _selector, object, line, _context,
		    exception);
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

@implementation OFRunLoop_WriteQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;

	@try {
		length = [object writeBuffer: (char *)_buffer + _writtenLength
				      length: _length - _writtenLength];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

	_writtenLength += length;

	if (_writtenLength != _length && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL) {
		_length = _block(object, &_buffer, _writtenLength, exception);

		if (_length == 0)
			return false;

		_writtenLength = 0;
		return true;
	} else {
# endif
		bool (*func)(id, SEL, OFStream *, const void *, size_t, id,
		    id) = (bool (*)(id, SEL, OFStream *, const void *, size_t,
		    id, id))[_target methodForSelector: _selector];

		_length = func(_target, _selector, object, &_buffer,
		    _writtenLength, _context, exception);

		if (_length == 0)
			return false;

		_writtenLength = 0;
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

@implementation OFRunLoop_AcceptQueueItem
- (bool)handleObject: (id)object
{
	OFTCPSocket *newSocket;
	id exception = nil;

	@try {
		newSocket = [object accept];
	} @catch (id e) {
		newSocket = nil;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		return _block(object, newSocket, exception);
	else {
# endif
		bool (*func)(id, SEL, OFTCPSocket *, OFTCPSocket *, id, id) =
		    (bool (*)(id, SEL, OFTCPSocket *, OFTCPSocket *, id, id))
		    [_target methodForSelector: _selector];

		return func(_target, _selector, object, newSocket, _context,
		    exception);
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

@implementation OFRunLoop_UDPReceiveQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	of_udp_socket_address_t address;
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
		return _block(object, _buffer, length, address, exception);
	else {
# endif
		bool (*func)(id, SEL, OFUDPSocket *, void *, size_t,
		    of_udp_socket_address_t, id, id) =
		    (bool (*)(id, SEL, OFUDPSocket *, void *, size_t,
		    of_udp_socket_address_t, id, id))
		    [_target methodForSelector: _selector];

		return func(_target, _selector, object, _buffer, length,
		    address, _context, exception);
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

@implementation OFRunLoop_UDPSendQueueItem
- (bool)handleObject: (id)object
{
	id exception = nil;

	@try {
		[object sendBuffer: _buffer
			    length: _length
			  receiver: &_receiver];
	} @catch (id e) {
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_block != NULL) {
		_length = _block(object, &_buffer,
		    (exception == nil ? _length : 0), &_receiver, exception);

		return (_length > 0);
	} else {
# endif
		size_t (*func)(id, SEL, OFUDPSocket *, const void *, size_t,
		    of_udp_socket_address_t *, id, id) =
		    (size_t (*)(id, SEL, OFUDPSocket *, const void *, size_t,
		    of_udp_socket_address_t *, id, id))
		    [_target methodForSelector: _selector];

		_length = func(_target, _selector, object, &_buffer,
		    (exception == nil ? _length : 0), &_receiver, _context,
		    exception);

		return (_length > 0);
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
#endif

@implementation OFRunLoop
+ (OFRunLoop *)mainRunLoop
{
	return mainRunLoop;
}

+ (OFRunLoop *)currentRunLoop
{
#ifdef OF_HAVE_THREADS
	return [[OFThread currentThread] runLoop];
#else
	return [self mainRunLoop];
#endif
}

+ (void)of_setMainRunLoop: (OFRunLoop *)runLoop
{
	mainRunLoop = [runLoop retain];
}

#ifdef OF_HAVE_SOCKETS
# define ADD_READ(type, object, code)					\
	void *pool = objc_autoreleasePoolPush();			\
	OFRunLoop *runLoop = [self currentRunLoop];			\
	OFList *queue = [runLoop->_readQueues objectForKey: object];	\
	type *queueItem;						\
									\
	if (queue == nil) {						\
		queue = [OFList list];					\
		[runLoop->_readQueues setObject: queue			\
					 forKey: object];		\
	}								\
									\
	if ([queue count] == 0)						\
		[runLoop->_kernelEventObserver				\
		    addObjectForReading: object];			\
									\
	queueItem = [[[type alloc] init] autorelease];			\
	code								\
	[queue appendObject: queueItem];				\
									\
	objc_autoreleasePoolPop(pool);
# define ADD_WRITE(type, object, code)					\
	void *pool = objc_autoreleasePoolPush();			\
	OFRunLoop *runLoop = [self currentRunLoop];			\
	OFList *queue = [runLoop->_writeQueues objectForKey: object];	\
	type *queueItem;						\
									\
	if (queue == nil) {						\
		queue = [OFList list];					\
		[runLoop->_writeQueues setObject: queue			\
					  forKey: object];		\
	}								\
									\
	if ([queue count] == 0)						\
		[runLoop->_kernelEventObserver				\
		    addObjectForWriting: object];			\
									\
	queueItem = [[[type alloc] init] autorelease];			\
	code								\
	[queue appendObject: queueItem];				\
									\
	objc_autoreleasePoolPop(pool);

+ (void)of_addAsyncReadForStream: (OFStream *)stream
			  buffer: (void *)buffer
			  length: (size_t)length
			  target: (id)target
			selector: (SEL)selector
			 context: (id)context
{
	ADD_READ(OFRunLoop_ReadQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_context = [context retain];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)of_addAsyncReadForStream: (OFStream *)stream
			  buffer: (void *)buffer
		     exactLength: (size_t)exactLength
			  target: (id)target
			selector: (SEL)selector
			 context: (id)context
{
	ADD_READ(OFRunLoop_ExactReadQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_context = [context retain];
		queueItem->_buffer = buffer;
		queueItem->_exactLength = exactLength;
	})
}

+ (void)of_addAsyncReadLineForStream: (OFStream *)stream
			    encoding: (of_string_encoding_t)encoding
			      target: (id)target
			    selector: (SEL)selector
			     context: (id)context
{
	ADD_READ(OFRunLoop_ReadLineQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_context = [context retain];
		queueItem->_encoding = encoding;
	})
}

+ (void)of_addAsyncWriteForStream: (OFStream *)stream
			   buffer: (const void *)buffer
			   length: (size_t)length
			   target: (id)target
			 selector: (SEL)selector
			  context: (id)context
{
	ADD_WRITE(OFRunLoop_WriteQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_context = [context retain];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)of_addAsyncAcceptForTCPSocket: (OFTCPSocket *)stream
			       target: (id)target
			     selector: (SEL)selector
			      context: (id)context
{
	ADD_READ(OFRunLoop_AcceptQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_context = [context retain];
	})
}

+ (void)of_addAsyncReceiveForUDPSocket: (OFUDPSocket *)socket
				buffer: (void *)buffer
				length: (size_t)length
				target: (id)target
			      selector: (SEL)selector
			       context: (id)context
{
	ADD_READ(OFRunLoop_UDPReceiveQueueItem, socket, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_context = [context retain];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)of_addAsyncSendForUDPSocket: (OFUDPSocket *)socket
			     buffer: (const void *)buffer
			     length: (size_t)length
			   receiver: (of_udp_socket_address_t)receiver
			     target: (id)target
			   selector: (SEL)selector
			    context: (id)context
{
	ADD_WRITE(OFRunLoop_UDPSendQueueItem, socket, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_context = [context retain];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
		queueItem->_receiver = receiver;
	})
}

# ifdef OF_HAVE_BLOCKS
+ (void)of_addAsyncReadForStream: (OFStream *)stream
			  buffer: (void *)buffer
			  length: (size_t)length
			   block: (of_stream_async_read_block_t)block
{
	ADD_READ(OFRunLoop_ReadQueueItem, stream, {
		queueItem->_block = [block copy];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)of_addAsyncReadForStream: (OFStream *)stream
			  buffer: (void *)buffer
		     exactLength: (size_t)exactLength
			   block: (of_stream_async_read_block_t)block
{
	ADD_READ(OFRunLoop_ExactReadQueueItem, stream, {
		queueItem->_block = [block copy];
		queueItem->_buffer = buffer;
		queueItem->_exactLength = exactLength;
	})
}

+ (void)of_addAsyncReadLineForStream: (OFStream *)stream
			    encoding: (of_string_encoding_t)encoding
			       block: (of_stream_async_read_line_block_t)block
{
	ADD_READ(OFRunLoop_ReadLineQueueItem, stream, {
		queueItem->_block = [block copy];
		queueItem->_encoding = encoding;
	})
}

+ (void)of_addAsyncWriteForStream: (OFStream *)stream
			   buffer: (const void *)buffer
			   length: (size_t)length
			    block: (of_stream_async_write_block_t)block
{
	ADD_WRITE(OFRunLoop_WriteQueueItem, stream, {
		queueItem->_block = [block copy];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)of_addAsyncAcceptForTCPSocket: (OFTCPSocket *)stream
				block: (of_tcp_socket_async_accept_block_t)block
{
	ADD_READ(OFRunLoop_AcceptQueueItem, stream, {
		queueItem->_block = [block copy];
	})
}

+ (void)of_addAsyncReceiveForUDPSocket: (OFUDPSocket *)socket
				buffer: (void *)buffer
				length: (size_t)length
				 block: (of_udp_socket_async_receive_block_t)
					    block
{
	ADD_READ(OFRunLoop_UDPReceiveQueueItem, socket, {
		queueItem->_block = [block copy];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)of_addAsyncSendForUDPSocket: (OFUDPSocket *)socket
			     buffer: (const void *)buffer
			     length: (size_t)length
			   receiver: (of_udp_socket_address_t)receiver
			      block: (of_udp_socket_async_send_block_t)block
{
	ADD_WRITE(OFRunLoop_UDPSendQueueItem, socket, {
		queueItem->_block = [block copy];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
		queueItem->_receiver = receiver;
	})
}
# endif
# undef ADD_READ
# undef ADD_WRITE

+ (void)of_cancelAsyncRequestsForObject: (id)object
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [self currentRunLoop];
	OFList *queue;

	if ((queue = [runLoop->_writeQueues objectForKey: object]) != nil) {
		assert([queue count] > 0);

		/*
		 * Clear the queue now, in case this has been called from a
		 * handler, as otherwise, we'd do the cleanups below twice.
		 */
		[queue removeAllObjects];

		[runLoop->_kernelEventObserver removeObjectForWriting: object];
		[runLoop->_writeQueues removeObjectForKey: object];
	}

	if ((queue = [runLoop->_readQueues objectForKey: object]) != nil) {
		assert([queue count] > 0);

		/*
		 * Clear the queue now, in case this has been called from a
		 * handler, as otherwise, we'd do the cleanups below twice.
		 */
		[queue removeAllObjects];

		[runLoop->_kernelEventObserver removeObjectForReading: object];
		[runLoop->_readQueues removeObjectForKey: object];
	}

	objc_autoreleasePoolPop(pool);
}
#endif

- (instancetype)init
{
	self = [super init];

	@try {
		_timersQueue = [[OFSortedList alloc] init];
#ifdef OF_HAVE_THREADS
		_timersQueueLock = [[OFMutex alloc] init];
#endif

#if defined(OF_HAVE_SOCKETS)
		_kernelEventObserver = [[OFKernelEventObserver alloc] init];
		[_kernelEventObserver setDelegate: self];

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
#ifdef OF_HAVE_THREADS
	[_timersQueueLock release];
#endif
#if defined(OF_HAVE_SOCKETS)
	[_kernelEventObserver release];
	[_readQueues release];
	[_writeQueues release];
#elif defined(OF_HAVE_THREADS)
	[_condition release];
#endif

	[super dealloc];
}

- (void)addTimer: (OFTimer *)timer
{
#ifdef OF_HAVE_THREADS
	[_timersQueueLock lock];
	@try {
#endif
		[_timersQueue insertObject: timer];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_timersQueueLock unlock];
	}
#endif

	[timer of_setInRunLoop: self];

#if defined(OF_HAVE_SOCKETS)
	[_kernelEventObserver cancel];
#elif defined(OF_HAVE_THREADS)
	[_condition signal];
#endif
}

- (void)of_removeTimer: (OFTimer *)timer
{
#ifdef OF_HAVE_THREADS
	[_timersQueueLock lock];
	@try {
#endif
		of_list_object_t *iter;

		for (iter = [_timersQueue firstListObject]; iter != NULL;
		    iter = iter->next) {
			if ([iter->object isEqual: timer]) {
				[_timersQueue removeListObject: iter];
				break;
			}
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		[_timersQueueLock unlock];
	}
#endif
}

#ifdef OF_HAVE_SOCKETS
- (void)objectIsReadyForReading: (id)object
{
	/*
	 * Retain the queue so that it doesn't disappear from us because the
	 * handler called -[cancelAsyncRequests].
	 */
	OFList OF_GENERIC(OF_KINDOF(OFRunLoop_ReadQueueItem *)) *queue =
	    [[_readQueues objectForKey: object] retain];

	assert(queue != nil);

	@try {
		if (![[queue firstObject] handleObject: object]) {
			of_list_object_t *listObject = [queue firstListObject];

			/*
			 * The handler might have called -[cancelAsyncRequests]
			 * so that our queue is now empty, in which case we
			 * should do nothing.
			 */
			if (listObject != NULL) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
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
	OFList OF_GENERIC(OF_KINDOF(OFRunLoop_WriteQueueItem *)) *queue =
	    [[_writeQueues objectForKey: object] retain];

	assert(queue != nil);

	@try {
		if (![[queue firstObject] handleObject: object]) {
			of_list_object_t *listObject = [queue firstListObject];

			/*
			 * The handler might have called -[cancelAsyncRequests]
			 * so that our queue is now empty, in which case we
			 * should do nothing.
			 */
			if (listObject != NULL) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
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

- (void)run
{
	[self runUntilDate: nil];
}

- (void)runUntilDate: (OFDate *)deadline
{
	_stop = false;

	for (;;) {
		void *pool = objc_autoreleasePoolPush();
		OFDate *now = [OFDate date];
		OFDate *nextTimer;

		for (;;) {
			OFTimer *timer;

#ifdef OF_HAVE_THREADS
			[_timersQueueLock lock];
			@try {
#endif
				of_list_object_t *listObject =
				    [_timersQueue firstListObject];

				if (listObject != NULL && [[listObject->object
				    fireDate] compare: now] !=
				    OF_ORDERED_DESCENDING) {
					timer = [[listObject->object
					    retain] autorelease];

					[_timersQueue removeListObject:
					    listObject];

					[timer of_setInRunLoop: nil];
				} else
					break;
#ifdef OF_HAVE_THREADS
			} @finally {
				[_timersQueueLock unlock];
			}
#endif

			if ([timer isValid])
				[timer fire];
		}

#ifdef OF_HAVE_THREADS
		[_timersQueueLock lock];
		@try {
#endif
			nextTimer = [[_timersQueue firstObject] fireDate];
#ifdef OF_HAVE_THREADS
		} @finally {
			[_timersQueueLock unlock];
		}
#endif

		/* Watch for I/O events until the next timer is due */
		if (nextTimer != nil || deadline != nil) {
			of_time_interval_t timeout;

			if (nextTimer != nil && deadline == nil)
				timeout = [nextTimer timeIntervalSinceNow];
			else if (nextTimer == nil && deadline != nil)
				timeout = [deadline timeIntervalSinceNow];
			else
				timeout = [[nextTimer earlierDate: deadline]
				    timeIntervalSinceNow];

			if (timeout < 0)
				timeout = 0;

#if defined(OF_HAVE_SOCKETS)
			@try {
				[_kernelEventObserver
				    observeForTimeInterval: timeout];
			} @catch (OFObserveFailedException *e) {
				if ([e errNo] != EINTR)
					@throw e;
			}
#elif defined(OF_HAVE_THREADS)
			[_condition lock];
			[_condition waitForTimeInterval: timeout];
			[_condition unlock];
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
				[_kernelEventObserver observe];
			} @catch (OFObserveFailedException *e) {
				if ([e errNo] != EINTR)
					@throw e;
			}
#elif defined(OF_HAVE_THREADS)
			[_condition lock];
			[_condition wait];
			[_condition unlock];
#else
			[OFThread sleepForTimeInterval: 86400];
#endif
		}

		if (_stop || (deadline != nil &&
		    [deadline compare: now] != OF_ORDERED_DESCENDING)) {
			objc_autoreleasePoolPop(pool);
			break;
		}

		objc_autoreleasePoolPop(pool);
	}
}

- (void)stop
{
	_stop = true;
#if defined(OF_HAVE_SOCKETS)
	[_kernelEventObserver cancel];
#elif defined(OF_HAVE_THREADS)
	[_condition signal];
#endif
}
@end
