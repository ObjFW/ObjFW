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

#import "OHJoyConPair.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OHGameController.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHLeftJoyCon.h"
#import "OHRightJoyCon.h"

#import "OFInvalidArgumentException.h"

@implementation OHJoyConPair
@synthesize buttons = _buttons, directionalPads = _directionalPads;

+ (instancetype)gamepadWithLeftJoyCon: (OHLeftJoyCon *)leftJoyCon
			  rightJoyCon: (OHRightJoyCon *)rightJoyCon
{
	return [[[self alloc] initWithLeftJoyCon: leftJoyCon
				     rightJoyCon: rightJoyCon] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithLeftJoyCon: (OHLeftJoyCon *)leftJoyCon
		       rightJoyCon: (OHRightJoyCon *)rightJoyCon
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons, *directionalPads;

		_leftJoyCon = [leftJoyCon retain];
		_rightJoyCon = [rightJoyCon retain];

		buttons = [OFMutableDictionary dictionaryWithCapacity:
		    _leftJoyCon.buttons.count + _rightJoyCon.buttons.count];
		[buttons addEntriesFromDictionary: _leftJoyCon.buttons];
		[buttons addEntriesFromDictionary: _rightJoyCon.buttons];
		[buttons removeObjectForKey: @"SL"];
		[buttons removeObjectForKey: @"SR"];
		[buttons makeImmutable];
		_buttons = [buttons retain];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];
		[directionalPads addEntriesFromDictionary:
		    _leftJoyCon.directionalPads];
		[directionalPads addEntriesFromDictionary:
		    _rightJoyCon.directionalPads];
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
	[_leftJoyCon release];
	[_rightJoyCon release];
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
@end
