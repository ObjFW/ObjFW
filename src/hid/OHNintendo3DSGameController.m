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

#import "OHNintendo3DSGameController.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OHGameController.h"
#import "OHGameController+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHNintendo3DSExtendedGamepad.h"
#import "OHNintendo3DSExtendedGamepad+Private.h"

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
	    objc_autorelease([[OHNintendo3DSGameController alloc] oh_init])];
	objc_autoreleasePoolPop(pool);
}

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	return controllers;
}

- (instancetype)oh_init
{
	self = [super oh_init];

	@try {
		_extendedGamepad =
		    [[OHNintendo3DSExtendedGamepad alloc] oh_init];

		[self updateState];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_extendedGamepad);

	[super dealloc];
}

- (void)updateState
{
	void *pool = objc_autoreleasePoolPush();
	OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *)
	    *buttons = _extendedGamepad.buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *directionalPads = _extendedGamepad.directionalPads;
	u32 keys;
	circlePosition leftPos, rightPos;
	OHGameControllerDirectionalPad *directionalPad;

	hidScanInput();

	keys = hidKeysHeld();
	hidCircleRead(&leftPos);
	hidCstickRead(&rightPos);

	[[buttons objectForKey: @"A"] setValue: !!(keys & KEY_A)];
	[[buttons objectForKey: @"B"] setValue: !!(keys & KEY_B)];
	[[buttons objectForKey: @"X"] setValue: !!(keys & KEY_X)];
	[[buttons objectForKey: @"Y"] setValue: !!(keys & KEY_Y)];
	[[buttons objectForKey: @"L"] setValue: !!(keys & KEY_L)];
	[[buttons objectForKey: @"R"] setValue: !!(keys & KEY_R)];
	[[buttons objectForKey: @"ZL"] setValue: !!(keys & KEY_ZL)];
	[[buttons objectForKey: @"ZR"] setValue: !!(keys & KEY_ZR)];
	[[buttons objectForKey: @"Start"] setValue: !!(keys & KEY_START)];
	[[buttons objectForKey: @"Select"] setValue: !!(keys & KEY_SELECT)];

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

	directionalPad = [directionalPads objectForKey: @"Circle Pad"];
	directionalPad.xAxis.value = (float)leftPos.dx / 150;
	directionalPad.yAxis.value = -(float)leftPos.dy / 150;

	directionalPad = [directionalPads objectForKey: @"C-Stick"];
	directionalPad.xAxis.value = (float)rightPos.dx / 150;
	directionalPad.yAxis.value = -(float)rightPos.dy / 150;

	directionalPad = [directionalPads objectForKey: @"D-Pad"];
	[directionalPad.up setValue: !!(keys & KEY_DUP)];
	[directionalPad.down setValue: !!(keys & KEY_DDOWN)];
	[directionalPad.left setValue: !!(keys & KEY_DLEFT)];
	[directionalPad.right setValue: !!(keys & KEY_DRIGHT)];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)name
{
	return @"Nintendo 3DS";
}

- (id <OHGameControllerProfile>)profile
{
	return _extendedGamepad;
}

- (id <OHGamepad>)gamepad
{
	return _extendedGamepad;
}
@end
