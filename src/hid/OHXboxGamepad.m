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

#import "OHXboxGamepad.h"
#import "OHXboxGamepad+Private.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"LB", @"RB", @"LT", @"RT", @"LSB", @"RSB",
	@"Start", @"Back", @"Guide"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHXboxGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithHasGuideButton: (bool)hasGuideButton
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;
		OHGameControllerButton *up, *down, *left, *right;

		for (size_t i = 0; i < numButtons; i++) {
			bool analog = ([buttonNames[i] isEqual: @"LT"] ||
			    [buttonNames[i] isEqual: @"RT"]);
			OHGameControllerButton *button;

			if ([buttonNames[i] isEqual: @"Guide"] &&
			    !hasGuideButton)
				continue;

			button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: analog];
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
		    oh_padWithName: @"Left Thumbstick"
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

		up = [OHGameControllerButton oh_elementWithName: @"D-Pad Up"
							 analog: false];
		down = [OHGameControllerButton oh_elementWithName: @"D-Pad Down"
							   analog: false];
		left = [OHGameControllerButton oh_elementWithName: @"D-Pad Left"
							   analog: false];
		right = [OHGameControllerButton
		    oh_elementWithName: @"D-Pad Right"
				analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
				up: up
			      down: down
			      left: left
			     right: right
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
	return [_buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Back"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Guide"];
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
@end
