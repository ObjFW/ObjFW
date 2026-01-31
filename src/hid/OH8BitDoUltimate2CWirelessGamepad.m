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

#import "OH8BitDoUltimate2CWirelessGamepad.h"
#import "OH8BitDoUltimate2CWirelessGamepad+Private.h"
#import "OFDictionary.h"
#import "OHEmulatedGameControllerTriggerButton.h"
#import "OHGameController.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
#endif

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"LB", @"RB", @"LSB", @"RSB", @"Menu", @"View",
	@"Home"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OH8BitDoUltimate2CWirelessGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithProductID: (uint16_t)productID
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OHGameControllerButton *button;
		OFMutableDictionary *directionalPads;
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		OHGameControllerAxis *axis;
#endif
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		_productID = productID;

		for (size_t i = 0; i < numButtons; i++) {
			button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		axis = [OHGameControllerAxis oh_elementWithName: @"LT"
							 analog: true];
		button = [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"LT"
				 axis: axis];
		[buttons setObject: button forKey: @"LT"];

		axis = [OHGameControllerAxis oh_elementWithName: @"RT"
							 analog: true];
		button = [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"RT"
				 axis: axis];
		[buttons setObject: button forKey: @"RT"];
#else
		button = [OHGameControllerButton oh_elementWithName: @"LT"
							     analog: true];
		[buttons setObject: button forKey: @"LT"];
		button = [OHGameControllerButton oh_elementWithName: @"RT"
							     analog: true];
		[buttons setObject: button forKey: @"RT"];
#endif

		if (productID == OHProductIDUltimate2CWirelessBT) {
			button = [OHGameControllerButton
			    oh_elementWithName: @"L4"
					analog: false];
			[buttons setObject: button forKey: @"L4"];

			button = [OHGameControllerButton
			    oh_elementWithName: @"R4"
					analog: false];
			[buttons setObject: button forKey: @"R4"];
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
		_directionalPads = objc_retain(directionalPads);

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
	return [_buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"LB"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"RB"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	return [_buttons objectForKey: @"LT"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"RT"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_buttons objectForKey: @"LSB"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_buttons objectForKey: @"RSB"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"Menu"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"View"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Home"];
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

	if (_productID == OHProductIDUltimate2CWirelessBT) {
		switch (button) {
		case BTN_C:
			return [_buttons objectForKey: @"L4"];
		case BTN_Z:
			return [_buttons objectForKey: @"R4"];
		}
	}

	switch (button) {
	case BTN_A:
		name = @"A";
		break;
	case BTN_B:
		name = @"B";
		break;
	case BTN_X:
		name = @"X";
		break;
	case BTN_Y:
		name = @"Y";
		break;
	case BTN_TL:
		name = @"LB";
		break;
	case BTN_TR:
		name = @"RB";
		break;
	case BTN_THUMBL:
		name = @"LSB";
		break;
	case BTN_THUMBR:
		name = @"RSB";
		break;
	case BTN_START:
		name = @"Menu";
		break;
	case BTN_SELECT:
		name = @"View";
		break;
	case BTN_MODE:
		name = @"Home";
		break;
	default:
		return nil;
	}

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	if (_productID == OHProductIDUltimate2CWirelessBT) {
		switch (axis) {
		case ABS_Z:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] xAxis];
		case ABS_RZ:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] yAxis];
		case ABS_BRAKE:
			return [[_buttons objectForKey: @"LT"] oh_axis];
		case ABS_GAS:
			return [[_buttons objectForKey: @"RT"] oh_axis];
		}
	} else {
		switch (axis) {
		case ABS_RX:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] xAxis];
		case ABS_RY:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] yAxis];
		case ABS_Z:
			return [[_buttons objectForKey: @"LT"] oh_axis];
		case ABS_RZ:
			return [[_buttons objectForKey: @"RT"] oh_axis];
		}
	}

	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
		    xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
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
