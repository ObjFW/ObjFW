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

#import "OHEvdevDualSense.h"
#import "OFDictionary.h"
#import "OHGameControllerEmulatedTriggerButton.h"

#import "OFInvalidArgumentException.h"

@implementation OHEvdevDualSense
- (OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *)buttons
{
	OFMutableDictionary *buttons =
	    [[_rawProfile.buttons mutableCopy] autorelease];

	[buttons removeObjectForKey: @"D-Pad Up"];
	[buttons removeObjectForKey: @"D-Pad Down"];
	[buttons removeObjectForKey: @"D-Pad Left"];
	[buttons removeObjectForKey: @"D-Pad Right"];

	[buttons setObject: self.leftTriggerButton forKey: @"L2"];
	[buttons setObject: self.rightTriggerButton forKey: @"R2"];

	[buttons makeImmutable];

	return buttons;
}

- (OHGameControllerButton *)northButton
{
	return [_rawProfile.buttons objectForKey: @"Triangle"];
}

- (OHGameControllerButton *)southButton
{
	return [_rawProfile.buttons objectForKey: @"Cross"];
}

- (OHGameControllerButton *)westButton
{
	return [_rawProfile.buttons objectForKey: @"Square"];
}

- (OHGameControllerButton *)eastButton
{
	return [_rawProfile.buttons objectForKey: @"Circle"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_rawProfile.buttons objectForKey: @"L1"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	OHGameControllerAxis *axis = [_rawProfile.axes objectForKey: @"Z"];

	if (axis != nil)
		return [[[OHGameControllerEmulatedTriggerButton alloc]
		    initWithName: @"L2"
			    axis: axis] autorelease];

	return [_rawProfile.buttons objectForKey: @"L2"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	OHGameControllerAxis *axis = [_rawProfile.axes objectForKey: @"RZ"];

	if (axis != nil)
		return [[[OHGameControllerEmulatedTriggerButton alloc]
		    initWithName: @"R2"
			    axis: axis] autorelease];

	return [_rawProfile.buttons objectForKey: @"R2"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_rawProfile.buttons objectForKey: @"R1"];
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
	return [_rawProfile.buttons objectForKey: @"Options"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_rawProfile.buttons objectForKey: @"Create"];
}

- (OHGameControllerButton *)homeButton
{
	return [_rawProfile.buttons objectForKey: @"PS"];
}
@end
