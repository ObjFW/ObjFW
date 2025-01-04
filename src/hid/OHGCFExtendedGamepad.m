/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OHGCFExtendedGamepad.h"
#import "OFDictionary.h"
#import "OHGCFGameController.h"

#import "OFInvalidArgumentException.h"

@implementation OHGCFExtendedGamepad
- (instancetype)oh_initWithLiveInput: (GCControllerLiveInput *)liveInput
{
	self = [super oh_initWithLiveInput: liveInput];

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
			    [OHGCFGameControllerProfile class]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (OHGameControllerButton *)northButton
{
	return _buttons[@"Y"];
}

- (OHGameControllerButton *)southButton
{
	return _buttons[@"A"];
}

- (OHGameControllerButton *)westButton
{
	return _buttons[@"X"];
}

- (OHGameControllerButton *)eastButton
{
	return _buttons[@"B"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return _buttons[@"Left Shoulder"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return _buttons[@"Right Shoulder"];
}

- (OHGameControllerButton *)leftTriggerButton
{
	return _buttons[@"Left Trigger"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return _buttons[@"Right Trigger"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return _buttons[@"Left Thumbstick"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return _buttons[@"Right Thumbstick"];
}

- (OHGameControllerButton *)menuButton
{
	return _buttons[@"Menu"];
}

- (OHGameControllerButton *)optionsButton
{
	return _buttons[@"Options"];
}

- (OHGameControllerButton *)homeButton
{
	return _buttons[@"Home"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	return _directionalPads[@"Left Thumbstick"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	return _directionalPads[@"Right Thumbstick"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return _directionalPads[@"Direction Pad"];
}
@end
