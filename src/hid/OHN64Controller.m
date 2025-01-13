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

#import "OHN64Controller.h"
#import "OHN64Controller+Private.h"
#import "OFDictionary.h"
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
	@"A", @"B", @"L", @"R", @"Z", @"Start"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHN64Controller
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
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;
#ifndef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
		OHGameControllerButton *up, *down, *left, *right;
#endif

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons copy];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Thumbstick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Thumbstick Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Thumbstick"];

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

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
		xAxis = [OHGameControllerAxis oh_elementWithName: @"C-Buttons X"
							  analog: false];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"C-Buttons Y"
							  analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"C-Buttons"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: false];
#else
		up = [OHGameControllerButton oh_elementWithName: @"C-Up"
							 analog: false];
		down = [OHGameControllerButton oh_elementWithName: @"C-Down"
							   analog: false];
		left = [OHGameControllerButton oh_elementWithName: @"C-Left"
							   analog: false];
		right = [OHGameControllerButton oh_elementWithName: @"C-Right"
							    analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"C-Buttons"
				up: up
			      down: down
			      left: left
			     right: right
			    analog: false];
#endif
		[directionalPads setObject: directionalPad
				    forKey: @"C-Buttons"];

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

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	switch (button) {
	case BTN_A:
		return [_buttons objectForKey: @"A"];
	case BTN_B:
		return [_buttons objectForKey: @"B"];
	case BTN_TL2:
		return [_buttons objectForKey: @"Z"];
	case BTN_SELECT:
		return [[_directionalPads objectForKey: @"C-Buttons"] up];
	case BTN_X:
		return [[_directionalPads objectForKey: @"C-Buttons"] down];
	case BTN_Y:
		return [[_directionalPads objectForKey: @"C-Buttons"] left];
	case BTN_C:
		return [[_directionalPads objectForKey: @"C-Buttons"] right];
	case BTN_TL:
		return [_buttons objectForKey: @"L"];
	case BTN_TR:
		return [_buttons objectForKey: @"R"];
	case BTN_START:
		return [_buttons objectForKey: @"Start"];
	}

	return nil;
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey: @"Thumbstick"] xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Thumbstick"] yAxis];
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
	}

	return nil;
}
#endif
@end
