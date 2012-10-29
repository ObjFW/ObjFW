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

#import "OFObject.h"

@class OFTimer;
@class OFDate;
@class OFCondition;

#ifdef OF_HAVE_BLOCKS
typedef void (^of_timer_block_t)(OFTimer*);
#endif

/*!
 * @brief A class for creating and firing timers.
 */
@interface OFTimer: OFObject <OFComparing>
{
	OFDate *fireDate;
	double interval;
	id target, object1, object2;
	SEL selector;
	uint8_t arguments;
	BOOL repeats;
#ifdef OF_HAVE_BLOCKS
	of_timer_block_t block;
#endif
	BOOL isValid, done;
	OFCondition *condition;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) OFDate *fireDate;
#endif

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
					target: (id)target
				      selector: (SEL)selector
				       repeats: (BOOL)repeats;

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object
				       repeats: (BOOL)repeats;

/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
					target: (id)target
				      selector: (SEL)selector
					object: (id)object1
					object: (id)object2
				       repeats: (BOOL)repeats;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Creates and schedules a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return A new, autoreleased timer
 */
+ (instancetype)scheduledTimerWithTimeInterval: (double)interval
				       repeats: (BOOL)repeats
					 block: (of_timer_block_t)block;
#endif

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (double)interval
			       target: (id)target
			     selector: (SEL)selector
			      repeats: (BOOL)repeats;

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object An object to pass when calling the selector on the target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (double)interval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object
			      repeats: (BOOL)repeats;

/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param target The target on which to call the selector
 * @param selector The selector to call on the target
 * @param object1 The first object to pass when calling the selector on the
 *		  target
 * @param object2 The second object to pass when calling the selector on the
 *		  target
 * @param repeats Whether the timer repeats after it has been executed
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (double)interval
			       target: (id)target
			     selector: (SEL)selector
			       object: (id)object1
			       object: (id)object2
			      repeats: (BOOL)repeats;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Creates a new timer with the specified time interval.
 *
 * @param interval The time interval after which the timer should be executed
 *		   when fired
 * @param repeats Whether the timer repeats after it has been executed
 * @param block The block to invoke when the timer fires
 * @return A new, autoreleased timer
 */
+ (instancetype)timerWithTimeInterval: (double)interval
			      repeats: (BOOL)repeats
				block: (of_timer_block_t)block;
#endif

/*!
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
- initWithFireDate: (OFDate*)fireDate
	  interval: (double)interval
	    target: (id)target
	  selector: (SEL)selector
	   repeats: (BOOL)repeats;

/*!
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
- initWithFireDate: (OFDate*)fireDate
	  interval: (double)interval
	    target: (id)target
	  selector: (SEL)selector
	    object: (id)object
	   repeats: (BOOL)repeats;

/*!
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
- initWithFireDate: (OFDate*)fireDate
	  interval: (double)interval
	    target: (id)target
	  selector: (SEL)selector
	    object: (id)object1
	    object: (id)object2
	   repeats: (BOOL)repeats;

#ifdef OF_HAVE_BLOCKS
/*!
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
- initWithFireDate: (OFDate*)fireDate
	  interval: (double)interval
	   repeats: (BOOL)repeats
	     block: (of_timer_block_t)block;
#endif

/*!
 * @brief Fires the timer, meaning it will execute the specified selector on the
 *	  target.
 */
- (void)fire;

/*!
 * @brief Returns the next date at which the timer will fire.
 *
 * @return The next date at which the timer will fire
 */
- (OFDate*)fireDate;

/*!
 * @brief Invalidates the timer, preventing it from firing.
 */
- (void)invalidate;

/*!
 * @brief Returns whether the timer is valid.
 *
 * @return Whether the timer is valid
 */
- (BOOL)isValid;

/*!
 * @brief Returns the time interval in which the timer will repeat, if it is a
 *	  repeating timer.
 *
 * @return The time interval in which the timer will repeat, if it is a
 *	   repeating timer
 */
- (double)timeInterval;

/*!
 * @brief Waits until the timer fired.
 */
- (void)waitUntilDone;
@end
