/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <stdlib.h>

#import "OFTimer.h"
#import "OFTimer+Private.h"
#import "OFDate.h"
#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#ifdef OF_HAVE_THREADS
# import "OFCondition.h"
#endif

#import "OFInvalidArgumentException.h"

@implementation OFTimer
@synthesize timeInterval = _interval, repeats = _repeats, valid = _valid;

+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
				       repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							   repeats: repeats]);

	[[OFRunLoop currentRunLoop] addTimer: timer];

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object
				       repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object
							   repeats: repeats]);

	[[OFRunLoop currentRunLoop] addTimer: timer];

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object1
					object: (id)object2
				       repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object1
							    object: object2
							   repeats: repeats]);

	[[OFRunLoop currentRunLoop] addTimer: timer];

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object1
					object: (id)object2
					object: (id)object3
				       repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object1
							    object: object2
							    object: object3
							   repeats: repeats]);

	[[OFRunLoop currentRunLoop] addTimer: timer];

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object1
					object: (id)object2
					object: (id)object3
					object: (id)object4
				       repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object1
							    object: object2
							    object: object3
							    object: object4
							   repeats: repeats]);

	[[OFRunLoop currentRunLoop] addTimer: timer];

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

#ifdef OF_HAVE_BLOCKS
+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
				       repeats: (bool)repeats
					 block: (OFTimerBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							   repeats: repeats
							     block: block]);

	[[OFRunLoop currentRunLoop] addTimer: timer];

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}
#endif

+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			      repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							   repeats: repeats]);

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object
			      repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object
							   repeats: repeats]);

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object1
			       object: (id)object2
			      repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object1
							    object: object2
							   repeats: repeats]);

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object1
			       object: (id)object2
			       object: (id)object3
			      repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object1
							    object: object2
							    object: object3
							   repeats: repeats]);

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object1
			       object: (id)object2
			       object: (id)object3
			       object: (id)object4
			      repeats: (bool)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							    target: target
							  selector: selector
							    object: object1
							    object: object2
							    object: object3
							    object: object4
							   repeats: repeats]);

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}

#ifdef OF_HAVE_BLOCKS
+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			      repeats: (bool)repeats
				block: (OFTimerBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: timeInterval];
	id timer = objc_autorelease([[self alloc] initWithFireDate: fireDate
							  interval: timeInterval
							   repeats: repeats
							     block: block]);

	objc_retain(timer);
	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(timer);
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithFireDate: (OFDate *)fireDate
			   interval: (OFTimeInterval)interval
			     target: (id)target
			   selector: (SEL)selector
			     object: (id)object1
			     object: (id)object2
			     object: (id)object3
			     object: (id)object4
			  arguments: (unsigned char)arguments
			    repeats: (bool)repeats
    OF_METHOD_FAMILY(init) OF_DIRECT
{
	self = [super init];

	@try {
		_fireDate = objc_retain(fireDate);
		_interval = interval;
		_target = objc_retain(target);
		_selector = selector;
		_object1 = objc_retain(object1);
		_object2 = objc_retain(object2);
		_object3 = objc_retain(object3);
		_object4 = objc_retain(object4);
		_arguments = arguments;
		_repeats = repeats;
		_valid = true;
#ifdef OF_HAVE_THREADS
		_condition = [[OFCondition alloc] init];
#endif
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			 repeats: (bool)repeats
{
	return [self of_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: nil
				  object: nil
				  object: nil
				  object: nil
			       arguments: 0
				 repeats: repeats];
}

- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (id)object
			 repeats: (bool)repeats
{
	return [self of_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: object
				  object: nil
				  object: nil
				  object: nil
			       arguments: 1
				 repeats: repeats];
}

- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (id)object1
			  object: (id)object2
			 repeats: (bool)repeats
{
	return [self of_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: object1
				  object: object2
				  object: nil
				  object: nil
			       arguments: 2
				 repeats: repeats];
}

- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (id)object1
			  object: (id)object2
			  object: (id)object3
			 repeats: (bool)repeats
{
	return [self of_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: object1
				  object: object2
				  object: object3
				  object: nil
			       arguments: 3
				 repeats: repeats];
}

- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (id)object1
			  object: (id)object2
			  object: (id)object3
			  object: (id)object4
			 repeats: (bool)repeats
{
	return [self of_initWithFireDate: fireDate
				interval: interval
				  target: target
				selector: selector
				  object: object1
				  object: object2
				  object: object3
				  object: object4
			       arguments: 4
				 repeats: repeats];
}

#ifdef OF_HAVE_BLOCKS
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			 repeats: (bool)repeats
			   block: (OFTimerBlock)block
{
	self = [super init];

	@try {
		_fireDate = objc_retain(fireDate);
		_interval = interval;
		_repeats = repeats;
		_block = [block copy];
		_valid = true;
# ifdef OF_HAVE_THREADS
		_condition = [[OFCondition alloc] init];
# endif
	} @catch (id e) {
		objc_release(self);
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
	OFAssert(_inRunLoop == nil);
	OFAssert(_inRunLoopMode == nil);

	objc_release(_fireDate);
	objc_release(_target);
	objc_release(_object1);
	objc_release(_object2);
	objc_release(_object3);
	objc_release(_object4);
#ifdef OF_HAVE_BLOCKS
	objc_release(_block);
#endif
#ifdef OF_HAVE_THREADS
	objc_release(_condition);
#endif

	[super dealloc];
}

- (OFComparisonResult)compare: (OFTimer *)timer
{
	if (![timer isKindOfClass: [OFTimer class]])
		@throw [OFInvalidArgumentException exception];

	return [_fireDate compare: timer->_fireDate];
}

- (void)of_setInRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode
{
	OFRunLoop *oldInRunLoop = _inRunLoop;
	OFRunLoopMode oldInRunLoopMode = _inRunLoopMode;

	_inRunLoop = objc_retain(runLoop);
	objc_release(oldInRunLoop);

	_inRunLoopMode = [mode copy];
	objc_release(oldInRunLoopMode);
}

- (void)of_reschedule
{
	long long missedIntervals;
	OFTimeInterval newFireDate;
	OFRunLoop *runLoop;

	if (!_repeats || !_valid)
		return;

	missedIntervals = -_fireDate.timeIntervalSinceNow / _interval;

	/* In case the clock was changed backwards */
	if (missedIntervals < 0)
		missedIntervals = 0;

	newFireDate = _fireDate.timeIntervalSince1970 +
	    (missedIntervals + 1) * _interval;

	objc_release(_fireDate);
	_fireDate = nil;
	_fireDate = [[OFDate alloc]
	    initWithTimeIntervalSince1970: newFireDate];

	runLoop = [OFRunLoop currentRunLoop];
	[runLoop addTimer: self forMode: runLoop.currentMode];
}

- (void)fire
{
	OFEnsure(_arguments <= 4);

	if (!_valid)
		return;

#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		_block(self);
	else {
#endif
		IMP method = [_target methodForSelector: _selector];

		switch (_arguments) {
		case 0:
			((void (*)(id, SEL))method)(_target, _selector);
			break;
		case 1:
			((void (*)(id, SEL, id))method)(_target, _selector,
			    _object1);
			break;
		case 2:
			((void (*)(id, SEL, id, id))method)(_target, _selector,
			    _object1, _object2);
			break;
		case 3:
			((void (*)(id, SEL, id, id, id))method)(_target,
			    _selector, _object1, _object2, _object3);
		case 4:
			((void (*)(id, SEL, id, id, id, id))method)(_target,
			    _selector, _object1, _object2, _object3, _object4);
			break;
		}
#ifdef OF_HAVE_BLOCKS
	}
#endif

	if  (!_repeats)
		[self invalidate];

#ifdef OF_HAVE_THREADS
	[_condition lock];
	@try {
		_done = true;
		[_condition signal];
	} @finally {
		[_condition unlock];
	}
#endif
}

- (OFDate *)fireDate
{
	return _fireDate;
}

- (void)setFireDate: (OFDate *)fireDate
{
	objc_retain(self);
	@try {
		@synchronized (self) {
			OFDate *old;

			[_inRunLoop of_removeTimer: self
					   forMode: _inRunLoopMode];

			old = _fireDate;
			_fireDate = [fireDate copy];
			objc_release(old);

			[_inRunLoop addTimer: self forMode: _inRunLoopMode];
		}
	} @finally {
		objc_release(self);
	}
}

- (void)invalidate
{
	_valid = false;

#ifdef OF_HAVE_BLOCKS
	objc_release(_block);
#endif
	objc_release(_target);
	objc_release(_object1);
	objc_release(_object2);
	objc_release(_object3);
	objc_release(_object4);

	_target = nil;
	_object1 = nil;
	_object2 = nil;
	_object3 = nil;
	_object4 = nil;
}

#ifdef OF_HAVE_THREADS
- (void)waitUntilDone
{
	[_condition lock];
	@try {
		if (_done) {
			_done = false;
			return;
		}

		[_condition wait];
	} @finally {
		[_condition unlock];
	}
}
#endif

- (OFString *)description
{
#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		return [OFString stringWithFormat:
		    @"<%@:\n"
		    @"\tFire date: %@\n"
		    @"\tInterval: %lf\n"
		    @"\tRepeats: %s\n"
		    @"\tBlock: %@\n"
		    @"\tValid: %s\n"
		    @">",
		    self.class, _fireDate, _interval, (_repeats ? "yes" : "no"),
		    _block, (_valid ? "yes" : "no")];
	else {
#endif
		void *pool = objc_autoreleasePoolPush();
		OFString *objects = @"", *ret;

		if (_arguments >= 1)
			objects = [objects stringByAppendingFormat:
			    @"\tObject: %@\n", _object1];
		if (_arguments >= 2)
			objects = [objects stringByAppendingFormat:
			    @"\tObject: %@\n", _object2];
		if (_arguments >= 3)
			objects = [objects stringByAppendingFormat:
			    @"\tObject: %@\n", _object3];
		if (_arguments >= 4)
			objects = [objects stringByAppendingFormat:
			    @"\tObject: %@\n", _object4];

		ret = [[OFString alloc] initWithFormat:
		    @"<%@:\n"
		    @"\tFire date: %@\n"
		    @"\tInterval: %lf\n"
		    @"\tRepeats: %s\n"
		    @"\tTarget: %@\n"
		    @"\tSelector: %s\n"
		    @"%@"
		    @"\tValid: %s\n"
		    @">",
		    self.class, _fireDate, _interval, (_repeats ? "yes" : "no"),
		    _target, sel_getName(_selector), objects,
		    (_valid ? "yes" : "no")];

		objc_autoreleasePoolPop(pool);

		return objc_autoreleaseReturnValue(ret);
#ifdef OF_HAVE_BLOCKS
	}
#endif
}
@end
