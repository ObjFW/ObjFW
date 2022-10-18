/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

	if (OFPlainConditionNew(&_condition) != 0) {
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
		int error = OFPlainConditionFree(&_condition);

		if (error != 0) {
			OFEnsure(error == EBUSY);

			@throw [OFConditionStillWaitingException
			    exceptionWithCondition: self];
		}
	}

	[super dealloc];
}

- (void)wait
{
	int error = OFPlainConditionWait(&_condition, &_mutex);

	if (error != 0)
		@throw [OFConditionWaitFailedException
		    exceptionWithCondition: self
				     errNo: error];
}

#ifdef OF_AMIGAOS
- (void)waitForConditionOrExecSignal: (ULONG *)signalMask
{
	int error = OFPlainConditionWaitOrExecSignal(&_condition, &_mutex,
	    signalMask);

	if (error != 0)
		@throw [OFConditionWaitFailedException
		    exceptionWithCondition: self
				     errNo: error];
}
#endif

- (bool)waitForTimeInterval: (OFTimeInterval)timeInterval
{
	int error = OFPlainConditionTimedWait(&_condition, &_mutex,
	    timeInterval);

	if (error == ETIMEDOUT)
		return false;

	if (error != 0)
		@throw [OFConditionWaitFailedException
		    exceptionWithCondition: self
				     errNo: error];

	return true;
}

#ifdef OF_AMIGAOS
- (bool)waitForTimeInterval: (OFTimeInterval)timeInterval
	       orExecSignal: (ULONG *)signalMask
{
	int error = OFPlainConditionTimedWaitOrExecSignal(&_condition, &_mutex,
	    timeInterval, signalMask);

	if (error == ETIMEDOUT)
		return false;

	if (error != 0)
		@throw [OFConditionWaitFailedException
		    exceptionWithCondition: self
				     errNo: error];

	return true;
}
#endif

- (bool)waitUntilDate: (OFDate *)date
{
	return [self waitForTimeInterval: date.timeIntervalSinceNow];
}

#ifdef OF_AMIGAOS
- (bool)waitUntilDate: (OFDate *)date orExecSignal: (ULONG *)signalMask
{
	return [self waitForTimeInterval: date.timeIntervalSinceNow
			    orExecSignal: signalMask];
}
#endif

- (void)signal
{
	int error = OFPlainConditionSignal(&_condition);

	if (error != 0)
		@throw [OFConditionSignalFailedException
		    exceptionWithCondition: self
				     errNo: error];
}

- (void)broadcast
{
	int error = OFPlainConditionBroadcast(&_condition);

	if (error != 0)
		@throw [OFConditionBroadcastFailedException
		    exceptionWithCondition: self
				     errNo: error];
}
@end
