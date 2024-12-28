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

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import <GameController/GameController.h>
#endif

#import "OHDualSenseGamepad.h"
#import "OHDualSenseGamepad+Private.h"
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "NSString+OFObject.h"
#endif
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
	@"Triangle", @"Cross", @"Square", @"Circle", @"L1", @"R1", @"L3", @"R3",
	@"Options", @"Create", @"PS"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHDualSenseGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
@synthesize oh_buttonsMap = _buttonsMap;
@synthesize oh_directionalPadsMap = _directionalPadsMap;
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

		xAxis = [OHGameControllerAxis oh_elementWithName: @"X"
							  analog: true];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"Y"
							  analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Left Stick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Stick"];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"RX"
							  analog: true];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"RY"
							  analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Right Stick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Stick"];

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

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
- (instancetype)oh_initWithLiveInput: (GCControllerLiveInput *)liveInput
{
	self = [self oh_init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttonsMap =
		    [OFMutableDictionary dictionary];
		OFMutableDictionary *directionalPadsMap =
		    [OFMutableDictionary dictionary];

		for (id <GCPhysicalInputElement> element in
		    liveInput.elements) {
			/*
			 * Unfortunately there is no way to get the unlocalized
			 * name or an identifier, but it seems in practice this
			 * is not localized. Let's hope it stays this way.
			 */
			OFString *name = element.localizedName.OFObject;

			if ([element conformsToProtocol:
			    @protocol(GCButtonElement)]) {
				OFString *buttonName = name;

				/*
				 * We don't use "Button" as part of a button
				 * name, but GameController.framework likes to
				 * do this.
				 */
				if ([buttonName hasSuffix: @" Button"])
					buttonName = [buttonName
					    substringToIndex:
					    buttonName.length - 7];

				/* Replace these names */
				if ([buttonName isEqual: @"Left Stick"])
					buttonName = @"L3";
				else if ([buttonName isEqual: @"Right Stick"])
					buttonName = @"R3";

				buttonsMap[element.localizedName] =
				    _buttons[buttonName];
			}

			if ([element conformsToProtocol:
			    @protocol(GCDirectionPadElement)]) {
				OFString *padName = name;

				if ([padName isEqual: @"Direction Pad"])
					padName = @"D-Pad";

				directionalPadsMap[element.localizedName] =
				    _directionalPads[padName];
			}
		}

		[buttonsMap makeImmutable];
		[directionalPadsMap makeImmutable];

		_buttonsMap = [buttonsMap copy];
		_directionalPadsMap = [directionalPadsMap copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[_buttons release];
	[_directionalPads release];
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
	[_buttonsMap release];
	[_directionalPadsMap release];
#endif

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
	return [_buttons objectForKey: @"Create"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"PS"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	return [_directionalPads objectForKey: @"Left Stick"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	return [_directionalPads objectForKey: @"Right Stick"];
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
		name = @"Create";
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
		return [[_directionalPads objectForKey: @"Left Stick"] xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Left Stick"] yAxis];
	case ABS_RX:
		return [[_directionalPads objectForKey: @"Right Stick"] xAxis];
	case ABS_RY:
		return [[_directionalPads objectForKey: @"Right Stick"] yAxis];
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

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
- (OFDictionary<NSString *, OHGameControllerAxis *> *)oh_axesMap
{
	return [OFDictionary dictionary];
}
#endif
@end
