/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OHGameControllerAxis.h"
#import "OHGameControllerAxis+Private.h"
#import "OFNotification.h"
#import "OFNotificationCenter.h"

const OFNotificationName OHGameControllerAxisValueDidChangeNotification =
    @"OHGameControllerAxisValueDidChangeNotification";

@implementation OHGameControllerAxis
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
@synthesize oh_minRawValue = _minRawValue, oh_maxRawValue = _maxRawValue;
#endif

- (float)value
{
	return _value;
}

- (void)setValue: (float)value
{
	void *pool;
	OFNotification *notification;

	if (value == _value)
		return;

	_value = value;

	pool = objc_autoreleasePoolPush();

	notification = [OFNotification
	    notificationWithName: OHGameControllerAxisValueDidChangeNotification
			  object: self];
	[[OFNotificationCenter defaultCenter] postNotification: notification];

	objc_autoreleasePoolPop(pool);
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
/* Change to a smaller type on ABI bump and switch to @synthesize */
- (bool)oh_isInverted
{
	return _inverted;
}

- (void)oh_setInverted: (bool)inverted
{
	_inverted = inverted;
}
#endif

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
