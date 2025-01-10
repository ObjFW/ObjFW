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

#import <GameController/GameController.h>

#import "OHGCFGameController.h"
#import "NSString+OFObject.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFSet.h"
#import "OHDualShock4Gamepad.h"
#import "OHDualShock4Gamepad+Private.h"
#import "OHDualSenseGamepad.h"
#import "OHDualSenseGamepad+Private.h"
#import "OHGCFExtendedGamepad.h"
#import "OHGameController.h"
#import "OHGameController+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHJoyConPair.h"
#import "OHJoyConPair+Private.h"
#import "OHLeftJoyCon.h"
#import "OHLeftJoyCon+Private.h"
#import "OHNESGamepad.h"
#import "OHNESGamepad+Private.h"
#import "OHRightJoyCon.h"
#import "OHRightJoyCon+Private.h"
#import "OHStadiaGamepad.h"
#import "OHStadiaGamepad+Private.h"
#import "OHSwitchProController.h"
#import "OHSwitchProController+Private.h"

@implementation OHGCFGameController
@synthesize name = _name;

+ (void)initialize
{
	if (self != OHGCFGameController.class)
		return;

	GCController.shouldMonitorBackgroundEvents = YES;
}

+ (OFArray<OHGameController *> *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (GCController *controller in GCController.controllers)
		[controllers addObject: [[[self alloc]
		    oh_initWithGCController: controller] autorelease]];

	objc_autoreleasePoolPop(pool);

	return controllers;
}

- (instancetype)oh_init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithGCController: (GCController *)controller
{
	self = [super oh_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_controller = [controller retain];
		_name = [_controller.vendorName.OFObject copy];

		if ([_name isEqual: @"DualSense Wireless Controller"])
			_profile = [[OHDualSenseGamepad alloc] oh_init];
		else if ([_name isEqual: @"DUALSHOCK 4 Wireless Controller"])
			_profile = [[OHDualShock4Gamepad alloc] oh_init];
		else if ([_name isEqual: @"Joy-Con (L/R)"])
			_profile = [[OHJoyConPair alloc] oh_init];
		else if ([_name isEqual: @"Joy-Con (L)"])
			_profile = [[OHLeftJoyCon alloc] oh_init];
		else if ([_name isEqual: @"Joy-Con (R)"])
			_profile = [[OHRightJoyCon alloc] oh_init];
		else if ([_name isEqual: @"Pro Controller"])
			_profile = [[OHSwitchProController alloc] oh_init];
		else if ([_name isEqual: @"Stadia Controller rev. A"])
			_profile = [[OHStadiaGamepad alloc] oh_init];
		else if ([_name isEqual: @"8Bitdo NES30 GamePad"])
			_profile = [[OHNESGamepad alloc] oh_init];
		else
			_profile = [[OHGCFExtendedGamepad alloc]
			    oh_initWithLiveInput:
			    _controller.input.unmappedInput];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_controller release];
	[_profile release];

	[super dealloc];
}

- (void)updateState
{
	void *pool = objc_autoreleasePoolPush();
	id <GCDevicePhysicalInputState> snapshot =
	    [_controller.input.unmappedInput capture];

	[_profile.buttons enumerateKeysAndObjectsUsingBlock:
	    ^ (OFString *name, OHGameControllerButton *button, bool *stop) {
		NSString *nameGC;
		id <GCButtonElement> buttonGC;

		nameGC = _profile.oh_buttonsMap[name];
		OFAssert(nameGC != nil);

		buttonGC = (id <GCButtonElement>)snapshot[nameGC];
		OFAssert(buttonGC != nil);

		button.value = buttonGC.pressedInput.value;
	}];

	[_profile.axes enumerateKeysAndObjectsUsingBlock:
	    ^ (OFString *name, OHGameControllerAxis *axis, bool *stop) {
		NSString *nameGC;
		id <GCAxisElement> axisGC;

		nameGC = _profile.oh_axesMap[name];
		OFAssert(nameGC != nil);

		axisGC = (id <GCAxisElement>)snapshot[nameGC];
		OFAssert(axisGC != nil);

		axis.value = axisGC.absoluteInput.value;
	}];

	[_profile.directionalPads enumerateKeysAndObjectsUsingBlock:
	    ^ (OFString *name, OHGameControllerDirectionalPad *directionalPad,
	    bool *stop) {
		NSString *nameGC;
		id <GCDirectionPadElement> directionalPadGC;

		nameGC = _profile.oh_directionalPadsMap[name];
		OFAssert(nameGC != nil);

		directionalPadGC = (id <GCDirectionPadElement>)snapshot[nameGC];
		OFAssert(directionalPadGC != nil);

		directionalPad.xAxis.value = directionalPadGC.xAxis.value;
		directionalPad.yAxis.value = (directionalPadGC.yAxis.value != 0
		    ? -directionalPadGC.yAxis.value : 0);
	}];

	objc_autoreleasePoolPop(pool);
}

- (OFNumber *)vendorID
{
	return nil;
}

- (OFNumber *)productID
{
	return nil;
}

- (id <OHGameControllerProfile>)profile
{
	return _profile;
}

- (id <OHGamepad>)gamepad
{
	if ([_profile conformsToProtocol: @protocol(OHGamepad)])
		return (id <OHGamepad>)_profile;

	return nil;
}

- (id <OHExtendedGamepad>)extendedGamepad
{
	if ([_profile conformsToProtocol: @protocol(OHExtendedGamepad)])
		return (id <OHExtendedGamepad>)_profile;

	return nil;
}
@end
