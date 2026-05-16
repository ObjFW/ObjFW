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

#import "OH8BitDoPro2Gamepad.h"
#import "OH8BitDoPro2Gamepad+Private.h"
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
	@"A", @"B", @"X", @"Y", @"L", @"R", @"L2", @"R2", @"L3", @"R3",
	@"Start", @"Select", @"Home"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OH8BitDoPro2Gamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithVIDPID: (OHVIDPID)VIDPID
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

		_VIDPID = VIDPID;

		for (size_t i = 0; i < numButtons; i++) {
			button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}

		if (!OHEqualVIDPIDs(_VIDPID,
		    OHVIDPIDXboxOneWirelessController)) {
			button = [OHGameControllerButton
			    oh_elementWithName: @"P1"
					analog: false];
			[buttons setObject: button forKey: @"P1"];

			button = [OHGameControllerButton
			    oh_elementWithName: @"P2"
					analog: false];
			[buttons setObject: button forKey: @"P2"];
		}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		axis = [OHGameControllerAxis oh_elementWithName: @"L2"
							 analog: true];
		button = [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"L2"
				 axis: axis];
		[buttons setObject: button forKey: @"L2"];

		axis = [OHGameControllerAxis oh_elementWithName: @"R2"
							 analog: true];
		button = [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"R2"
				 axis: axis];
		[buttons setObject: button forKey: @"R2"];
#else
		button = [OHGameControllerButton oh_elementWithName: @"L2"
							     analog: true];
		[buttons setObject: button forKey: @"L2"];
		button = [OHGameControllerButton oh_elementWithName: @"R2"
							     analog: true];
		[buttons setObject: button forKey: @"R2"];
#endif

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
	return [_buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"L"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"R"];
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
	return [_buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Select"];
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

	if (OHEqualVIDPIDs(_VIDPID, OHVIDPIDXboxOneWirelessController)) {
		switch (button) {
		case BTN_B:
			name = @"A";
			break;
		case BTN_A:
			name = @"B";
			break;
		case BTN_X:
			name = @"X";
			break;
		case BTN_C:
			name = @"Y";
			break;
		case BTN_Y:
			name = @"L";
			break;
		case BTN_Z:
			name = @"R";
			break;
		case BTN_TL2:
			name = @"L3";
			break;
		case BTN_TR2:
			name = @"R3";
			break;
		case BTN_TR:
			name = @"Start";
			break;
		case BTN_TL:
			name = @"Select";
			break;
		case KEY_MENU:
			name = @"Home";
			break;
		default:
			return nil;
		}
	} else {
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
			name = @"L";
			break;
		case BTN_TR:
			name = @"R";
			break;
		case BTN_THUMBL:
			name = @"L3";
			break;
		case BTN_THUMBR:
			name = @"R3";
			break;
		case BTN_Z:
			name = @"P1";
			break;
		case BTN_C:
			name = @"P2";
			break;
		case BTN_START:
			name = @"Start";
			break;
		case BTN_SELECT:
			name = @"Select";
			break;
		case BTN_MODE:
			name = @"Home";
			break;
		default:
			return nil;
		}
	}

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey:
		    @"Left Thumbstick"] xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey:
		    @"Left Thumbstick"] yAxis];
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
	}

	if (OHEqualVIDPIDs(_VIDPID, OHVIDPIDXboxOneWirelessController)) {
		switch (axis) {
		case ABS_RX:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] xAxis];
		case ABS_RY:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] yAxis];
		case ABS_Z:
			return [[_buttons objectForKey: @"L2"] oh_axis];
		case ABS_RZ:
			return [[_buttons objectForKey: @"R2"] oh_axis];
		default:
			return nil;
		}
	} else {
		switch (axis) {
		case ABS_Z:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] xAxis];
		case ABS_RZ:
			return [[_directionalPads objectForKey:
			    @"Right Thumbstick"] yAxis];
		case ABS_BRAKE:
			return [[_buttons objectForKey: @"L2"] oh_axis];
		case ABS_GAS:
			return [[_buttons objectForKey: @"R2"] oh_axis];
		default:
			return nil;
		}
	}
}
#endif
@end
