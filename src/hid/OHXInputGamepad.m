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

#import "OHXInputGamepad.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"LB", @"RB", @"LT", @"RT", @"LSB", @"RSB",
	@"Start", @"Back", @"Guide"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHXInputGamepad
- (instancetype)init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;
		OHGameControllerButton *upButton, *downButton;
		OHGameControllerButton *leftButton, *rightButton;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button =
			    [[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]];

			@try {
				[buttons setObject: button
					    forKey: buttonNames[i]];
			} @finally {
				[button release];
			}
		}
		[buttons makeImmutable];
		_buttons = [buttons retain];

		_axes = [[OFDictionary alloc] init];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"X"] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"Y"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Left Thumbstick"
			   xAxis: xAxis
			   yAxis: yAxis] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Thumbstick"];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"RX"] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"RY"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Right Thumbstick"
			   xAxis: xAxis
			   yAxis: yAxis] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Thumbstick"];

		upButton = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Up"] autorelease];
		downButton = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Down"] autorelease];
		leftButton = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Left"] autorelease];
		rightButton = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Right"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			upButton: upButton
		      downButton: downButton
		      leftButton: leftButton
		     rightButton: rightButton] autorelease];
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		[directionalPads makeImmutable];
		_directionalPads = [directionalPads retain];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
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

- (OHGameControllerDirectionalPad *)directionalPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}
@end
