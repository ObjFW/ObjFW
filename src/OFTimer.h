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

#import "OFObject.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFTimer;
@class OFDate;
#ifdef OF_HAVE_THREADS
@class OFCondition;
#endif

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block to execute when a timer fires.
 *
 * @param timer The timer which fired
 */
typedef void (^OFTimerBlock)(OFTimer *timer);
#endif

/**
 * @class OFTimer OFTimer.h ObjFW/ObjFW.h
 *
 * @brief A class for creating and firing timers.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFTimer: OFObject <OFComparing>
{
	OFDate *_fireDate;
	OFTimeInterval _interval;
	id _target;
	id _Nullable _object1, _object2, _object3, _object4;
	SEL _selector;
	unsigned char _arguments;
	bool _repeats;
#ifdef OF_HAVE_BLOCKS
	OFTimerBlock _block;
#endif
	bool _valid;
#ifdef OF_HAVE_THREADS
	OFCondition *_condition;
	bool _done;
#endif
	OFRunLoop *_Nullable _inRunLoop;
	OFRunLoopMode _Nullable _inRunLoopMode;
}

/**
 * @brief The time interval in which the timer will repeat, if it is a
 *	  repeating timer.
 */
@property (readonly, nonatomic) OFTimeInterval timeInterval;

/**
 * @brief Whether the timer repeats.
 */
@property (readonly, nonatomic) bool repeats;

/**
 * @brief Whether the timer is valid.
 */
@property (readonly, nonatomic, getter=isValid) bool valid;

/**
 * @brief The next date at which the timer will fire.
 *
 * If the timer is already scheduled in a run loop, it will be rescheduled.
 * Note that rescheduling is an expensive operation, though it still might be
 * preferable to reschedule instead of invalidating the timer and creating a
 * new one.
 */
@property (copy, nonatomic) OFDate *fireDate;

/**
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
				       repeats: (bool)repeats;

/**
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object
				       repeats: (bool)repeats;

/**
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object1
					object: (nullable id)object2
				       repeats: (bool)repeats;

/**
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object1
					object: (nullable id)object2
					object: (nullable id)object3
				       repeats: (bool)repeats;

/**
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param object4 The fourth object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
					target: (id)target
				      selector: (SEL)selector
					object: (nullable id)object1
					object: (nullable id)object2
					object: (nullable id)object3
					object: (nullable id)object4
				       repeats: (bool)repeats;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (OFTimeInterval)timeInterval
				       repeats: (bool)repeats
					 block: (OFTimerBlock)block;
#endif

/**
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			      repeats: (bool)repeats;

/**
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object
			      repeats: (bool)repeats;

/**
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object1
			       object: (nullable id)object2
			      repeats: (bool)repeats;

/**
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object1
			       object: (nullable id)object2
			       object: (nullable id)object3
			      repeats: (bool)repeats;

/**
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param object4 The fourth object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			       target: (id)target
			     selector: (SEL)selector
			       object: (nullable id)object1
			       object: (nullable id)object2
			       object: (nullable id)object3
			       object: (nullable id)object4
			      repeats: (bool)repeats;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Creates a new timer with the specified time interval.
 *
 * @param timeInterval The time interval after which the timer should be fired
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (OFTimeInterval)timeInterval
			      repeats: (bool)repeats
				block: (OFTimerBlock)block;
#endif

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			 repeats: (bool)repeats;

/**
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object
			 repeats: (bool)repeats;

/**
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object1
			  object: (nullable id)object2
			 repeats: (bool)repeats;

/**
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object1
			  object: (nullable id)object2
			  object: (nullable id)object3
			 repeats: (bool)repeats;

/**
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param object3 The third object to pass when calling the selector on the
 *		  target
 * @param object4 The fourth object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (nullable id)object1
			  object: (nullable id)object2
			  object: (nullable id)object3
			  object: (nullable id)object4
			 repeats: (bool)repeats;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Initializes an already allocated timer with the specified time
 *	  interval.
 *
 * @param fireDate The date at which the timer should fire
 * @param interval The time interval after which to repeat the timer, if it is
 *		   a repeating timer
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return An initialized timer
 */
- (instancetype)initWithFireDate: (OFDate *)fireDate
			interval: (OFTimeInterval)interval
			 repeats: (bool)repeats
			   block: (OFTimerBlock)block;
#endif

/**
 * @brief Compares the timer to another timer.
 *
 * @param timer The timer to compare the string to
 * @return The result of the comparison
 */
- (OFComparisonResult)compare: (OFTimer *)timer;

/**
 * @brief Fires the timer without changing its regular schedule.
 *
 * A non-repeating timer will be invalidated after firing.
 */
- (void)fire;

/**
 * @brief Invalidates the timer, preventing it from firing.
 */
- (void)invalidate;

#ifdef OF_HAVE_THREADS
/**
 * @brief Waits until the timer fired.
 */
- (void)waitUntilDone;
#endif
@end

OF_ASSUME_NONNULL_END
