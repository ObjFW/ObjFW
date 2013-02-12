/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <stdlib.h>

#include <assert.h>

#import "OFTimer.h"
#import "OFDate.h"
#import "OFRunLoop.h"
#ifdef OF_HAVE_THREADS
# import "OFCondition.h"
#endif

#import "OFInvalidArgumentException.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFTimer
+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
					target: (id)target
				      selector: (SEL)selector
				       repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					   repeats: repeats] autorelease];

	[[OFRunLoop currentRunLoop] addTimer: timer];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object
				       repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object
					   repeats: repeats] autorelease];

	[[OFRunLoop currentRunLoop] addTimer: timer];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object1
					object: (id)object2
				       repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object1
					    object: object2
					   repeats: repeats] autorelease];

	[[OFRunLoop currentRunLoop] addTimer: timer];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

#ifdef OF_HAVE_BLOCKS
+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
				       repeats: (BOOL)repeats
					 block: (of_timer_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					   repeats: repeats
					     block: block] autorelease];

	[[OFRunLoop currentRunLoop] addTimer: timer];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}
#endif

+ (instancetype)timerWithTimeInterval: (double)interval
			       target: (id)target
			     selector: (SEL)selector
			      repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					   repeats: repeats] autorelease];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ (instancetype)timerWithTimeInterval: (double)interval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object
			      repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object
					   repeats: repeats] autorelease];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ (instancetype)timerWithTimeInterval: (double)interval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object1
			       object: (id)object2
			      repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object1
					    object: object2
					   repeats: repeats] autorelease];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

#ifdef OF_HAVE_BLOCKS
+ (instancetype)timerWithTimeInterval: (double)interval
			      repeats: (BOOL)repeats
				block: (of_timer_block_t)block
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					   repeats: repeats
					     block: block] autorelease];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}
#endif

- init
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	abort();
}

- OF_initWithFireDate: (OFDate*)fireDate
	     interval: (double)interval
	       target: (id)target
	     selector: (SEL)selector
	       object: (id)object1
	       object: (id)object2
	    arguments: (uint8_t)arguments
	      repeats: (BOOL)repeats
{
	self = [super init];

	@try {
		_fireDate = [fireDate retain];
		_interval = interval;
		_target = [target retain];
		_selector = selector;
		_object1 = [object1 retain];
		_object2 = [object2 retain];
		_arguments = arguments;
		_repeats = repeats;
		_valid = YES;
#ifdef OF_HAVE_THREADS
		_condition = [[OFCondition alloc] init];
#endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFireDate: (OFDate*)fireDate
	  interval: (double)interval
	    target: (id)target
	  selector: (SEL)selector
	   repeats: (BOOL)repeats
{
	return [self OF_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: nil
				  object: nil
			       arguments: 0
				 repeats: repeats];
}

- initWithFireDate: (OFDate*)fireDate
	  interval: (double)interval
	    target: (id)target
	  selector: (SEL)selector
	    object: (id)object
	   repeats: (BOOL)repeats
{
	return [self OF_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: object
				  object: nil
			       arguments: 1
				 repeats: repeats];
}

- initWithFireDate: (OFDate*)fireDate
	  interval: (double)interval
	    target: (id)target
	  selector: (SEL)selector
	    object: (id)object1
	    object: (id)object2
	   repeats: (BOOL)repeats
{
	return [self OF_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: object1
				  object: object2
			       arguments: 2
				 repeats: repeats];
}

#ifdef OF_HAVE_BLOCKS
- initWithFireDate: (OFDate*)fireDate
	   interval: (double)interval
	    repeats: (BOOL)repeats
	      block: (of_timer_block_t)block
{
	self = [super init];

	@try {
		_fireDate = [fireDate retain];
		_interval = interval;
		_repeats = repeats;
		_block = [block copy];
		_valid = YES;
# ifdef OF_HAVE_THREADS
		_condition = [[OFCondition alloc] init];
# endif
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	/*
	 * The run loop references the timer, so it should never be deallocated
	 * if it is still in a run loop.
	 */
	assert(_inRunLoop == nil);

	[_fireDate release];
	[_target release];
	[_object1 release];
	[_object2 release];
#ifdef OF_HAVE_BLOCKS
	[_block release];
#endif
#ifdef OF_HAVE_THREADS
	[_condition release];
#endif

	[super dealloc];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	OFTimer *timer;

	if (![object isKindOfClass: [OFTimer class]])
		@throw[OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	timer = (OFTimer*)object;

	return [_fireDate compare: timer->_fireDate];
}

- (void)fire
{
	OF_ENSURE(_arguments <= 2);

#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block(self);
	else {
#endif
		switch (_arguments) {
		case 0:
			[_target performSelector: _selector];
			break;
		case 1:
			[_target performSelector: _selector
				      withObject: _object1];
			break;
		case 2:
			[_target performSelector: _selector
				      withObject: _object1
				      withObject: _object2];
			break;
		}
#ifdef OF_HAVE_BLOCKS
	}
#endif

#ifdef OF_HAVE_THREADS
	[_condition lock];
	@try {
		_done = YES;
		[_condition signal];
	} @finally {
		[_condition unlock];
	}
#endif

	if (_repeats && _valid) {
		OFDate *old = _fireDate;
		_fireDate = [[OFDate alloc]
		    initWithTimeIntervalSinceNow: _interval];
		[old release];

		[[OFRunLoop currentRunLoop] addTimer: self];
	} else
		[self invalidate];
}

- (OFDate*)fireDate
{
	OF_GETTER(_fireDate, YES)
}

- (void)setFireDate: (OFDate*)fireDate
{
	[self retain];
	@try {
		@synchronized (self) {
			[_inRunLoop OF_removeTimer: self];

			OF_SETTER(_fireDate, fireDate, YES, 0)

			[_inRunLoop addTimer: self];
		}
	} @finally {
		[self release];
	}
}

- (double)timeInterval
{
	return _interval;
}

- (void)invalidate
{
	_valid = NO;

	[_target release];
	_target = nil;
}

- (BOOL)isValid
{
	return _valid;
}

#ifdef OF_HAVE_THREADS
- (void)waitUntilDone
{
	[_condition lock];
	@try {
		if (_done) {
			_done = NO;
			return;
		}

		[_condition wait];
	} @finally {
		[_condition unlock];
	}
}
#endif

- (void)OF_setInRunLoop: (OFRunLoop*)inRunLoop
{
	OF_SETTER(_inRunLoop, inRunLoop, YES, 0)
}
@end
