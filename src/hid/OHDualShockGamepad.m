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

#import "OHDualShockGamepad.h"
#import "OHDualShockGamepad+Private.h"
#import "OFDictionary.h"
#import "OHEmulatedGameControllerTriggerButton.h"
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
	@"Triangle", @"Cross", @"Square", @"Circle", @"L1", @"R1", @"L2", @"R2",
	@"L3", @"R3", @"Select", @"Start"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHDualShockGamepad
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
		OHGameControllerButton *button;
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}

		[buttons makeImmutable];
		_buttons = [buttons copy];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Left Thumbstick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Left Thumbstick Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Left Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Thumbstick"];

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Right Thumbstick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Right Thumbstick Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Right Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Thumbstick"];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad X"
							  analog: false];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad Y"
							  analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: false];
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		[directionalPads makeImmutable];
		_directionalPads = [directionalPads copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_buttons);
	objc_release(_directionalPads);

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
}

- (OHGameControllerButton *)northButton
{
	return [_buttons objectForKey: @"Triangle"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"Cross"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"Square"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"Circle"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"L1"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"R1"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	return [_buttons objectForKey: @"L2"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"R2"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_buttons objectForKey: @"L3"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_buttons objectForKey: @"R3"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"Options"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Share"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"PS"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	return [_directionalPads objectForKey: @"Left Thumbstick"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	return [_directionalPads objectForKey: @"Right Thumbstick"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	OFString *name;

	switch (button) {
	case BTN_TRIGGER:
		name = @"Triangle";
		break;
	case BTN_THUMB2:
		name = @"Cross";
		break;
	case BTN_TOP:
		name = @"Square";
		break;
	case BTN_THUMB:
		name = @"Circle";
		break;
	case BTN_BASE:
		name = @"L1";
		break;
	case BTN_BASE2:
		name = @"R1";
		break;
	case BTN_TOP2:
		name = @"L2";
		break;
	case BTN_PINKIE:
		name = @"R2";
		break;
	case BTN_BASE5:
		name = @"L3";
		break;
	case BTN_BASE6:
		name = @"R3";
		break;
	case BTN_BASE4:
		name = @"Select";
		break;
	case BTN_BASE3:
		name = @"Start";
		break;
	default:
		return nil;
	}

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
		    xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
		    yAxis];
	case ABS_RZ:
		return [[_directionalPads objectForKey: @"Right Thumbstick"]
		    xAxis];
	case ABS_Z:
		return [[_directionalPads objectForKey: @"Right Thumbstick"]
		    yAxis];
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
	default:
		return nil;
	}
}
#endif
@end
