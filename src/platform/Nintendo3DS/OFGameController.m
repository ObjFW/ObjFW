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

#define id id_3ds
#include <3ds.h>
#undef id

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
@synthesize leftAnalogStickPosition = _leftAnalogStickPosition;
@dynamic rightAnalogStickPosition;

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

	if (keys & KEY_A)
		[_pressedButtons addObject: OFGameControllerButtonA];
	if (keys & KEY_B)
		[_pressedButtons addObject: OFGameControllerButtonB];
	if (keys & KEY_SELECT)
		[_pressedButtons addObject: OFGameControllerButtonSelect];
	if (keys & KEY_START)
		[_pressedButtons addObject: OFGameControllerButtonStart];
	if (keys & KEY_DRIGHT)
		[_pressedButtons addObject: OFGameControllerButtonDPadRight];
	if (keys & KEY_DLEFT)
		[_pressedButtons addObject: OFGameControllerButtonDPadLeft];
	if (keys & KEY_DUP)
		[_pressedButtons addObject: OFGameControllerButtonDPadUp];
	if (keys & KEY_DDOWN)
		[_pressedButtons addObject: OFGameControllerButtonDPadDown];
	if (keys & KEY_R)
		[_pressedButtons addObject: OFGameControllerButtonR];
	if (keys & KEY_L)
		[_pressedButtons addObject: OFGameControllerButtonL];
	if (keys & KEY_X)
		[_pressedButtons addObject: OFGameControllerButtonX];
	if (keys & KEY_Y)
		[_pressedButtons addObject: OFGameControllerButtonY];
	if (keys & KEY_ZL)
		[_pressedButtons addObject: OFGameControllerButtonZL];
	if (keys & KEY_ZR)
		[_pressedButtons addObject: OFGameControllerButtonZR];
	if (keys & KEY_CSTICK_RIGHT)
		[_pressedButtons addObject: OFGameControllerButtonCPadRight];
	if (keys & KEY_CSTICK_LEFT)
		[_pressedButtons addObject: OFGameControllerButtonCPadLeft];
	if (keys & KEY_CSTICK_UP)
		[_pressedButtons addObject: OFGameControllerButtonCPadUp];
	if (keys & KEY_CSTICK_DOWN)
		[_pressedButtons addObject: OFGameControllerButtonCPadDown];

	_leftAnalogStickPosition = OFMakePoint(
	    (float)pos.dx / (pos.dx < 0 ? -INT16_MIN : INT16_MAX),
	    (float)pos.dy / (pos.dy < 0 ? -INT16_MIN : INT16_MAX));
}

- (OFString *)name
{
	return @"Nintendo 3DS";
}

- (OFNumber *)vendorID
{
	return nil;
}

- (OFNumber *)productID
{
	return nil;
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)buttons
{
	return [OFSet setWithObjects: OFGameControllerButtonA,
	    OFGameControllerButtonB, OFGameControllerButtonSelect,
	    OFGameControllerButtonStart, OFGameControllerButtonDPadRight,
	    OFGameControllerButtonDPadLeft, OFGameControllerButtonDPadUp,
	    OFGameControllerButtonDPadDown, OFGameControllerButtonR,
	    OFGameControllerButtonL, OFGameControllerButtonX,
	    OFGameControllerButtonY, OFGameControllerButtonZL,
	    OFGameControllerButtonZR, OFGameControllerButtonCPadRight,
	    OFGameControllerButtonCPadLeft, OFGameControllerButtonCPadUp,
	    OFGameControllerButtonCPadDown, nil];
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

- (float)pressureForButton: (OFGameControllerButton)button
{
	return ([self.pressedButtons containsObject: button] ? 1 : 0);
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
