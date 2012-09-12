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

#import "OFRunLoop.h"
#import "OFThread.h"
#import "OFSortedList.h"
#import "OFTimer.h"
#import "OFDate.h"
#import "OFStreamObserver.h"

static OFTLSKey *currentRunLoopKey;
static OFRunLoop *mainRunLoop;

@implementation OFRunLoop
+ (void)initialize
{
	if (self == [OFRunLoop class])
		currentRunLoopKey = [[OFTLSKey alloc] init];
}

+ (OFRunLoop*)mainRunLoop
{
	return [[mainRunLoop retain] autorelease];
}

+ (OFRunLoop*)currentRunLoop
{
	return [[[OFThread objectForTLSKey: currentRunLoopKey]
	    retain] autorelease];
}

+ (void)_setMainRunLoop: (OFRunLoop*)mainRunLoop_
{
	mainRunLoop = [mainRunLoop_ retain];
}

- init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		timersQueue = [[[OFThread currentThread] _timersQueue] retain];
		streamObserver = [[OFStreamObserver alloc] init];

		[OFThread setObject: self
			  forTLSKey: currentRunLoopKey];

		objc_autoreleasePoolPop(pool);
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

	[super dealloc];
}

- (void)addTimer: (OFTimer*)timer
{
	@synchronized (timersQueue) {
		[timersQueue addObject: timer];
	}
	[streamObserver cancel];
}

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
