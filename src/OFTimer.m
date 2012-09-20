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

#import "OFTimer.h"
#import "OFDate.h"
#import "OFRunLoop.h"
#import "OFThread.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFTimer
+ scheduledTimerWithTimeInterval: (double)interval
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

+ scheduledTimerWithTimeInterval: (double)interval
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

+ scheduledTimerWithTimeInterval: (double)interval
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
+ scheduledTimerWithTimeInterval: (double)interval
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

+ timerWithTimeInterval: (double)interval
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

+ timerWithTimeInterval: (double)interval
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

+ timerWithTimeInterval: (double)interval
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
+ timerWithTimeInterval: (double)interval
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
	Class c = [self class];
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- OF_initWithFireDate: (OFDate*)fireDate_
	     interval: (double)interval_
	       target: (id)target_
	     selector: (SEL)selector_
	       object: (id)object1_
	       object: (id)object2_
	    arguments: (uint8_t)arguments_
	      repeats: (BOOL)repeats_
{
	self = [super init];

	@try {
		fireDate = [fireDate_ retain];
		interval = interval_;
		target = [target_ retain];
		selector = selector_;
		object1 = [object1_ retain];
		object2 = [object2_ retain];
		arguments = arguments_;
		repeats = repeats_;
		isValid = YES;
		condition = [[OFCondition alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFireDate: (OFDate*)fireDate_
	  interval: (double)interval_
	    target: (id)target_
	  selector: (SEL)selector_
	   repeats: (BOOL)repeats_
{
	return [self OF_initWithFireDate: fireDate_
				interval: interval_
				  target: target_
				selector: selector_
				  object: nil
				  object: nil
			       arguments: 0
				 repeats: repeats_];
}

- initWithFireDate: (OFDate*)fireDate_
	  interval: (double)interval_
	    target: (id)target_
	  selector: (SEL)selector_
	    object: (id)object
	   repeats: (BOOL)repeats_
{
	return [self OF_initWithFireDate: fireDate_
				interval: interval_
				  target: target_
				selector: selector_
				  object: object
				  object: nil
			       arguments: 1
				 repeats: repeats_];
}

- initWithFireDate: (OFDate*)fireDate_
	  interval: (double)interval_
	    target: (id)target_
	  selector: (SEL)selector_
	    object: (id)object1_
	    object: (id)object2_
	   repeats: (BOOL)repeats_
{
	return [self OF_initWithFireDate: fireDate_
				interval: interval_
				  target: target_
				selector: selector_
				  object: object1_
				  object: object2_
			       arguments: 2
				 repeats: repeats_];
}

#ifdef OF_HAVE_BLOCKS
- initWithFireDate: (OFDate*)fireDate_
	   interval: (double)interval_
	    repeats: (BOOL)repeats_
	      block: (of_timer_block_t)block_
{
	self = [super init];

	@try {
		fireDate = [fireDate_ retain];
		interval = interval_;
		repeats = repeats_;
		block = [block_ copy];
		isValid = YES;
		condition = [[OFCondition alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[fireDate release];
	[target release];
	[object1 release];
	[object2 release];
#ifdef OF_HAVE_BLOCKS
	[block release];
#endif
	[condition release];

	[super dealloc];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object_
{
	OFTimer *otherTimer;

	if (![object_ isKindOfClass: [OFTimer class]])
		@throw[OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	otherTimer = (OFTimer*)object_;

	return [fireDate compare: otherTimer->fireDate];
}

- (void)fire
{
	OF_ENSURE(arguments <= 2);

#ifdef OF_HAVE_BLOCKS
	if (block != NULL)
		block(self);
	else {
#endif
		switch (arguments) {
		case 0:
			[target performSelector: selector];
			break;
		case 1:
			[target performSelector: selector
				     withObject: object1];
			break;
		case 2:
			[target performSelector: selector
				     withObject: object1
				     withObject: object2];
			break;
		}
#ifdef OF_HAVE_BLOCKS
	}
#endif

	[condition lock];
	[condition signal];
	[condition unlock];

	if (repeats && isValid) {
		OFDate *old = fireDate;
		fireDate = [[OFDate alloc]
		    initWithTimeIntervalSinceNow: interval];
		[old release];

		[[OFRunLoop currentRunLoop] addTimer: self];
	} else
		isValid = NO;
}

- (OFDate*)fireDate
{
	return [[fireDate retain] autorelease];
}

- (double)timeInterval
{
	return interval;
}

- (void)invalidate
{
	isValid = NO;
}

- (BOOL)isValid
{
	return isValid;
}

- (void)waitUntilDone
{
	[condition lock];
	[condition wait];
	[condition unlock];
}
@end
