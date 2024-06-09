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
#import "OHEvdevGameController.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerEmulatedTriggerButton.h"

#import "OFInvalidArgumentException.h"

@implementation OHEvdevExtendedGamepad
- (instancetype)initWithController: (OHEvdevGameController *)controller
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_rawProfile = [controller.rawProfile retain];

		if (self.northButton == nil || self.southButton == nil ||
		    self.westButton == nil || self.eastButton == nil ||
		    self.leftShoulderButton == nil ||
		    self.rightShoulderButton == nil ||
		    self.leftTriggerButton == nil ||
		    self.rightTriggerButton == nil || self.menuButton == nil ||
		    self.optionsButton == nil || self.leftThumbstick == nil ||
		    self.rightThumbstick == nil || self.dPad == nil)
			@throw [OFInvalidArgumentException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_rawProfile release];

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *)buttons
{
	OFMutableDictionary *buttons =
	    [[_rawProfile.buttons mutableCopy] autorelease];

	[buttons removeObjectForKey: @"D-Pad Up"];
	[buttons removeObjectForKey: @"D-Pad Down"];
	[buttons removeObjectForKey: @"D-Pad Left"];
	[buttons removeObjectForKey: @"D-Pad Right"];

	if ([_rawProfile.axes objectForKey: @"Z"] != nil)
		[buttons setObject: self.leftTriggerButton forKey: @"LT"];

	if ([_rawProfile.axes objectForKey: @"RZ"] != nil)
		[buttons setObject: self.rightTriggerButton forKey: @"RT"];

	[buttons makeImmutable];

	return buttons;
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	OFMutableDictionary *axes =
	    [[_rawProfile.axes mutableCopy] autorelease];

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
	return [_rawProfile.buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)southButton
{
	return [_rawProfile.buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)westButton
{
	return [_rawProfile.buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)eastButton
{
	return [_rawProfile.buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_rawProfile.buttons objectForKey: @"LB"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_rawProfile.buttons objectForKey: @"RB"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	OHGameControllerAxis *axis = [_rawProfile.axes objectForKey: @"Z"];

	if (axis != nil)
		return [[[OHGameControllerEmulatedTriggerButton alloc]
		    initWithName: @"LT"
			    axis: axis] autorelease];

	return [_rawProfile.buttons objectForKey: @"LT"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	OHGameControllerAxis *axis = [_rawProfile.axes objectForKey: @"RZ"];

	if (axis != nil)
		return [[[OHGameControllerEmulatedTriggerButton alloc]
		    initWithName: @"RT"
			    axis: axis] autorelease];

	return [_rawProfile.buttons objectForKey: @"RT"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_rawProfile.buttons objectForKey: @"LSB"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_rawProfile.buttons objectForKey: @"RSB"];
}

- (OHGameControllerButton *)menuButton
{
	return [_rawProfile.buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_rawProfile.buttons objectForKey: @"Back"];
}

- (OHGameControllerButton *)homeButton
{
	return [_rawProfile.buttons objectForKey: @"Guide"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	OHGameControllerAxis *xAxis = [_rawProfile.axes objectForKey: @"X"];
	OHGameControllerAxis *yAxis = [_rawProfile.axes objectForKey: @"Y"];

	if (xAxis == nil || yAxis == nil)
		return nil;

	return [[[OHGameControllerDirectionalPad alloc]
	    initWithName: @"Left Thumbstick"
		   xAxis: xAxis
		   yAxis: yAxis] autorelease];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	OHGameControllerAxis *xAxis = [_rawProfile.axes objectForKey: @"RX"];
	OHGameControllerAxis *yAxis = [_rawProfile.axes objectForKey: @"RY"];

	if (xAxis == nil || yAxis == nil)
		return nil;

	return [[[OHGameControllerDirectionalPad alloc]
	    initWithName: @"Right Thumbstick"
		   xAxis: xAxis
		   yAxis: yAxis] autorelease];
}

- (OHGameControllerDirectionalPad *)dPad
{
	OHGameControllerAxis *xAxis = [_rawProfile.axes objectForKey: @"HAT0X"];
	OHGameControllerAxis *yAxis = [_rawProfile.axes objectForKey: @"HAT0Y"];
	OHGameControllerButton *up, *down, *left, *right;

	if (xAxis != nil && yAxis != nil)
		return [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			   xAxis: xAxis
			   yAxis: yAxis] autorelease];

	up = [_rawProfile.buttons objectForKey: @"D-Pad Up"];
	down = [_rawProfile.buttons objectForKey: @"D-Pad Down"];
	left = [_rawProfile.buttons objectForKey: @"D-Pad Left"];
	right = [_rawProfile.buttons objectForKey: @"D-Pad Right"];

	if (up != nil && down != nil && left != nil && right != nil)
		return [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			      up: up
			    down: down
			    left: left
			   right: right] autorelease];

	return nil;
}
@end
