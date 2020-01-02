/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

#import "OFCondition.h"
#import "OFDate.h"

#import "OFConditionBroadcastFailedException.h"
#import "OFConditionSignalFailedException.h"
#import "OFConditionStillWaitingException.h"
#import "OFConditionWaitFailedException.h"
#import "OFInitializationFailedException.h"

@implementation OFCondition
+ (instancetype)condition
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	if (!of_condition_new(&_condition)) {
		Class c = self.class;
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass: c];
	}

	_conditionInitialized = true;

	return self;
}

- (void)dealloc
{
	if (_conditionInitialized) {
		if (!of_condition_free(&_condition)) {
			OF_ENSURE(errno == EBUSY);

			@throw [OFConditionStillWaitingException
			    exceptionWithCondition: self];
		}
	}

	[super dealloc];
}

- (void)wait
{
	if (!of_condition_wait(&_condition, &_mutex))
		@throw [OFConditionWaitFailedException
		    exceptionWithCondition: self
				     errNo: errno];
}

#ifdef OF_AMIGAOS
- (void)waitForConditionOrExecSignal: (ULONG *)signalMask
{
	if (!of_condition_wait_or_signal(&_condition, &_mutex, signalMask))
		@throw [OFConditionWaitFailedException
		    exceptionWithCondition: self
				     errNo: errno];
}
#endif

- (bool)waitForTimeInterval: (of_time_interval_t)timeInterval
{
	if (!of_condition_timed_wait(&_condition, &_mutex, timeInterval)) {
		if (errno == ETIMEDOUT)
			return false;
		else
			@throw [OFConditionWaitFailedException
			    exceptionWithCondition: self
					     errNo: errno];
	}

	return true;
}

#ifdef OF_AMIGAOS
- (bool)waitForTimeInterval: (of_time_interval_t)timeInterval
	       orExecSignal: (ULONG *)signalMask
{
	if (!of_condition_timed_wait_or_signal(&_condition, &_mutex,
	    timeInterval, signalMask)) {
		if (errno == ETIMEDOUT)
			return false;
		else
			@throw [OFConditionWaitFailedException
			    exceptionWithCondition: self
					     errNo: errno];
	}

	return true;
}
#endif

- (bool)waitUntilDate: (OFDate *)date
{
	return [self waitForTimeInterval: date.timeIntervalSinceNow];
}

#ifdef OF_AMIGAOS
- (bool)waitUntilDate: (OFDate *)date
	 orExecSignal: (ULONG *)signalMask
{
	return [self waitForTimeInterval: date.timeIntervalSinceNow
			    orExecSignal: signalMask];
}
#endif

- (void)signal
{
	if (!of_condition_signal(&_condition))
		@throw [OFConditionSignalFailedException
		    exceptionWithCondition: self
				     errNo: errno];
}

- (void)broadcast
{
	if (!of_condition_broadcast(&_condition))
		@throw [OFConditionBroadcastFailedException
		    exceptionWithCondition: self
				     errNo: errno];
}
@end
