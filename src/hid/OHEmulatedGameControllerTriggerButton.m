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

#import "OHEmulatedGameControllerTriggerButton.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

@implementation OHEmulatedGameControllerTriggerButton
@synthesize oh_axis = _axis;

+ (instancetype)oh_buttonWithName: (OFString *)name analog: (bool)analog
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)oh_buttonWithName: (OFString *)name
			     axis: (OHGameControllerAxis *)axis
{
	return [[[self alloc] oh_initWithName: name axis: axis] autorelease];
}

- (instancetype)oh_initWithName: (OFString *)name analog: (bool)analog
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithName: (OFString *)name
			   axis: (OHGameControllerAxis *)axis
{
	self = [super oh_initWithName: name analog: true];

	_axis = [axis retain];

	return self;
}

- (void)dealloc
{
	[_axis release];

	[super dealloc];
}

- (bool)isPressed
{
	return (_axis.value > -1);
}

- (float)value
{
	return (_axis.value + 1) / 2;
}
@end
