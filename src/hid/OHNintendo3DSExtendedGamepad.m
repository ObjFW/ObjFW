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

#import "OHNintendo3DSExtendedGamepad.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"ZL", @"ZR", @"Start", @"Select"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHNintendo3DSExtendedGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

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
		OHGameControllerButton *up, *down, *left, *right;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button =
			    [[[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]] autorelease];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons retain];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"X"] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"Y"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Circle Pad"
			   xAxis: xAxis
			   yAxis: yAxis] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Circle Pad"];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"CX"] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"CY"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"C-Stick"
			   xAxis: xAxis
			   yAxis: yAxis] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"C-Stick"];

		up = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Up"] autorelease];
		down = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Down"] autorelease];
		left = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Left"] autorelease];
		right = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Right"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			      up: up
			    down: down
			    left: left
			   right: right] autorelease];
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
