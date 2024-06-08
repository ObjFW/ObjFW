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

#import "OHEvdevGamepad.h"
#import "OFDictionary.h"
#import "OHEvdevGameController.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerEmulatedTriggerButton.h"

#import "OFInvalidArgumentException.h"

@implementation OHEvdevGamepad
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
		    self.rightTriggerButton == nil ||
		    self.leftThumbstickButton == nil ||
		    self.rightThumbstickButton == nil ||
		    self.menuButton == nil || self.optionsButton == nil ||
		    self.homeButton == nil || self.leftThumbstick == nil ||
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
	return [OFDictionary dictionaryWithKeysAndObjects:
	    @"North", self.northButton,
	    @"South", self.southButton,
	    @"West", self.westButton,
	    @"East", self.eastButton,
	    @"Left Shoulder", self.leftShoulderButton,
	    @"Right Shoulder", self.rightShoulderButton,
	    @"Left Trigger", self.leftTriggerButton,
	    @"Right Trigger", self.rightTriggerButton,
	    @"Left Thumbstick", self.leftThumbstickButton,
	    @"Right Thumbstick", self.rightThumbstickButton,
	    @"Menu", self.menuButton,
	    @"Options", self.optionsButton,
	    @"Home", self.homeButton, nil];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
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
	return [_rawProfile.buttons objectForKey: @"TL"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_rawProfile.buttons objectForKey: @"TR"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	OHGameControllerAxis *axis = [_rawProfile.axes objectForKey: @"Z"];

	if (axis != nil)
		return [[[OHGameControllerEmulatedTriggerButton alloc]
		    initWithAxis: axis] autorelease];

	return [_rawProfile.buttons objectForKey: @"TL2"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	OHGameControllerAxis *axis = [_rawProfile.axes objectForKey: @"RZ"];

	if (axis != nil)
		return [[[OHGameControllerEmulatedTriggerButton alloc]
		    initWithAxis: axis] autorelease];

	return [_rawProfile.buttons objectForKey: @"TR2"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_rawProfile.buttons objectForKey: @"Thumb L"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_rawProfile.buttons objectForKey: @"Thumb R"];
}

- (OHGameControllerButton *)menuButton
{
	return [_rawProfile.buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_rawProfile.buttons objectForKey: @"Select"];
}

- (OHGameControllerButton *)homeButton
{
	return [_rawProfile.buttons objectForKey: @"Mode"];
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
	OHGameControllerButton *upButton, *downButton;
	OHGameControllerButton *leftButton, *rightButton;

	if (xAxis != nil && yAxis != nil)
		return [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			   xAxis: xAxis
			   yAxis: yAxis] autorelease];

	upButton = [_rawProfile.buttons objectForKey: @"D-Pad Up"];
	downButton = [_rawProfile.buttons objectForKey: @"D-Pad Down"];
	leftButton = [_rawProfile.buttons objectForKey: @"D-Pad Left"];
	rightButton = [_rawProfile.buttons objectForKey: @"D-Pad Right"];

	if (upButton != nil && downButton != nil &&
	    leftButton != nil && rightButton != nil)
		return [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			upButton: upButton
		      downButton: downButton
		      leftButton: leftButton
		     rightButton: rightButton] autorelease];

	return nil;
}
@end
