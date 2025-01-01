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

#import "OHEmulatedGameControllerButton.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

@implementation OHEmulatedGameControllerButton
- (instancetype)oh_initWithName: (OFString *)name analog: (bool)analog
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithAxis: (OHGameControllerAxis *)axis
		       positive: (bool)positive
{
	void *pool = objc_autoreleasePoolPush();
	OFString *name;

	@try {
		name = [OFString stringWithFormat:
		    @"%@%c", axis.name, (positive ? '+' : '-')];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [super oh_initWithName: name analog: false];

	objc_autoreleasePoolPop(pool);

	_axis = [axis retain];
	_positive = positive;

	return self;
}

- (void)dealloc
{
	[_axis release];

	[super dealloc];
}

- (bool)isPressed
{
	if (_positive)
		return (_axis.value > 0);
	else
		return (_axis.value < 0);
}

- (float)value
{
	return (self.isPressed ? 1 : 0);
}
@end
