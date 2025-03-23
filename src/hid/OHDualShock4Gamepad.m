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

#import "OHDualShock4Gamepad.h"
#import "OHDualShock4Gamepad+Private.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_GCF
# import "OFString+NSObject.h"
#endif
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
	@"Triangle", @"Cross", @"Square", @"Circle", @"L1", @"R1", @"L3", @"R3",
	@"Options", @"Share", @"PS"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

#ifdef OF_HAVE_GCF
static OFDictionary<OFString *, NSString *> *buttonsMap;
static OFDictionary<OFString *, NSString *> *directionalPadsMap;
#endif

@implementation OHDualShock4Gamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

#ifdef OF_HAVE_GCF
+ (void)initialize
{
	void *pool;

	if (self != [OHDualShock4Gamepad class])
		return;

	pool = objc_autoreleasePoolPush();

	buttonsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"Triangle", @"Button Y".NSObject,
	    @"Cross", @"Button A".NSObject,
	    @"Square", @"Button X".NSObject,
	    @"Circle", @"Button B".NSObject,
	    @"L1", @"Left Shoulder".NSObject,
	    @"R1", @"Right Shoulder".NSObject,
	    @"L2", @"Left Trigger".NSObject,
	    @"R2", @"Right Trigger".NSObject,
	    @"L3", @"Left Thumbstick".NSObject,
	    @"R3", @"Right Thumbstick".NSObject,
	    @"Options", @"Button Menu".NSObject,
	    @"Share", @"Button Options".NSObject,
	    @"PS", @"Button Home".NSObject,
	    nil];
	directionalPadsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"Left Thumbstick", @"Left Thumbstick".NSObject,
	    @"Right Thumbstick", @"Right Thumbstick".NSObject,
	    @"D-Pad", @"Direction Pad".NSObject,
	    nil];

	objc_autoreleasePoolPop(pool);
}
#endif

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
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		OHGameControllerAxis *axis;
#endif
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
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
		_directionalPads = [directionalPads copy];

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
	case BTN_NORTH:
		name = @"Triangle";
		break;
	case BTN_SOUTH:
		name = @"Cross";
		break;
	case BTN_WEST:
		name = @"Square";
		break;
	case BTN_EAST:
		name = @"Circle";
		break;
	case BTN_TL:
		name = @"L1";
		break;
	case BTN_TR:
		name = @"R1";
		break;
	case BTN_THUMBL:
		name = @"L3";
		break;
	case BTN_THUMBR:
		name = @"R3";
		break;
	case BTN_START:
		name = @"Options";
		break;
	case BTN_SELECT:
		name = @"Share";
		break;
	case BTN_MODE:
		name = @"PS";
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
	case ABS_RX:
		return [[_directionalPads objectForKey: @"Right Thumbstick"]
		    xAxis];
	case ABS_RY:
		return [[_directionalPads objectForKey: @"Right Thumbstick"]
		    yAxis];
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
	case ABS_Z:
		return [[_buttons objectForKey: @"L2"] oh_axis];
	case ABS_RZ:
		return [[_buttons objectForKey: @"R2"] oh_axis];
	default:
		return nil;
	}
}
#endif

#ifdef OF_HAVE_GCF
- (OFDictionary<OFString *, NSString *> *)oh_buttonsMap
{
	return buttonsMap;
}

- (OFDictionary<OFString *, NSString *> *)oh_axesMap
{
	return [OFDictionary dictionary];
}

- (OFDictionary<OFString *, NSString *> *)oh_directionalPadsMap
{
	return directionalPadsMap;
}
#endif
@end
