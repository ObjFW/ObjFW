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

#include "config.h"

#define OF_RUNLOOP_M

#import "OFRunLoop.h"
#import "OFDictionary.h"
#import "OFThread.h"
#import "OFSortedList.h"
#import "OFTimer.h"
#import "OFDate.h"

#import "autorelease.h"
#import "macros.h"

static OFRunLoop *mainRunLoop = nil;

#ifdef OF_HAVE_BLOCKS
@interface OFRunLoop_ReadQueueItem: OFObject
{
	void *buffer;
	size_t length;
	of_stream_async_read_block_t block;
}

@property void *buffer;
@property size_t length;
@property (copy) of_stream_async_read_block_t block;
@end

@interface OFRunLoop_ReadLineQueueItem: OFObject
{
	of_stream_async_read_line_block_t block;
	of_string_encoding_t encoding;
}

@property (copy) of_stream_async_read_line_block_t block;
@property of_string_encoding_t encoding;
@end

@interface OFRunLoop_AcceptQueueItem: OFObject
{
	of_tcpsocket_async_accept_block_t block;
}

@property (copy) of_tcpsocket_async_accept_block_t block;
@end

@implementation OFRunLoop_ReadQueueItem
@synthesize buffer, length, block;

- (void)dealloc
{
	[block release];

	[super dealloc];
}
@end

@implementation OFRunLoop_ReadLineQueueItem
@synthesize block, encoding;

- (void)dealloc
{
	[block release];

	[super dealloc];
}
@end

@implementation OFRunLoop_AcceptQueueItem
@synthesize block;

- (void)dealloc
{
	[block release];

	[super dealloc];
}
@end
#endif

@implementation OFRunLoop
+ (OFRunLoop*)mainRunLoop
{
	return [[mainRunLoop retain] autorelease];
}

+ (OFRunLoop*)currentRunLoop
{
	OFThread *currentThread = [OFThread currentThread];
	OFRunLoop *runLoop = [currentThread runLoop];

	if (runLoop != nil)
		return runLoop;

	runLoop = [[[OFRunLoop alloc] init] autorelease];
	[currentThread OF_setRunLoop: runLoop];

	return runLoop;
}

+ (void)OF_setMainRunLoop
{
	void *pool = objc_autoreleasePoolPush();
	mainRunLoop = [[[OFThread currentThread] runLoop] retain];
	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
+ (void)OF_addAsyncReadForStream: (OFStream*)stream
			buffer: (void*)buffer
			length: (size_t)length
			 block: (of_stream_async_read_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [self currentRunLoop];
	OFList *queue = [runLoop->readQueues objectForKey: stream];
	OFRunLoop_ReadQueueItem *queueItem;

	if (queue == nil) {
		queue = [OFList list];
		[runLoop->readQueues setObject: queue
					forKey: stream];
	}

	if ([queue count] == 0)
		[runLoop->streamObserver addStreamForReading: stream];

	queueItem = [[[OFRunLoop_ReadQueueItem alloc] init] autorelease];
	[queueItem setBuffer: buffer];
	[queueItem setLength: length];
	[queueItem setBlock: block];
	[queue appendObject: queueItem];

	objc_autoreleasePoolPop(pool);
}

+ (void)OF_addAsyncReadLineForStream: (OFStream*)stream
			    encoding: (of_string_encoding_t)encoding
			       block: (of_stream_async_read_line_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [self currentRunLoop];
	OFList *queue = [runLoop->readQueues objectForKey: stream];
	OFRunLoop_ReadLineQueueItem *queueItem;

	if (queue == nil) {
		queue = [OFList list];
		[runLoop->readQueues setObject: queue
					forKey: stream];
	}

	if ([queue count] == 0)
		[runLoop->streamObserver addStreamForReading: stream];

	queueItem = [[[OFRunLoop_ReadLineQueueItem alloc] init] autorelease];
	[queueItem setBlock: block];
	[queueItem setEncoding: encoding];
	[queue appendObject: queueItem];

	objc_autoreleasePoolPop(pool);
}

+ (void)OF_addAsyncAcceptForTCPSocket: (OFTCPSocket*)socket
				block: (of_tcpsocket_async_accept_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [self currentRunLoop];
	OFList *queue = [runLoop->readQueues objectForKey: socket];
	OFRunLoop_AcceptQueueItem *queueItem;

	if (queue == nil) {
		queue = [OFList list];
		[runLoop->readQueues setObject: queue
					forKey: socket];
	}

	if ([queue count] == 0)
		[runLoop->streamObserver addStreamForReading: socket];

	queueItem = [[[OFRunLoop_AcceptQueueItem alloc] init] autorelease];
	[queueItem setBlock: block];
	[queue appendObject: queueItem];

	objc_autoreleasePoolPop(pool);
}
#endif

- init
{
	self = [super init];

	@try {
		timersQueue = [[OFSortedList alloc] init];

		streamObserver = [[OFStreamObserver alloc] init];
		[streamObserver setDelegate: self];

		readQueues = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[timersQueue release];
	[streamObserver release];
	[readQueues release];

	[super dealloc];
}

- (void)addTimer: (OFTimer*)timer
{
	@synchronized (timersQueue) {
		[timersQueue addObject: timer];
	}
	[streamObserver cancel];
}

#ifdef OF_HAVE_BLOCKS
- (void)streamIsReadyForReading: (OFStream*)stream
{
	OFList *queue = [readQueues objectForKey: stream];
	of_list_object_t *listObject;

	OF_ENSURE(queue != nil);

	listObject = [queue firstListObject];

	if ([listObject->object isKindOfClass:
	    [OFRunLoop_ReadQueueItem class]]) {
		OFRunLoop_ReadQueueItem *queueItem = listObject->object;
		void *buffer = [queueItem buffer];
		size_t length = [stream readIntoBuffer: buffer
						length: [queueItem length]];

		if (![queueItem block](stream, buffer, length)) {
			[queue removeListObject: listObject];

			if ([queue count] == 0) {
				[streamObserver removeStreamForReading: stream];
				[readQueues removeObjectForKey: stream];
			}
		}
	} else if ([listObject->object isKindOfClass:
	    [OFRunLoop_ReadLineQueueItem class]]) {
		OFRunLoop_ReadLineQueueItem *queueItem = listObject->object;
		OFString *line;

		line = [stream tryReadLineWithEncoding: [queueItem encoding]];

		if (line != nil || [stream isAtEndOfStream]) {
			if (![queueItem block](stream, line)) {
				[queue removeListObject: listObject];

				if ([queue count] == 0) {
					[streamObserver
					    removeStreamForReading: stream];
					[readQueues removeObjectForKey: stream];
				}
			}
		}
	} else if ([listObject->object isKindOfClass:
	    [OFRunLoop_AcceptQueueItem class]]) {
		OFRunLoop_AcceptQueueItem *queueItem = listObject->object;
		OFTCPSocket *newSocket = [(OFTCPSocket*)stream accept];

		if (![queueItem block]((OFTCPSocket*)stream, newSocket)) {
			[queue removeListObject: listObject];

			if ([queue count] == 0) {
				[streamObserver removeStreamForReading: stream];
				[readQueues removeObjectForKey: stream];
			}
		}
	} else
		OF_ENSURE(0);
}
#endif

- (void)run
{
	for (;;) {
		void *pool = objc_autoreleasePoolPush();
		OFDate *now = [OFDate date];
		OFTimer *timer;
		OFDate *nextTimer;

		@synchronized (timersQueue) {
			of_list_object_t *listObject =
			    [timersQueue firstListObject];

			if (listObject != NULL &&
			    [[listObject->object fireDate] compare: now] !=
			    OF_ORDERED_DESCENDING) {
				timer =
				    [[listObject->object retain] autorelease];

				[timersQueue removeListObject: listObject];
			} else
				timer = nil;
		}

		[timer fire];

		@synchronized (timersQueue) {
			nextTimer = [[timersQueue firstObject] fireDate];
		}

		/* Watch for stream events until the next timer is due */
		if (nextTimer != nil) {
			double timeout = [nextTimer timeIntervalSinceNow];

			if (timeout > 0)
				[streamObserver observeWithTimeout: timeout];
		} else {
			/*
			 * No more timers: Just watch for streams until we get
			 * an event. If a timer is added by another thread, it
			 * cancels the observe.
			 */
			[streamObserver observe];
		}

		objc_autoreleasePoolPop(pool);
	}
}
@end
