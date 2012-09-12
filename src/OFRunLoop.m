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

	[super dealloc];
}

- (void)addTimer: (OFTimer*)timer
{
	@synchronized (timersQueue) {
		[timersQueue addObject: timer];
	}
}

- (void)run
{
	for (;;) {
		void *pool = objc_autoreleasePoolPush();
		OFDate *now = [OFDate date];

		@synchronized (timersQueue) {
			of_list_object_t *iter;

			while ((iter = [timersQueue firstListObject]) != NULL) {
				void *pool2 = objc_autoreleasePoolPush();
				OFTimer *timer;

				/*
				 * If a timer is in the future, we can
				 * stop now as it is sorted.
				 */
				if ([[iter->object fireDate] compare: now] ==
				    OF_ORDERED_DESCENDING)
					break;

				timer = [[iter->object retain] autorelease];
				[timersQueue removeListObject: iter];

				[timer fire];

				objc_autoreleasePoolPop(pool2);
			}

			/* Sleep until we reach the next timer */
			if (iter != NULL)
				[OFThread sleepUntilDate:
				    [iter->object fireDate]];
			else {
				/*
				 * FIXME:
				 * Theoretically, another thread could add
				 * something to the run loop. This means we
				 * would need a way to block the thread until
				 * another event is added. The most easy way to
				 * achieve that would be if a run loop also
				 * handles streams: An OFStreamObserver could
				 * be called instead of sleepUntilDate above
				 * and get a timeout. If no timers are left,
				 * it could be called without a timeout and
				 * would automatically stop blocking once a new
				 * stream is added. This could also be used to
				 * stop blocking once a new timer is added.
				 */
				[OFThread sleepForTimeInterval: 24 * 3600];
			}
		}

		objc_autoreleasePoolPop(pool);
	}
}
@end
