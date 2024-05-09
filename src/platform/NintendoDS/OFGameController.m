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

#import "OFGameController.h"
#import "OFArray.h"
#import "OFSet.h"

#import "OFOutOfRangeException.h"

#define asm __asm__
#include <nds.h>
#undef asm

@interface OFGameController ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
@end

static OFArray OF_GENERIC(OFGameController *) *controllers;

static void
initControllers(void)
{
	void *pool = objc_autoreleasePoolPush();

	controllers = [[OFArray alloc] initWithObject:
	    [[[OFGameController alloc] of_init] autorelease]];

	objc_autoreleasePoolPop(pool);
}

@implementation OFGameController
@dynamic leftAnalogStickPosition, rightAnalogStickPosition;

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	static OFOnceControl onceControl = OFOnceControlInitValue;

	OFOnce(&onceControl, initControllers);

	return [[controllers retain] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (OFString *)name
{
	return @"Nintendo DS";
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)buttons
{
	return [OFSet setWithObjects: OFGameControllerButtonA,
	    OFGameControllerButtonB, OFGameControllerButtonSelect,
	    OFGameControllerButtonStart, OFGameControllerButtonDPadRight,
	    OFGameControllerButtonDPadLeft, OFGameControllerButtonDPadUp,
	    OFGameControllerButtonDPadDown, OFGameControllerButtonR,
	    OFGameControllerButtonL, OFGameControllerButtonX,
	    OFGameControllerButtonY, nil];
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)pressedButtons
{
	OFMutableSet OF_GENERIC(OFGameControllerButton) *pressedButtons =
	    [OFMutableSet setWithCapacity: 12];
	uint32 keys;

	scanKeys();
	keys = keysCurrent();

	if (keys & KEY_A)
		[pressedButtons addObject: OFGameControllerButtonA];
	if (keys & KEY_B)
		[pressedButtons addObject: OFGameControllerButtonB];
	if (keys & KEY_SELECT)
		[pressedButtons addObject: OFGameControllerButtonSelect];
	if (keys & KEY_START)
		[pressedButtons addObject: OFGameControllerButtonStart];
	if (keys & KEY_RIGHT)
		[pressedButtons addObject: OFGameControllerButtonDPadRight];
	if (keys & KEY_LEFT)
		[pressedButtons addObject: OFGameControllerButtonDPadLeft];
	if (keys & KEY_UP)
		[pressedButtons addObject: OFGameControllerButtonDPadUp];
	if (keys & KEY_DOWN)
		[pressedButtons addObject: OFGameControllerButtonDPadDown];
	if (keys & KEY_R)
		[pressedButtons addObject: OFGameControllerButtonR];
	if (keys & KEY_L)
		[pressedButtons addObject: OFGameControllerButtonL];
	if (keys & KEY_X)
		[pressedButtons addObject: OFGameControllerButtonX];
	if (keys & KEY_Y)
		[pressedButtons addObject: OFGameControllerButtonY];

	[pressedButtons makeImmutable];

	return pressedButtons;
}

- (bool)hasLeftAnalogStick
{
	return false;
}

- (bool)hasRightAnalogStick
{
	return false;
}

- (float)pressureForButton: (OFGameControllerButton)button
{
	return ([self.pressedButtons containsObject: button] ? 1 : 0);
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
