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

#import "OHCombinedJoyCons.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OHGameController.h"
#import "OHGameControllerDirectionalPad.h"

#import "OFInvalidArgumentException.h"

@implementation OHCombinedJoyCons
+ (instancetype)gamepadWithLeftJoyCon: (OHGameController *)leftJoyCon
			  rightJoyCon: (OHGameController *)rightJoyCon
{
	return [[[self alloc] initWithLeftJoyCon: leftJoyCon
				     rightJoyCon: rightJoyCon] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithLeftJoyCon: (OHGameController *)leftJoyCon
		       rightJoyCon: (OHGameController *)rightJoyCon
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFDictionary *leftButtons, *rightButtons;
		OFMutableDictionary *buttons, *directionalPads;
		OHGameControllerDirectionalPad *directionalPad;

		if (leftJoyCon.vendorID.unsignedShortValue !=
		    OHVendorIDNintendo ||
		    rightJoyCon.vendorID.unsignedShortValue !=
		    OHVendorIDNintendo)
			@throw [OFInvalidArgumentException exception];

		if (leftJoyCon.productID.unsignedShortValue !=
		    OHProductIDLeftJoyCon ||
		    rightJoyCon.productID.unsignedShortValue !=
		    OHProductIDRightJoyCon)
			@throw [OFInvalidArgumentException exception];

		_leftJoyCon = [leftJoyCon.rawProfile retain];
		_rightJoyCon = [rightJoyCon.rawProfile retain];

		leftButtons = _leftJoyCon.buttons;
		rightButtons = _rightJoyCon.buttons;

		buttons = [OFMutableDictionary dictionaryWithCapacity:
		    leftButtons.count + rightButtons.count];
		[buttons addEntriesFromDictionary: leftButtons];
		[buttons addEntriesFromDictionary: rightButtons];
		[buttons removeObjectForKey: @"D-Pad Up"];
		[buttons removeObjectForKey: @"D-Pad Down"];
		[buttons removeObjectForKey: @"D-Pad Left"];
		[buttons removeObjectForKey: @"D-Pad Right"];
		[buttons removeObjectForKey: @"SL"];
		[buttons removeObjectForKey: @"SR"];
		[buttons makeImmutable];
		_buttons = [buttons retain];

		_axes = [[OFDictionary alloc] init];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Left Thumbstick"
			   xAxis: [_leftJoyCon.axes objectForKey: @"X"]
			   yAxis: [_leftJoyCon.axes objectForKey: @"Y"]]
		    autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Thumbstick"];

		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Right Thumbstick"
			   xAxis: [_rightJoyCon.axes objectForKey: @"RX"]
			   yAxis: [_rightJoyCon.axes objectForKey: @"RY"]]
		    autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Thumbstick"];

		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			      up: [leftButtons objectForKey: @"D-Pad Up"]
			    down: [leftButtons objectForKey: @"D-Pad Down"]
			    left: [leftButtons objectForKey: @"D-Pad Left"]
			   right: [leftButtons objectForKey: @"D-Pad Right"]]
		    autorelease];
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		[directionalPads makeImmutable];
		_directionalPads = [directionalPads retain];

		objc_autoreleasePoolPop(pool);
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

- (OHGameControllerButton *)northButton
{
	return [_buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"L"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"R"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	return [_buttons objectForKey: @"ZL"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"ZR"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_buttons objectForKey: @"Left Thumbstick"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_buttons objectForKey: @"Right Thumbstick"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"+"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"-"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Home"];
}

- (OHGameControllerDirectionalPad *)leftThumbStick
{
	return [_directionalPads objectForKey: @"Left Thumbstick"];
}

- (OHGameControllerDirectionalPad *)rightThumbStick
{
	return [_directionalPads objectForKey: @"Right Thumbstick"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}
@end
