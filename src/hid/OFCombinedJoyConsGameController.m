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

#import "OFCombinedJoyConsGameController.h"
#import "OFNumber.h"
#import "OFSet.h"

#import "OFInvalidArgumentException.h"

@implementation OFCombinedJoyConsGameController
+ (instancetype)controllerWithLeftJoyCon: (OFGameController *)leftJoyCon
			     rightJoyCon: (OFGameController *)rightJoyCon
{
	return [[[self alloc] initWithLeftJoyCon: leftJoyCon
				     rightJoyCon: rightJoyCon] autorelease];
}

- (instancetype)initWithLeftJoyCon: (OFGameController *)leftJoyCon
		       rightJoyCon: (OFGameController *)rightJoyCon
{
	self = [super init];

	@try {
		if (leftJoyCon.vendorID.unsignedShortValue != 0x057E ||
		    rightJoyCon.vendorID.unsignedShortValue != 0x057E)
			@throw [OFInvalidArgumentException exception];

		if (leftJoyCon.productID.unsignedShortValue != 0x2006 ||
		    rightJoyCon.productID.unsignedShortValue != 0x2007)
			@throw [OFInvalidArgumentException exception];

		_leftJoyCon = [leftJoyCon retain];
		_rightJoyCon = [rightJoyCon retain];

		[self retrieveState];
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

	[super dealloc];
}

- (void)retrieveState
{
	[_leftJoyCon retrieveState];
	[_rightJoyCon retrieveState];
}

- (OFString *)name
{
	return @"Combined Joy-Cons";
}

- (OFSet *)buttons
{
	return [OFSet setWithObjects:
	    OFGameControllerNorthButton,
	    OFGameControllerSouthButton,
	    OFGameControllerWestButton,
	    OFGameControllerEastButton,
	    OFGameControllerLeftTriggerButton,
	    OFGameControllerRightTriggerButton,
	    OFGameControllerLeftShoulderButton,
	    OFGameControllerRightShoulderButton,
	    OFGameControllerLeftStickButton,
	    OFGameControllerRightStickButton,
	    OFGameControllerDPadUpButton,
	    OFGameControllerDPadDownButton,
	    OFGameControllerDPadLeftButton,
	    OFGameControllerDPadRightButton,
	    OFGameControllerStartButton,
	    OFGameControllerSelectButton,
	    OFGameControllerHomeButton,
	    OFGameControllerCaptureButton,
	    @"Left SL",
	    @"Right SL",
	    @"Left SR",
	    @"Right SR", nil];
}

- (OFSet OF_GENERIC(OFGameControllerButton) *)pressedButtons
{
	OFMutableSet *pressedButtons = [OFMutableSet setWithCapacity: 22];
	OFSet *leftPressedButtons = _leftJoyCon.pressedButtons;
	OFSet *rightPressedButtons = _rightJoyCon.pressedButtons;

	if ([rightPressedButtons containsObject: OFGameControllerEastButton])
		[pressedButtons addObject: OFGameControllerNorthButton];
	if ([rightPressedButtons containsObject: OFGameControllerWestButton])
		[pressedButtons addObject: OFGameControllerSouthButton];
	if ([rightPressedButtons containsObject: OFGameControllerNorthButton])
		[pressedButtons addObject: OFGameControllerWestButton];
	if ([rightPressedButtons containsObject: OFGameControllerSouthButton])
		[pressedButtons addObject: OFGameControllerEastButton];
	if ([leftPressedButtons containsObject:
	    OFGameControllerLeftTriggerButton])
		[pressedButtons addObject: OFGameControllerLeftTriggerButton];
	if ([rightPressedButtons containsObject:
	    OFGameControllerRightTriggerButton])
		[pressedButtons addObject: OFGameControllerRightTriggerButton];
	if ([leftPressedButtons containsObject:
	    OFGameControllerLeftShoulderButton])
		[pressedButtons addObject: OFGameControllerLeftShoulderButton];
	if ([rightPressedButtons containsObject:
	    OFGameControllerRightShoulderButton])
		[pressedButtons addObject: OFGameControllerRightShoulderButton];
	if ([leftPressedButtons containsObject:
	    OFGameControllerLeftStickButton])
		[pressedButtons addObject: OFGameControllerLeftStickButton];
	if ([rightPressedButtons containsObject:
	    OFGameControllerRightStickButton])
		[pressedButtons addObject: OFGameControllerRightStickButton];
	if ([leftPressedButtons containsObject: OFGameControllerWestButton])
		[pressedButtons addObject: OFGameControllerDPadUpButton];
	if ([leftPressedButtons containsObject: OFGameControllerEastButton])
		[pressedButtons addObject: OFGameControllerDPadDownButton];
	if ([leftPressedButtons containsObject: OFGameControllerSouthButton])
		[pressedButtons addObject: OFGameControllerDPadLeftButton];
	if ([leftPressedButtons containsObject: OFGameControllerNorthButton])
		[pressedButtons addObject: OFGameControllerDPadRightButton];
	if ([rightPressedButtons containsObject: OFGameControllerStartButton])
		[pressedButtons addObject: OFGameControllerStartButton];
	if ([leftPressedButtons containsObject: OFGameControllerSelectButton])
		[pressedButtons addObject: OFGameControllerSelectButton];
	if ([rightPressedButtons containsObject: OFGameControllerHomeButton])
		[pressedButtons addObject: OFGameControllerHomeButton];
	if ([leftPressedButtons containsObject: OFGameControllerCaptureButton])
		[pressedButtons addObject: OFGameControllerCaptureButton];
	if ([leftPressedButtons containsObject: @"SL"])
		[pressedButtons addObject: @"Left SL"];
	if ([rightPressedButtons containsObject: @"SL"])
		[pressedButtons addObject: @"Right SL"];
	if ([leftPressedButtons containsObject: @"SR"])
		[pressedButtons addObject: @"Left SR"];
	if ([rightPressedButtons containsObject: @"SR"])
		[pressedButtons addObject: @"Right SR"];

	[pressedButtons makeImmutable];

	return pressedButtons;
}

- (bool)hasLeftAnalogStick
{
	return true;
}

- (bool)hasRightAnalogStick
{
	return true;
}

- (OFPoint)leftAnalogStickPosition
{
	OFPoint position = _leftJoyCon.leftAnalogStickPosition;

	return OFMakePoint(-position.y, position.x);
}

- (OFPoint)rightAnalogStickPosition
{
	OFPoint position = _rightJoyCon.leftAnalogStickPosition;

	return OFMakePoint(position.y, -position.x);
}
@end
