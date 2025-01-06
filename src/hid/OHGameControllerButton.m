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

#import "OHGameControllerButton.h"
#import "OFNotification.h"
#import "OFNotificationCenter.h"

const OFNotificationName OHGameControllerButtonValueDidChangeNotification =
    @"OHGameControllerButtonValueDidChangeNotification";

@implementation OHGameControllerButton
- (float)value
{
	return _value;
}

- (void)setValue: (float)value
{
	void *pool;
	OFNotificationName name;
	OFNotification *notification;

	if (value == _value)
		return;

	_value = value;

	pool = objc_autoreleasePoolPush();

	name = OHGameControllerButtonValueDidChangeNotification;
	notification = [OFNotification notificationWithName: name
						     object: self];
	[[OFNotificationCenter defaultCenter] postNotification: notification];

	objc_autoreleasePoolPop(pool);
}

- (bool)isPressed
{
	return (_value > 0);
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
