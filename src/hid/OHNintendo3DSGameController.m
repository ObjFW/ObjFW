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

#import "OHNintendo3DSGameController.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHNintendo3DSGamepad.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"

#define id id_3ds
#include <3ds.h>
#undef id

static OFArray OF_GENERIC(OHGameController *) *controllers;

@implementation OHNintendo3DSGameController
@synthesize gamepad = _gamepad;

+ (void)initialize
{
	void *pool;

	if (self != [OHNintendo3DSGameController class])
		return;

	pool = objc_autoreleasePoolPush();
	controllers = [[OFArray alloc] initWithObject:
	    [[[OHNintendo3DSGameController alloc] init] autorelease]];
	objc_autoreleasePoolPop(pool);
}

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	return controllers;
}

- (instancetype)init
{
	self = [super init];

	@try {
		_gamepad = [[OHNintendo3DSGamepad alloc] init];

		[self retrieveState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_gamepad release];

	[super dealloc];
}

- (void)retrieveState
{
	u32 keys;
	circlePosition leftPos, rightPos;

	hidScanInput();

	keys = hidKeysHeld();
	hidCircleRead(&leftPos);
	hidCstickRead(&rightPos);

	[_gamepad.northButton setValue: !!(keys & KEY_X)];
	[_gamepad.southButton setValue: !!(keys & KEY_B)];
	[_gamepad.westButton setValue: !!(keys & KEY_Y)];
	[_gamepad.eastButton setValue: !!(keys & KEY_A)];
	[_gamepad.leftShoulderButton setValue: !!(keys & KEY_L)];
	[_gamepad.rightShoulderButton setValue: !!(keys & KEY_R)];
	[_gamepad.leftTriggerButton setValue: !!(keys & KEY_ZL)];
	[_gamepad.rightTriggerButton setValue: !!(keys & KEY_ZR)];
	[_gamepad.menuButton setValue: !!(keys & KEY_START)];
	[_gamepad.optionsButton setValue: !!(keys & KEY_SELECT)];

	if (leftPos.dx > 150)
		leftPos.dx = 150;
	if (leftPos.dx < -150)
		leftPos.dx = -150;
	if (leftPos.dy > 150)
		leftPos.dy = 150;
	if (leftPos.dy < -150)
		leftPos.dy = -150;

	if (rightPos.dx > 150)
		rightPos.dx = 150;
	if (rightPos.dx < -150)
		rightPos.dx = -150;
	if (rightPos.dy > 150)
		rightPos.dy = 150;
	if (rightPos.dy < -150)
		rightPos.dy = -150;

	_gamepad.leftThumbstick.xAxis.value = (float)leftPos.dx / 150;
	_gamepad.leftThumbstick.yAxis.value = -(float)leftPos.dy / 150;
	_gamepad.rightThumbstick.xAxis.value = (float)rightPos.dx / 150;
	_gamepad.rightThumbstick.yAxis.value = -(float)rightPos.dy / 150;

	[_gamepad.dPad.up setValue: !!(keys & KEY_DUP)];
	[_gamepad.dPad.down setValue: !!(keys & KEY_DDOWN)];
	[_gamepad.dPad.left setValue: !!(keys & KEY_DLEFT)];
	[_gamepad.dPad.right setValue: !!(keys & KEY_DRIGHT)];
}

- (OFString *)name
{
	return @"Nintendo 3DS";
}

- (OHGameControllerProfile *)rawProfile
{
	return _gamepad;
}
@end
