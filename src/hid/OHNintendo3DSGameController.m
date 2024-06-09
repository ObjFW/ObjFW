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
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHNintendo3DSExtendedGamepad.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"

#define id id_3ds
#include <3ds.h>
#undef id

static OFArray OF_GENERIC(OHGameController *) *controllers;

@implementation OHNintendo3DSGameController
@synthesize extendedGamepad = _extendedGamepad;

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
		_extendedGamepad = [[OHNintendo3DSExtendedGamepad alloc] init];

		[self retrieveState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_extendedGamepad release];

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

	[_extendedGamepad.northButton setValue: !!(keys & KEY_X)];
	[_extendedGamepad.southButton setValue: !!(keys & KEY_B)];
	[_extendedGamepad.westButton setValue: !!(keys & KEY_Y)];
	[_extendedGamepad.eastButton setValue: !!(keys & KEY_A)];
	[_extendedGamepad.leftShoulderButton setValue: !!(keys & KEY_L)];
	[_extendedGamepad.rightShoulderButton setValue: !!(keys & KEY_R)];
	[_extendedGamepad.leftTriggerButton setValue: !!(keys & KEY_ZL)];
	[_extendedGamepad.rightTriggerButton setValue: !!(keys & KEY_ZR)];
	[_extendedGamepad.menuButton setValue: !!(keys & KEY_START)];
	[_extendedGamepad.optionsButton setValue: !!(keys & KEY_SELECT)];

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

	_extendedGamepad.leftThumbstick.xAxis.value = (float)leftPos.dx / 150;
	_extendedGamepad.leftThumbstick.yAxis.value = -(float)leftPos.dy / 150;
	_extendedGamepad.rightThumbstick.xAxis.value = (float)rightPos.dx / 150;
	_extendedGamepad.rightThumbstick.yAxis.value =
	    -(float)rightPos.dy / 150;

	[_extendedGamepad.dPad.up setValue: !!(keys & KEY_DUP)];
	[_extendedGamepad.dPad.down setValue: !!(keys & KEY_DDOWN)];
	[_extendedGamepad.dPad.left setValue: !!(keys & KEY_DLEFT)];
	[_extendedGamepad.dPad.right setValue: !!(keys & KEY_DRIGHT)];
}

- (OFString *)name
{
	return @"Nintendo 3DS";
}

- (id <OHGameControllerProfile>)rawProfile
{
	return _extendedGamepad;
}

- (id <OHGamepad>)gamepad
{
	return _extendedGamepad;
}
@end
