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

#import "OHNintendoDSGamepad.h"
#import "OFDictionary.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"Start", @"Select"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHNintendoDSGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OHGameControllerButton *up, *down, *left, *right;
		OHGameControllerDirectionalPad *dPad;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button =
			    [[[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]] autorelease];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons retain];

		up = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Up"] autorelease];
		down = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Down"] autorelease];
		left = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Left"] autorelease];
		right = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Right"] autorelease];
		dPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			      up: up
			    down: down
			    left: left
			   right: right] autorelease];

		_directionalPads = [[OFDictionary alloc]
		    initWithObject: dPad
			    forKey: @"D-Pad"];

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

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Select"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}
@end
