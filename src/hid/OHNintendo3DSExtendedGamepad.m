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

#import "OHNintendo3DSExtendedGamepad.h"
#import "OHNintendo3DSExtendedGamepad+Private.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"ZL", @"ZR", @"Start", @"Select"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHNintendo3DSExtendedGamepad
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
		OHGameControllerButton *up, *down, *left, *right;

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
		    oh_elementWithName: @"Circle Pad X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Circle Pad Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Circle Pad"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Circle Pad"];

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"C-Stick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"C-Stick Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"C-Stick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"C-Stick"];

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
	return [_buttons objectForKey: @"ZL"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"ZR"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return nil;
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return nil;
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
	return nil;
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	return [_directionalPads objectForKey: @"Circle Pad"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	return [_directionalPads objectForKey: @"C-Stick"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}
@end
