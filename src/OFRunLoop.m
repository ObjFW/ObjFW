/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

static OFRunLoop *mainRunLoop = nil;

#ifdef OF_HAVE_SOCKETS
@interface OFRunLoop_QueueItem: OFObject
{
@public
	id _target;
	SEL _selector;
}
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

@implementation OFRunLoop_QueueItem
- (void)dealloc
{
	[_target release];

	[super dealloc];
}
@end

@implementation OFRunLoop_ReadQueueItem
# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoop_ExactReadQueueItem
# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoop_ReadLineQueueItem
# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoop_AcceptQueueItem
# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	[_block release];

	[super dealloc];
}
# endif
@end

@implementation OFRunLoop_UDPReceiveQueueItem
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
+ (OFRunLoop*)mainRunLoop
{
	return [[mainRunLoop retain] autorelease];
}

+ (OFRunLoop*)currentRunLoop
{
#ifdef OF_HAVE_THREADS
	return [[OFThread currentThread] runLoop];
#else
	return [self mainRunLoop];
#endif
}

+ (void)OF_setMainRunLoop: (OFRunLoop*)runLoop
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

+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
			  length: (size_t)length
			  target: (id)target
			selector: (SEL)selector
{
	ADD_READ(OFRunLoop_ReadQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
		     exactLength: (size_t)exactLength
			  target: (id)target
			selector: (SEL)selector
{
	ADD_READ(OFRunLoop_ExactReadQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_buffer = buffer;
		queueItem->_exactLength = exactLength;
	})
}

+ (void)OF_addAsyncReadLineForStream: (OFStream*)stream
			    encoding: (of_string_encoding_t)encoding
			      target: (id)target
			    selector: (SEL)selector
{
	ADD_READ(OFRunLoop_ReadLineQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
		queueItem->_encoding = encoding;
	})
}

+ (void)OF_addAsyncAcceptForTCPSocket: (OFTCPSocket*)stream
			       target: (id)target
			     selector: (SEL)selector
{
	ADD_READ(OFRunLoop_AcceptQueueItem, stream, {
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
	})
}

+ (void)OF_addAsyncReceiveForUDPSocket: (OFUDPSocket*)socket
				buffer: (void*)buffer
				length: (size_t)length
				target: (id)target
			      selector: (SEL)selector
{
	ADD_READ(OFRunLoop_UDPReceiveQueueItem, socket, {
		queueItem->_buffer = buffer;
		queueItem->_length = length;
		queueItem->_target = [target retain];
		queueItem->_selector = selector;
	})
}

# ifdef OF_HAVE_BLOCKS
+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
			  length: (size_t)length
			   block: (of_stream_async_read_block_t)block
{
	ADD_READ(OFRunLoop_ReadQueueItem, stream, {
		queueItem->_block = [block copy];
		queueItem->_buffer = buffer;
		queueItem->_length = length;
	})
}

+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			  buffer: (void*)buffer
		     exactLength: (size_t)exactLength
			   block: (of_stream_async_read_block_t)block
{
	ADD_READ(OFRunLoop_ExactReadQueueItem, stream, {
		queueItem->_block = [block copy];
		queueItem->_buffer = buffer;
		queueItem->_exactLength = exactLength;
	})
}

+ (void)OF_addAsyncReadLineForStream: (OFStream*)stream
			    encoding: (of_string_encoding_t)encoding
			       block: (of_stream_async_read_line_block_t)block
{
	ADD_READ(OFRunLoop_ReadLineQueueItem, stream, {
		queueItem->_block = [block copy];
		queueItem->_encoding = encoding;
	})
}

+ (void)OF_addAsyncAcceptForTCPSocket: (OFTCPSocket*)stream
				block: (of_tcp_socket_async_accept_block_t)block
{
	ADD_READ(OFRunLoop_AcceptQueueItem, stream, {
		queueItem->_block = [block copy];
	})
}

+ (void)OF_addAsyncReceiveForUDPSocket: (OFUDPSocket*)socket
				buffer: (void*)buffer
				length: (size_t)length
				 block: (of_udp_socket_async_receive_block_t)
					    block
{
	ADD_READ(OFRunLoop_UDPReceiveQueueItem, socket, {
		queueItem->_buffer = buffer;
		queueItem->_length = length;
		queueItem->_block = [block copy];
	})
}
# endif
# undef ADD_READ

+ (void)OF_cancelAsyncRequestsForObject: (id)object
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [self currentRunLoop];
	OFList *queue;

	if ((queue = [runLoop->_readQueues objectForKey: object]) != nil) {
		assert([queue count] > 0);

		[runLoop->_kernelEventObserver removeObjectForReading: object];
		[runLoop->_readQueues removeObjectForKey: object];
	}

	objc_autoreleasePoolPop(pool);
}
#endif

- init
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
#elif defined(OF_HAVE_THREADS)
	[_condition release];
#endif

	[super dealloc];
}

- (void)addTimer: (OFTimer*)timer
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

	[timer OF_setInRunLoop: self];

#if defined(OF_HAVE_SOCKETS)
	[_kernelEventObserver cancel];
#elif defined(OF_HAVE_THREADS)
	[_condition signal];
#endif
}

- (void)OF_removeTimer: (OFTimer*)timer
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
	OFList *queue = [_readQueues objectForKey: object];
	of_list_object_t *listObject;

	assert(queue != nil);

	listObject = [queue firstListObject];

	if ([listObject->object isKindOfClass:
	    [OFRunLoop_ReadQueueItem class]]) {
		OFRunLoop_ReadQueueItem *queueItem = listObject->object;
		size_t length;
		OFException *exception = nil;

		@try {
			length = [object readIntoBuffer: queueItem->_buffer
						 length: queueItem->_length];
		} @catch (OFException *e) {
			length = 0;
			exception = e;
		}

# ifdef OF_HAVE_BLOCKS
		if (queueItem->_block != NULL) {
			if (!queueItem->_block(object, queueItem->_buffer,
			    length, exception)) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
		} else {
# endif
			bool (*func)(id, SEL, OFStream*, void*, size_t,
			    OFException*) = (bool(*)(id, SEL, OFStream*, void*,
			    size_t, OFException*))
			    [queueItem->_target methodForSelector:
			    queueItem->_selector];

			if (!func(queueItem->_target, queueItem->_selector,
			    object, queueItem->_buffer, length, exception)) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
# ifdef OF_HAVE_BLOCKS
		}
# endif
	} else if ([listObject->object isKindOfClass:
	    [OFRunLoop_ExactReadQueueItem class]]) {
		OFRunLoop_ExactReadQueueItem *queueItem = listObject->object;
		size_t length;
		OFException *exception = nil;

		@try {
			length = [object
			    readIntoBuffer: (char*)queueItem->_buffer +
					    queueItem->_readLength
				    length: queueItem->_exactLength -
					    queueItem->_readLength];
		} @catch (OFException *e) {
			length = 0;
			exception = e;
		}

		queueItem->_readLength += length;
		if (queueItem->_readLength == queueItem->_exactLength ||
		    [object isAtEndOfStream] || exception != nil) {
# ifdef OF_HAVE_BLOCKS
			if (queueItem->_block != NULL) {
				if (queueItem->_block(object,
				    queueItem->_buffer, queueItem->_readLength,
				    exception))
					queueItem->_readLength = 0;
				else {
					[queue removeListObject: listObject];

					if ([queue count] == 0) {
						[_kernelEventObserver
						    removeObjectForReading:
						    object];
						[_readQueues
						    removeObjectForKey: object];
					}
				}
			} else {
# endif
				bool (*func)(id, SEL, OFStream*, void*,
				    size_t, OFException*) = (bool(*)(id, SEL,
				    OFStream*, void*, size_t, OFException*))
				    [queueItem->_target
				    methodForSelector: queueItem->_selector];

				if (func(queueItem->_target,
				    queueItem->_selector, object,
				    queueItem->_buffer, queueItem->_readLength,
				    exception))
					queueItem->_readLength = 0;
				else {
					[queue removeListObject: listObject];

					if ([queue count] == 0) {
						[_kernelEventObserver
						    removeObjectForReading:
						    object];
						[_readQueues
						    removeObjectForKey: object];
					}
				}
# ifdef OF_HAVE_BLOCKS
			}
# endif
		}
	} else if ([listObject->object isKindOfClass:
	    [OFRunLoop_ReadLineQueueItem class]]) {
		OFRunLoop_ReadLineQueueItem *queueItem = listObject->object;
		OFString *line;
		OFException *exception = nil;

		@try {
			line = [object
			    tryReadLineWithEncoding: queueItem->_encoding];
		} @catch (OFException *e) {
			line = nil;
			exception = e;
		}

		if (line != nil || [object isAtEndOfStream] ||
		    exception != nil) {
# ifdef OF_HAVE_BLOCKS
			if (queueItem->_block != NULL) {
				if (!queueItem->_block(object, line,
				    exception)) {
					[queue removeListObject: listObject];

					if ([queue count] == 0) {
						[_kernelEventObserver
						    removeObjectForReading:
						    object];
						[_readQueues
						    removeObjectForKey: object];
					}
				}
			} else {
# endif
				bool (*func)(id, SEL, OFStream*, OFString*,
				    OFException*) = (bool(*)(id, SEL, OFStream*,
				    OFString*, OFException*))
				    [queueItem->_target methodForSelector:
				    queueItem->_selector];

				if (!func(queueItem->_target,
				    queueItem->_selector, object, line,
				    exception)) {
					[queue removeListObject: listObject];

					if ([queue count] == 0) {
						[_kernelEventObserver
						    removeObjectForReading:
						    object];
						[_readQueues
						    removeObjectForKey: object];
					}
				}
# ifdef OF_HAVE_BLOCKS
			}
# endif
		}
	} else if ([listObject->object isKindOfClass:
	    [OFRunLoop_AcceptQueueItem class]]) {
		OFRunLoop_AcceptQueueItem *queueItem = listObject->object;
		OFTCPSocket *newSocket;
		OFException *exception = nil;

		@try {
			newSocket = [object accept];
		} @catch (OFException *e) {
			newSocket = nil;
			exception = e;
		}

# ifdef OF_HAVE_BLOCKS
		if (queueItem->_block != NULL) {
			if (!queueItem->_block(object, newSocket, exception)) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
		} else {
# endif
			bool (*func)(id, SEL, OFTCPSocket*, OFTCPSocket*,
			    OFException*) =
			    (bool(*)(id, SEL, OFTCPSocket*, OFTCPSocket*,
			    OFException*))
			    [queueItem->_target methodForSelector:
			    queueItem->_selector];

			if (!func(queueItem->_target, queueItem->_selector,
			    object, newSocket, exception)) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
# ifdef OF_HAVE_BLOCKS
		}
# endif
	} else if ([listObject->object isKindOfClass:
	    [OFRunLoop_UDPReceiveQueueItem class]]) {
		OFRunLoop_UDPReceiveQueueItem *queueItem = listObject->object;
		size_t length;
		of_udp_socket_address_t address;
		OFException *exception = nil;

		@try {
			length = [object receiveIntoBuffer: queueItem->_buffer
						    length: queueItem->_length
						    sender: &address];
		} @catch (OFException *e) {
			length = 0;
			exception = e;
		}

# ifdef OF_HAVE_BLOCKS
		if (queueItem->_block != NULL) {
			if (!queueItem->_block(object, queueItem->_buffer,
			    length, address, exception)) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
		} else {
# endif
			bool (*func)(id, SEL, OFUDPSocket*, void*, size_t,
			    of_udp_socket_address_t address, OFException*) =
			    (bool(*)(id, SEL, OFUDPSocket*, void*, size_t,
			    of_udp_socket_address_t, OFException*))
			    [queueItem->_target methodForSelector:
			    queueItem->_selector];

			if (!func(queueItem->_target, queueItem->_selector,
			    object, queueItem->_buffer, length, address,
			    exception)) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
# ifdef OF_HAVE_BLOCKS
		}
# endif
	} else
		assert(0);
}
#endif

- (void)run
{
	_running = true;

	for (;;) {
		void *pool;
		OFDate *now;
		OFTimer *timer;
		OFDate *nextTimer;

		if (!_running)
			break;

		pool = objc_autoreleasePoolPush();
		now = [OFDate date];

#ifdef OF_HAVE_THREADS
		[_timersQueueLock lock];
		@try {
#endif
			of_list_object_t *listObject =
			    [_timersQueue firstListObject];

			if (listObject != NULL &&
			    [[listObject->object fireDate] compare: now] !=
			    OF_ORDERED_DESCENDING) {
				timer =
				    [[listObject->object retain] autorelease];

				[_timersQueue removeListObject: listObject];

				[timer OF_setInRunLoop: nil];
			} else
				timer = nil;
#ifdef OF_HAVE_THREADS
		} @finally {
			[_timersQueueLock unlock];
		}
#endif

		if ([timer isValid])
			[timer fire];

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
		if (nextTimer != nil) {
			of_time_interval_t timeout =
			    [nextTimer timeIntervalSinceNow];

			if (timeout > 0) {
#if defined(OF_HAVE_SOCKETS)
				[_kernelEventObserver
				    observeForTimeInterval: timeout];
#elif defined(OF_HAVE_THREADS)
				[_condition lock];
				[_condition waitForTimeInterval: timeout];
				[_condition unlock];
#else
				[OFThread sleepForTimeInterval: timeout];
#endif
			}
		} else {
			/*
			 * No more timers: Just watch for I/O until we get
			 * an event. If a timer is added by another thread, it
			 * cancels the observe.
			 */
#if defined(OF_HAVE_SOCKETS)
			[_kernelEventObserver observe];
#elif defined(OF_HAVE_THREADS)
			[_condition lock];
			[_condition wait];
			[_condition unlock];
#else
			[OFThread sleepForTimeInterval: 86400];
#endif
		}

		objc_autoreleasePoolPop(pool);
	}
}

- (void)stop
{
	_running = false;
#if defined(OF_HAVE_SOCKETS)
	[_kernelEventObserver cancel];
#elif defined(OF_HAVE_THREADS)
	[_condition signal];
#endif
}
@end
