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

#import "OHEvdevExtendedGamepad.h"
#import "OFDictionary.h"
#import "OHEmulatedGameControllerTriggerButton.h"
#import "OHEvdevGameController.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"

#import "OFInvalidArgumentException.h"

@implementation OHEvdevExtendedGamepad
- (instancetype)oh_initWithKeyBits: (unsigned long *)keyBits
			    evBits: (unsigned long *)evBits
			   absBits: (unsigned long *)absBits
			  vendorID: (uint16_t)vendorID
			 productID: (uint16_t)productID
{
	self = [super oh_initWithKeyBits: keyBits
				  evBits: evBits
				 absBits: absBits
				vendorID: vendorID
			       productID: productID];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (self.northButton == nil || self.southButton == nil ||
		    self.westButton == nil || self.eastButton == nil ||
		    self.leftShoulderButton == nil ||
		    self.rightShoulderButton == nil ||
		    self.leftTriggerButton == nil ||
		    self.rightTriggerButton == nil || self.menuButton == nil ||
		    self.optionsButton == nil || self.leftThumbstick == nil ||
		    self.rightThumbstick == nil || self.dPad == nil)
			object_setClass(self,
			    [OHEvdevGameControllerProfile class]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *)buttons
{
	OFMutableDictionary *buttons = [[_buttons mutableCopy] autorelease];

	[buttons removeObjectForKey: @"D-Pad Up"];
	[buttons removeObjectForKey: @"D-Pad Down"];
	[buttons removeObjectForKey: @"D-Pad Left"];
	[buttons removeObjectForKey: @"D-Pad Right"];

	if ([_axes objectForKey: @"Z"] != nil)
		[buttons setObject: self.leftTriggerButton forKey: @"LT"];

	if ([_axes objectForKey: @"RZ"] != nil)
		[buttons setObject: self.rightTriggerButton forKey: @"RT"];

	[buttons makeImmutable];

	return buttons;
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	OFMutableDictionary *axes = [[_axes mutableCopy] autorelease];

	[axes removeObjectForKey: @"X"];
	[axes removeObjectForKey: @"Y"];
	[axes removeObjectForKey: @"RX"];
	[axes removeObjectForKey: @"RY"];
	[axes removeObjectForKey: @"Z"];
	[axes removeObjectForKey: @"RZ"];
	[axes removeObjectForKey: @"HAT0X"];
	[axes removeObjectForKey: @"HAT0Y"];

	[axes makeImmutable];

	return axes;
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *) *)
    directionalPads
{
	return [OFDictionary dictionaryWithKeysAndObjects:
	    @"Left Thumbstick", self.leftThumbstick,
	    @"Right Thumbstick", self.rightThumbstick,
	    @"D-Pad", self.dPad, nil];
}

- (OHGameControllerButton *)northButton
{
	return [_buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"LB"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"RB"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	OHGameControllerAxis *axis = [_axes objectForKey: @"Z"];

	if (axis != nil)
		return [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"LT"
				 axis: axis];

	return [_buttons objectForKey: @"LT"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	OHGameControllerAxis *axis = [_axes objectForKey: @"RZ"];

	if (axis != nil)
		return [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"RT"
				 axis: axis];

	return [_buttons objectForKey: @"RT"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_buttons objectForKey: @"LSB"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_buttons objectForKey: @"RSB"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Back"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Guide"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	OHGameControllerAxis *xAxis = [_axes objectForKey: @"X"];
	OHGameControllerAxis *yAxis = [_axes objectForKey: @"Y"];

	if (xAxis == nil || yAxis == nil)
		return nil;

	return [OHGameControllerDirectionalPad
	    oh_padWithName: @"Left Thumbstick"
		     xAxis: xAxis
		     yAxis: yAxis
		    analog: true];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	OHGameControllerAxis *xAxis = [_axes objectForKey: @"RX"];
	OHGameControllerAxis *yAxis = [_axes objectForKey: @"RY"];

	if (xAxis == nil || yAxis == nil)
		return nil;

	return [OHGameControllerDirectionalPad
	    oh_padWithName: @"Right Thumbstick"
		     xAxis: xAxis
		     yAxis: yAxis
		    analog: true];
}

- (OHGameControllerDirectionalPad *)dPad
{
	OHGameControllerAxis *xAxis = [_axes objectForKey: @"HAT0X"];
	OHGameControllerAxis *yAxis = [_axes objectForKey: @"HAT0Y"];
	OHGameControllerButton *up, *down, *left, *right;

	if (xAxis != nil && yAxis != nil)
		return [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: false];

	up = [_buttons objectForKey: @"D-Pad Up"];
	down = [_buttons objectForKey: @"D-Pad Down"];
	left = [_buttons objectForKey: @"D-Pad Left"];
	right = [_buttons objectForKey: @"D-Pad Right"];

	if (up != nil && down != nil && left != nil && right != nil)
		return [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
				up: up
			      down: down
			      left: left
			     right: right
			    analog: false];

	return nil;
}
@end
