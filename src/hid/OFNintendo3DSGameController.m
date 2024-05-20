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

#import "OFNintendo3DSGameController.h"
#import "OFArray.h"
#import "OFSet.h"

#import "OFOutOfRangeException.h"

#define id id_3ds
#include <3ds.h>
#undef id

static OFArray OF_GENERIC(OFGameController *) *controllers;

@implementation OFNintendo3DSGameController
@synthesize leftAnalogStickPosition = _leftAnalogStickPosition;

+ (void)initialize
{
	void *pool;

	if (self != [OFNintendo3DSGameController class])
		return;

	pool = objc_autoreleasePoolPush();
	controllers = [[OFArray alloc] initWithObject:
	    [[[OFNintendo3DSGameController alloc] init] autorelease]];
	objc_autoreleasePoolPop(pool);
}

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	return controllers;
}

- (instancetype)init
{
	self = [super init];

	@try {
		_pressedButtons = [[OFMutableSet alloc] initWithCapacity: 18];

		[self retrieveState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_pressedButtons release];

	[super dealloc];
}

- (void)retrieveState
{
	u32 keys;
	circlePosition pos;

	hidScanInput();

	keys = hidKeysHeld();
	hidCircleRead(&pos);

	[_pressedButtons removeAllObjects];

	if (keys & KEY_X)
		[_pressedButtons addObject: OFGameControllerNorthButton];
	if (keys & KEY_B)
		[_pressedButtons addObject: OFGameControllerSouthButton];
	if (keys & KEY_Y)
		[_pressedButtons addObject: OFGameControllerWestButton];
	if (keys & KEY_A)
		[_pressedButtons addObject: OFGameControllerEastButton];
	if (keys & KEY_ZL)
		[_pressedButtons addObject: OFGameControllerLeftTriggerButton];
	if (keys & KEY_ZR)
		[_pressedButtons addObject: OFGameControllerRightTriggerButton];
	if (keys & KEY_L)
		[_pressedButtons addObject: OFGameControllerLeftShoulderButton];
	if (keys & KEY_R)
		[_pressedButtons addObject:
		    OFGameControllerRightShoulderButton];
	if (keys & KEY_DUP)
		[_pressedButtons addObject: OFGameControllerDPadUpButton];
	if (keys & KEY_DDOWN)
		[_pressedButtons addObject: OFGameControllerDPadDownButton];
	if (keys & KEY_DLEFT)
		[_pressedButtons addObject: OFGameControllerDPadLeftButton];
	if (keys & KEY_DRIGHT)
		[_pressedButtons addObject: OFGameControllerDPadRightButton];
	if (keys & KEY_START)
		[_pressedButtons addObject: OFGameControllerStartButton];
	if (keys & KEY_SELECT)
		[_pressedButtons addObject: OFGameControllerSelectButton];
	if (keys & KEY_CSTICK_UP)
		[_pressedButtons addObject: OFGameControllerCPadUpButton];
	if (keys & KEY_CSTICK_DOWN)
		[_pressedButtons addObject: OFGameControllerCPadDownButton];
	if (keys & KEY_CSTICK_LEFT)
		[_pressedButtons addObject: OFGameControllerCPadLeftButton];
	if (keys & KEY_CSTICK_RIGHT)
		[_pressedButtons addObject: OFGameControllerCPadRightButton];

	if (pos.dx > 150)
		pos.dx = 150;
	if (pos.dx < -150)
		pos.dx = -150;
	if (pos.dy > 150)
		pos.dy = 150;
	if (pos.dy < -150)
		pos.dy = -150;

	_leftAnalogStickPosition = OFMakePoint(
	    (float)pos.dx / 150, -(float)pos.dy / 150);
}

- (OFString *)name
{
	return @"Nintendo 3DS";
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)buttons
{
	return [OFSet setWithObjects:
	    OFGameControllerNorthButton,
	    OFGameControllerSouthButton,
	    OFGameControllerWestButton,
	    OFGameControllerEastButton,
	    OFGameControllerLeftTriggerButton,
	    OFGameControllerRightTriggerButton,
	    OFGameControllerRightShoulderButton,
	    OFGameControllerLeftShoulderButton,
	    OFGameControllerDPadUpButton,
	    OFGameControllerDPadDownButton,
	    OFGameControllerDPadLeftButton,
	    OFGameControllerDPadRightButton,
	    OFGameControllerStartButton,
	    OFGameControllerSelectButton,
	    OFGameControllerCPadRightButton,
	    OFGameControllerCPadLeftButton,
	    OFGameControllerCPadUpButton,
	    OFGameControllerCPadDownButton, nil];
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)pressedButtons
{
	return [[_pressedButtons copy] autorelease];
}

- (bool)hasLeftAnalogStick
{
	return true;
}

- (bool)hasRightAnalogStick
{
	return false;
}
@end
