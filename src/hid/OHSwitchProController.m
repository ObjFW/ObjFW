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

#import "OHSwitchProController.h"
#import "OHSwitchProController+Private.h"
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "NSString+OFObject.h"
#endif
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
	@"A", @"B", @"X", @"Y", @"L", @"R", @"ZL", @"ZR", @"Left Thumbstick",
	@"Right Thumbstick", @"+", @"-", @"Home", @"Capture"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHSwitchProController
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

		xAxis = [OHGameControllerAxis oh_elementWithName: @"X"
							  analog: true];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"Y"
							  analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Left Thumnstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Thumbstick"];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"RX"
							  analog: true];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"RY"
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
					buttonName = @"Left Thumbstick";
				else if ([buttonName isEqual: @"Right Stick"])
					buttonName = @"Right Thumbstick";
				else if ([buttonName isEqual: @"HOME"])
					buttonName = @"Home";
				else if ([buttonName isEqual: @"Share"])
					buttonName = @"Capture";

				buttonsMap[element.localizedName] =
				    _buttons[buttonName];
			}

			if ([element conformsToProtocol:
			    @protocol(GCDirectionPadElement)]) {
				OFString *padName = name;

				/* Replace these names */
				if ([padName isEqual: @"Left Stick"])
					padName = @"Left Thumbstick";
				else if ([padName isEqual: @"Right Stick"])
					padName = @"Right Thumbstick";
				else if ([padName isEqual:
				    @"Directional Buttons"])
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
	return [_buttons objectForKey: @"ZL"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"ZR"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_buttons objectForKey: @"Left Thumbstick"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_buttons objectForKey: @"Right Thumbstick"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"+"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"-"];
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

	switch (button) {
	case BTN_NORTH:
		name = @"X";
		break;
	case BTN_SOUTH:
		name = @"B";
		break;
	case BTN_WEST:
		name = @"Y";
		break;
	case BTN_EAST:
		name = @"A";
		break;
	case BTN_TL2:
		name = @"ZL";
		break;
	case BTN_TR2:
		name = @"ZR";
		break;
	case BTN_TL:
		name = @"L";
		break;
	case BTN_TR:
		name = @"R";
		break;
	case BTN_THUMBL:
		name = @"Left Thumbstick";
		break;
	case BTN_THUMBR:
		name = @"Right Thumbstick";
		break;
	case BTN_START:
		name = @"+";
		break;
	case BTN_SELECT:
		name = @"-";
		break;
	case BTN_MODE:
		name = @"Home";
		break;
	case BTN_Z:
		name = @"Capture";
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
