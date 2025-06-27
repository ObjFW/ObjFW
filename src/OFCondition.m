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

#include <errno.h>

#import "OFCondition.h"
#import "OFDate.h"
#import "OFString.h"

#import "OFBroadcastConditionFailedException.h"
#import "OFConditionStillWaitingException.h"
#import "OFInitializationFailedException.h"
#import "OFSignalConditionFailedException.h"
#import "OFWaitForConditionFailedException.h"

@implementation OFCondition
+ (instancetype)condition
{
	return objc_autoreleaseReturnValue([[self alloc] init]);
}

- (instancetype)init
{
	self = [super init];

	if (OFPlainConditionNew(&_condition) != 0) {
		Class c = self.class;
		objc_release(self);
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
		@throw [OFWaitForConditionFailedException
		    exceptionWithCondition: self
				     errNo: error];
}

#ifdef OF_AMIGAOS
- (void)waitForConditionOrExecSignal: (ULONG *)signalMask
{
	int error = OFPlainConditionWaitOrExecSignal(&_condition, &_mutex,
	    signalMask);

	if (error != 0)
		@throw [OFWaitForConditionFailedException
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
		@throw [OFWaitForConditionFailedException
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
		@throw [OFWaitForConditionFailedException
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
		@throw [OFSignalConditionFailedException
		    exceptionWithCondition: self
				     errNo: error];
}

- (void)broadcast
{
	int error = OFPlainConditionBroadcast(&_condition);

	if (error != 0)
		@throw [OFBroadcastConditionFailedException
		    exceptionWithCondition: self
				     errNo: error];
}
@end
