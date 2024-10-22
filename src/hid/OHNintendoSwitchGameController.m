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

#import "OHNintendoSwitchGameController.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHNintendoSwitchExtendedGamepad.h"

#import "OFInitializationFailedException.h"
#import "OFReadFailedException.h"

#define id nx_id
#include <switch.h>
#undef id

static const size_t maxControllers = 8;

@implementation OHNintendoSwitchGameController
@synthesize extendedGamepad = _extendedGamepad;

+ (void)initialize
{
	if (self == [OHNintendoSwitchGameController class])
		padConfigureInput(maxControllers, HidNpadStyleSet_NpadFullCtrl);
}

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (size_t i = 0; i < maxControllers; i++) {
		OHGameController *controller;

		@try {
			controller = [[[OHNintendoSwitchGameController alloc]
			    initWithIndex: i] autorelease];
		} @catch (OFInitializationFailedException *e) {
			/* Controller does not exist. */
			continue;
		}

		[controllers addObject: controller];
	}

	[controllers makeImmutable];

	objc_autoreleasePoolPop(pool);

	return controllers;
}

- (instancetype)initWithIndex: (size_t)index
{
	self = [super init];

	@try {
		padInitialize(&_pad, HidNpadIdType_No1 + index,
		    (index == 0 ? HidNpadIdType_Handheld : 0));
		padUpdate(&_pad);

		if (!padIsConnected(&_pad))
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_extendedGamepad =
		    [[OHNintendoSwitchExtendedGamepad alloc] init];

		[self updateState];
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

- (void)updateState
{
	void *pool = objc_autoreleasePoolPush();
	OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *)
	    *buttons = _extendedGamepad.buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *directionalPads = _extendedGamepad.directionalPads;
	u64 keys;
	HidAnalogStickState stick;
	OHGameControllerDirectionalPad *directionalPad;

	padUpdate(&_pad);
	keys = padGetButtons(&_pad);

	[[buttons objectForKey: @"A"] setValue: !!(keys & HidNpadButton_A)];
	[[buttons objectForKey: @"B"] setValue: !!(keys & HidNpadButton_B)];
	[[buttons objectForKey: @"X"] setValue: !!(keys & HidNpadButton_X)];
	[[buttons objectForKey: @"Y"] setValue: !!(keys & HidNpadButton_Y)];
	[[buttons objectForKey: @"L"] setValue: !!(keys & HidNpadButton_L)];
	[[buttons objectForKey: @"R"] setValue: !!(keys & HidNpadButton_R)];
	[[buttons objectForKey: @"ZL"] setValue: !!(keys & HidNpadButton_ZL)];
	[[buttons objectForKey: @"ZR"] setValue: !!(keys & HidNpadButton_ZR)];
	[[buttons objectForKey: @"Left Thumbstick"]
	    setValue: !!(keys & HidNpadButton_StickL)];
	[[buttons objectForKey: @"Right Thumbstick"]
	    setValue: !!(keys & HidNpadButton_StickR)];
	[[buttons objectForKey: @"+"] setValue: !!(keys & HidNpadButton_Plus)];
	[[buttons objectForKey: @"-"] setValue: !!(keys & HidNpadButton_Minus)];

	stick = padGetStickPos(&_pad, 0);
	directionalPad = [directionalPads objectForKey: @"Left Thumbstick"];
	[directionalPad.xAxis setValue:
	    (float)stick.x / (stick.x < 0 ? -INT16_MIN : INT16_MAX)];
	[directionalPad.yAxis setValue:
	    -(float)stick.y / (stick.y < 0 ? -INT16_MIN : INT16_MAX)];

	stick = padGetStickPos(&_pad, 1);
	directionalPad = [directionalPads objectForKey: @"Right Thumbstick"];
	[directionalPad.xAxis setValue:
	    (float)stick.x / (stick.x < 0 ? -INT16_MIN : INT16_MAX)];
	[directionalPad.yAxis setValue:
	    -(float)stick.y / (stick.y < 0 ? -INT16_MIN : INT16_MAX)];

	directionalPad = [directionalPads objectForKey: @"D-Pad"];
	[directionalPad.up setValue: !!(keys & keys & HidNpadButton_Up)];
	[directionalPad.down setValue: !!(keys & keys & HidNpadButton_Down)];
	[directionalPad.left setValue: !!(keys & keys & HidNpadButton_Left)];
	[directionalPad.right setValue: !!(keys & keys & HidNpadButton_Right)];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)name
{
	return @"Nintendo Switch";
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
