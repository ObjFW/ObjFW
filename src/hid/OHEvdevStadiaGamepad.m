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

#import "OHEvdevStadiaGamepad.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerEmulatedTriggerButton.h"

@implementation OHEvdevStadiaGamepad
- (OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *)buttons
{
	OFMutableDictionary *buttons =
	    [[_rawProfile.buttons mutableCopy] autorelease];

	[buttons setObject: self.leftTriggerButton forKey: @"L2"];
	[buttons setObject: self.rightTriggerButton forKey: @"R2"];

	[buttons makeImmutable];

	return buttons;
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	OFMutableDictionary *axes =
	    [[_rawProfile.axes mutableCopy] autorelease];

	[axes removeObjectForKey: @"X"];
	[axes removeObjectForKey: @"Y"];
	[axes removeObjectForKey: @"Z"];
	[axes removeObjectForKey: @"RZ"];
	[axes removeObjectForKey: @"Gas"];
	[axes removeObjectForKey: @"Brake"];
	[axes removeObjectForKey: @"HAT0X"];
	[axes removeObjectForKey: @"HAT0Y"];

	[axes makeImmutable];

	return axes;
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_rawProfile.buttons objectForKey: @"L1"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_rawProfile.buttons objectForKey: @"R1"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	OHGameControllerAxis *axis = [_rawProfile.axes objectForKey: @"Brake"];

	return [[[OHGameControllerEmulatedTriggerButton alloc]
	    initWithName: @"L2"
		    axis: axis] autorelease];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [[[OHGameControllerEmulatedTriggerButton alloc]
	    initWithName: @"R2"
		    axis: [_rawProfile.axes objectForKey: @"Gas"]] autorelease];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_rawProfile.buttons objectForKey: @"L3"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_rawProfile.buttons objectForKey: @"R3"];
}

- (OHGameControllerButton *)menuButton
{
	return [_rawProfile.buttons objectForKey: @"Menu"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_rawProfile.buttons objectForKey: @"Options"];
}

- (OHGameControllerButton *)homeButton
{
	return [_rawProfile.buttons objectForKey: @"Stadia"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	OHGameControllerAxis *xAxis = [_rawProfile.axes objectForKey: @"Z"];
	OHGameControllerAxis *yAxis = [_rawProfile.axes objectForKey: @"RZ"];

	return [[[OHGameControllerDirectionalPad alloc]
	    initWithName: @"Right Thumbstick"
		   xAxis: xAxis
		   yAxis: yAxis] autorelease];
}
@end
