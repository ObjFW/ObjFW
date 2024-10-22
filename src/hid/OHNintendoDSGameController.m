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

#import "OHNintendoDSGameController.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHNintendoDSGamepad.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"

#define asm __asm__
#include <nds.h>
#undef asm

static OFArray OF_GENERIC(OHGameController *) *controllers;

@implementation OHNintendoDSGameController
@synthesize gamepad = _gamepad;

+ (void)initialize
{
	void *pool;

	if (self != [OHNintendoDSGameController class])
		return;

	pool = objc_autoreleasePoolPush();
	controllers = [[OFArray alloc] initWithObject:
	    [[[OHNintendoDSGameController alloc] init] autorelease]];
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
		_gamepad = [[OHNintendoDSGamepad alloc] init];

		[self updateState];
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

- (void)updateState
{
	OFDictionary *buttons = _gamepad.buttons;
	OHGameControllerDirectionalPad *dPad =
	    [_gamepad.directionalPads objectForKey: @"D-Pad"];
	u32 keys;

	scanKeys();
	keys = keysCurrent();

	[[buttons objectForKey: @"A"] setValue: !!(keys & KEY_A)];
	[[buttons objectForKey: @"B"] setValue: !!(keys & KEY_B)];
	[[buttons objectForKey: @"X"] setValue: !!(keys & KEY_X)];
	[[buttons objectForKey: @"Y"] setValue: !!(keys & KEY_Y)];
	[[buttons objectForKey: @"L"] setValue: !!(keys & KEY_L)];
	[[buttons objectForKey: @"R"] setValue: !!(keys & KEY_R)];
	[[buttons objectForKey: @"Start"] setValue: !!(keys & KEY_START)];
	[[buttons objectForKey: @"Select"] setValue: !!(keys & KEY_SELECT)];

	[dPad.up setValue: !!(keys & KEY_UP)];
	[dPad.down setValue: !!(keys & KEY_DOWN)];
	[dPad.left setValue: !!(keys & KEY_LEFT)];
	[dPad.right setValue: !!(keys & KEY_RIGHT)];
}

- (OFString *)name
{
	return @"Nintendo DS";
}

- (id <OHGameControllerProfile>)profile
{
	return _gamepad;
}
@end
