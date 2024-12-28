/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OHRightJoyCon.h"
#import "OHRightJoyCon+Private.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
# import "evdev_compat.h"
#endif

static OFString *const buttonNames[] = {
	@"X", @"B", @"A", @"Y", @"R", @"ZR", @"Right Thumbstick", @"+",
	@"Home", @"SL", @"SR"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHRightJoyCon
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons copy];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"X"
							  analog: true];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"Y"
							  analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Right Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];

		_directionalPads = [[OFDictionary alloc]
		    initWithObject: directionalPad
			    forKey: @"Right Thumbstick"];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_buttons release];
	[_directionalPads release];

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	OFString *name;

	switch (button) {
	case BTN_NORTH:
		name = @"X";
		break;
	case BTN_SOUTH:
		name = @"B";
		break;
	case BTN_EAST:
		name = @"A";
		break;
	case BTN_WEST:
		name = @"Y";
		break;
	case BTN_TR:
		name = @"R";
		break;
	case BTN_TR2:
		name = @"ZR";
		break;
	case BTN_THUMBR:
		name = @"Right Thumbstick";
		break;
	case BTN_START:
		name = @"+";
		break;
	case BTN_MODE:
		name = @"Home";
		break;
	case BTN_TL:
		name = @"SL";
		break;
	case BTN_TL2:
		name = @"SR";
		break;
	default:
		return nil;
	}

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_RX:
		return [[_directionalPads
		    objectForKey: @"Right Thumbstick"] xAxis];
	case ABS_RY:
		return [[_directionalPads
		    objectForKey: @"Right Thumbstick"] yAxis];
	}

	return nil;
}
#endif
@end
